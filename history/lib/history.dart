// Copyright (c) 2017, yo. All rights reserved. Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library history;

import 'dart:core';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

export 'src/history_base.dart';

class HistoryEntry {
  static const int TIMESTAMP_OFFSET = 0;
  static const int TIMESTAMP_SIZE = 8;
  static const int DATA_OFFSET = TIMESTAMP_OFFSET + TIMESTAMP_SIZE;
  static const int CHECKSUM_SIZE = 8;

  ByteData _entryBytes;
  int timestamp;
  ByteData dataBytes;
  int checksum;

  HistoryEntry(int timestamp, ByteData dataBytes) {

    if (dataBytes == null) {
      throw new ArgumentError.notNull('dataBytes');
    }

    this.timestamp;
    this.dataBytes = dataBytes;
    checksum = HistoryEntry.calculateChecksum(data: _entryBytes.buffer.asUint8List(0, _entryBytes.lengthInBytes - CHECKSUM_SIZE));
    _entryBytes = new ByteData(TIMESTAMP_SIZE + dataBytes.lengthInBytes + CHECKSUM_SIZE);
    
    // Timestamp
    _entryBytes.setInt64(TIMESTAMP_OFFSET, this.timestamp);
    // Data
    _entryBytes.buffer.asUint8List().setRange(DATA_OFFSET, DATA_OFFSET + dataBytes.lengthInBytes, dataBytes.buffer.asUint8List());
    // Checksum
    _entryBytes.setInt64(TIMESTAMP_SIZE + dataBytes.lengthInBytes, checksum);
  }

  HistoryEntry.parse(ByteData entryBytes) {

    if (entryBytes == null) {
      throw new ArgumentError.notNull('entryBytes');
    } else if (entryBytes.lengthInBytes < TIMESTAMP_SIZE - CHECKSUM_SIZE) {
      throw new ArgumentError('entryBytes parameter size is too small');
    }
    
    _entryBytes = entryBytes;
    
    // Timestamp
    timestamp = _entryBytes.getInt64(TIMESTAMP_OFFSET);
    // Data
    dataBytes = new ByteData(entryBytes.lengthInBytes - TIMESTAMP_SIZE - CHECKSUM_SIZE);
    dataBytes.buffer.asUint8List().setRange(0, dataBytes.lengthInBytes - 1,
        entryBytes.buffer.asUint8List().getRange(DATA_OFFSET, DATA_OFFSET + dataBytes.lengthInBytes - 1));
    // Checksum
    checksum = _entryBytes.getInt64(_entryBytes.lengthInBytes - CHECKSUM_SIZE);
  }

  ByteData get bytes => _entryBytes;
  bool get isValid =>
      checksum ==
      HistoryEntry.calculateChecksum(data: _entryBytes.buffer.asUint8List(0, _entryBytes.lengthInBytes - CHECKSUM_SIZE));

  static calculateChecksum({int checksum = 0, Uint8List data}) {
    data.forEach((item) => checksum += item);
    return checksum;
  }
}

class History {
  static const int _DEFAULT_HISTORY_SIZE = 16;
  static const int _DEFAULT_HISTORY_PAGE_SIZE = 4;
  static const String DEFAULT_HISTORY_FILE_NAME = 'history.bin';

  String fileName = DEFAULT_HISTORY_FILE_NAME;
  int dataSize;
  int entrySize;

  // Number of entries in the history
  int historySize = _DEFAULT_HISTORY_SIZE;
  // Number of entries in a page
  int pageSize = _DEFAULT_HISTORY_PAGE_SIZE;

  int nextEntry;

