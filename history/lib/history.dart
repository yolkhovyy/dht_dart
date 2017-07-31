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

  String _fileName = DEFAULT_HISTORY_FILE_NAME;
  String get fileName => _fileName;

  int _dataSize;
  int get dataSize => _dataSize;

  int _entrySize;
  int get entrySize => _entrySize;

  // Number of entries in the history
  int _historySize = _DEFAULT_HISTORY_SIZE;
  int get historySize => _historySize;

  int _head;
  int get head => _head;
  int _tail;
  int _numOfEntries;

  History.open({String fileName = DEFAULT_HISTORY_FILE_NAME,
                int dataSize = 0,
                int historySize = _DEFAULT_HISTORY_SIZE}) {

    _fileName = fileName;
    _historySize = historySize;
    _dataSize = dataSize;
    _entrySize = HistoryEntry.TIMESTAMP_SIZE + this._dataSize + HistoryEntry.CHECKSUM_SIZE;
    File file = new File(this._fileName);
    FileStat stat = file.statSync();
    _numOfEntries = (stat.size / _entrySize).floor();
    _head = _open();
    _tail = _numOfEntries > 0 ? (_head + 1).remainder(_numOfEntries) : 0;
  }

  int _open() {

    int result = 0;

    int a = 0;
    int b = _numOfEntries;
    int timestampMax = 0;

    File file = new File(this._fileName);
    if (file.existsSync() && _numOfEntries > 0) {
      ByteData bytes = new ByteData(_entrySize);
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);
      raf.setPositionSync(a * _entrySize);   
      raf.readIntoSync(bytes.buffer.asUint8List());
      HistoryEntry historyEntry = new HistoryEntry.parse(bytes);
      if (!historyEntry.isValid) {
        result = _linearSearch(raf, timestampMax, a, b);
      } else {
        timestampMax = historyEntry.timestamp;
        while (b - a > 1) {
          int next = a + ((b - a) / 2).floor();
          raf.setPositionSync(next * _entrySize);
          raf.readIntoSync(bytes.buffer.asUint8List());
          historyEntry = new HistoryEntry.parse(bytes);
          if (!historyEntry.isValid) {
            a = _linearSearch(raf, timestampMax, a, b);
            result = a;
            break;
          } else if (historyEntry.timestamp > timestampMax) {
            timestampMax = historyEntry.timestamp;
            a = next;
          } else {
            b = next;
          }            
        }
        result = a;
      }
      raf.closeSync();
    }

    return result;
  }



  int _linearSearch(RandomAccessFile raf, int timestampMax, int lo, int hi) {
    int result = lo;
    ByteData bytes = new ByteData(_entrySize);
    while (hi - lo > 1) {
      lo++;
      raf.setPositionSync(lo * _entrySize);
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

  find({int timestampBegin = 0, int timestampEnd = 0xFFFFFFFFFFFFFFFF}) {
    int i = _find(timestampBegin);
    print('Timestamp:$timestampBegin record:$i');
  }

  int _find(int timestampBegin) {

    int result = -1;  // returns -1 if nothing found

    File file = new File(_fileName);
    if (file.existsSync() && _numOfEntries > 0) {
      
      ByteData bytes = new ByteData(_entrySize);
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);

      raf.setPositionSync(_head * _entrySize);
      raf.readIntoSync(bytes.buffer.asUint8List());
      HistoryEntry historyEntry = new HistoryEntry.parse(bytes);
      if (!historyEntry.isValid) {
        // TODO linear search
      } else if (historyEntry.timestamp == timestampBegin) {
        // Done, the head
        result = _head;
      } else if (historyEntry.timestamp < timestampBegin) {
        // Done, nothing found
      } else {
        raf.setPositionSync(_tail * _entrySize);
        raf.readIntoSync(bytes.buffer.asUint8List());
        historyEntry = new HistoryEntry.parse(bytes);
        if (!historyEntry.isValid) {
          // TODO linear search
        } else if (historyEntry.timestamp >= timestampBegin) {
          // Found, the tail
          result = _tail;
        } else {
          bool exactFound = false;
          int a = _tail;
          int b = _head;

          while (!exactFound && a != b) {
            int step = (b - a + _numOfEntries).remainder(_numOfEntries);
            step = step > 1 ? (step / 2).floor() : 1;
            int next = (a + step).remainder(_numOfEntries);
            //print('head:$head tail:$tail step:$step');
            raf.setPositionSync(next * _entrySize);
            raf.readIntoSync(bytes.buffer.asUint8List());

            historyEntry = new HistoryEntry.parse(bytes);
            if (!historyEntry.isValid) {
              // lo = _linearSearch(raf, timestampMax, lo, hi);
              // result = lo;
              // break;
            } else if (historyEntry.timestamp == timestampBegin) {
              exactFound = true;
              result = next;
              break;
            } else if (historyEntry.timestamp < timestampBegin) {
              a = next;
            } else {
              b = next;
            }
          }
          if (!exactFound && a != b) {
            result = a;
          }
        }
      }

      raf.closeSync();
    }

    return result;
  }

  Stream<List<HistoryEntry>> read({int timestampBegin = 0, int timestampEnd = 0x7FFFFFFFFFFFFFFF,
    final int PAGE_SIZE  = _DEFAULT_HISTORY_PAGE_SIZE}) async* {

    if (PAGE_SIZE == null) {
      throw new ArgumentError.notNull('PAGE_SIZE');
    } else if (PAGE_SIZE <= 0) {
      throw new ArgumentError("PAGE_SIZE parameter must be greater than 0");
    }

    File file = new File(this._fileName);
    if (file.existsSync()) {
      ByteData bytes = new ByteData(_entrySize);
      RandomAccessFile raf = await file.open(mode: FileMode.READ);
      int numOfEntries = _numOfEntries;
      int numOfPages = (numOfEntries / PAGE_SIZE).ceil();
      int next = _find(timestampBegin);
      while (numOfPages-- > 0) {
        int pageSize = PAGE_SIZE;
        List<HistoryEntry> result = new List<HistoryEntry>();
        while (pageSize > 0 && numOfEntries-- > 0) {
          raf = await raf.setPosition(next * _entrySize);
          var r = await raf.readInto(bytes.buffer.asUint8List());
          if (r == _entrySize) {
            HistoryEntry historyEntry = new HistoryEntry.parse(bytes);
            if (historyEntry.isValid) {
              result.add(historyEntry);
              pageSize--;
            }
          }
          next = (++next).remainder(numOfEntries);
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
      if (_head < _historySize) {
        raf = await file.open(mode: FileMode.APPEND);
      } else {
        raf = await file.open(mode: FileMode.WRITE);
        raf = await raf.setPosition(_head * _entrySize);
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

      if (++_head / _entrySize >= _historySize) {
        _head = 0;
      }
    } catch (e) {
      print('History.store failed: $e');
    }
  }
}