  History.open({String fileName = DEFAULT_HISTORY_FILE_NAME,
                int dataSize = 0,
                int historySize = _DEFAULT_HISTORY_SIZE,
                int pageSize = _DEFAULT_HISTORY_PAGE_SIZE}) {

    this.fileName = fileName;
    this.historySize = historySize;
    this.dataSize = dataSize;
    this.pageSize = pageSize;
    entrySize = HistoryEntry.TIMESTAMP_SIZE + this.dataSize + HistoryEntry.CHECKSUM_SIZE;

    nextEntry = 0;
    HistoryEntry historyEntry;
    int lo = 0;
    int numOfEntries = 0;
    int timestampMax = 0;

    File file = new File(this.fileName);
    if (file.existsSync()) {

      ByteData bytes = new ByteData(entrySize);
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);
      FileStat stat = file.statSync();

      numOfEntries = (stat.size / entrySize).floor();
      int hi = numOfEntries;

      if (numOfEntries > 0) {
        raf.setPositionSync(lo * entrySize);
        raf.readIntoSync(bytes.buffer.asUint8List());

        historyEntry = new HistoryEntry.parse(bytes);
        if (!historyEntry.isValid) {
          lo = _linearSearch(raf, timestampMax, lo, hi);
          nextEntry = numOfEntries > 1 && lo > 0 ? (++lo).remainder(this.historySize) : lo;
        } else {
          timestampMax = historyEntry.timestamp;
          while (hi - lo > 1) {
            int next = lo + ((hi - lo) / 2).floor();
            raf.setPositionSync(next * entrySize);
            raf.readIntoSync(bytes.buffer.asUint8List());
            historyEntry = new HistoryEntry.parse(bytes);
            if (!historyEntry.isValid) {
              lo = _linearSearch(raf, timestampMax, lo, hi);
              nextEntry = lo;
              break;
             } else {
              int timestamp = historyEntry.timestamp;
              if (timestamp > timestampMax) {
                timestampMax = timestamp;
                lo = next;
              } else {
                hi = next;
              }            
            }
          }
          nextEntry = (++lo).remainder(this.historySize);
        }
        raf.closeSync();
      }
    }
  }

  int _linearSearch(RandomAccessFile raf, int timestampMax, int lo, int hi) {
    int result = lo;
    ByteData bytes = new ByteData(entrySize);
    while (hi - lo > 1) {
      lo++;
      raf.setPositionSync(lo * entrySize);
      raf.readIntoSync(bytes.buffer.asUint8List());
      HistoryEntry historyEntry = new HistoryEntry.parse(bytes);
      if (historyEntry.isValid) {
        if (historyEntry.timestamp >= timestampMax) {
          timestampMax = historyEntry.timestamp;
          result = lo;
        }
      }
    }
    return result;
  }

  Stream<List<HistoryEntry>> read(final int PAGE_SIZE) async* {

    if (PAGE_SIZE == null) {
      throw new ArgumentError.notNull('PAGE_SIZE');
    } else if (PAGE_SIZE == 0) {
      throw new ArgumentError("PAGE_SIZE must not be 0");
    }

    File file = new File(this.fileName);
    if (file.existsSync()) {
      ByteData bytes = new ByteData(entrySize);
      RandomAccessFile raf = await file.open(mode: FileMode.READ);
      FileStat stat = await file.stat();
      final int NUM_OF_ENTRIES = (stat.size / entrySize).floor();
      int numOfEntries = NUM_OF_ENTRIES;
      int numOfPages = (NUM_OF_ENTRIES / PAGE_SIZE).ceil();
      int next = nextEntry.remainder(NUM_OF_ENTRIES);
      while (numOfPages-- > 0) {
        int pageSize = PAGE_SIZE;
        List<HistoryEntry> result = new List<HistoryEntry>();
        while (pageSize > 0 && numOfEntries-- > 0) {
          raf = await raf.setPosition(next * entrySize);
          var r = await raf.readInto(bytes.buffer.asUint8List());
          if (r == entrySize) {
            HistoryEntry historyEntry = new HistoryEntry.parse(bytes);
            if (historyEntry.isValid) {
              result.add(historyEntry);
              pageSize--;
            }
          }
          next = (++next).remainder(NUM_OF_ENTRIES);
        }
        yield result;
      }
    }
  }

  store(int timestamp, Uint8List data) async {
    try {
      ByteData dataTimestamp = new ByteData(HistoryEntry.TIMESTAMP_SIZE);
      dataTimestamp.setUint64(0, timestamp);

      File file = new File(DEFAULT_HISTORY_FILE_NAME);
      RandomAccessFile raf;
      if (nextEntry < historySize) {
        raf = await file.open(mode: FileMode.APPEND);
      } else {
        raf = await file.open(mode: FileMode.WRITE);
        raf = await raf.setPosition(nextEntry * entrySize);
      }
      // Timestamp
      raf = await raf.writeFrom(dataTimestamp.buffer.asUint8List());
      // Data
      raf = await raf.writeFrom(data);
      // Checksum
      int cs = HistoryEntry.calculateChecksum(data: dataTimestamp.buffer.asUint8List());
      cs = HistoryEntry.calculateChecksum(checksum: cs, data: data);
      ByteData bd = new ByteData(8);
      bd.setUint64(0, cs);
      raf = await raf.writeFrom(bd.buffer.asUint8List());
      raf.close();

      if (++nextEntry / entrySize >= historySize) {
        nextEntry = 0;
      }
    } catch (e) {
      print('History.store failed: $e');
    }
  }
}
