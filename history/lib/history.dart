// Copyright (c) 2017, yo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library history;

import 'dart:typed_data';
import 'dart:io';

export 'src/history_base.dart';

class History {

  static const int TIMESTAMP_OFFSET = 0;
  static const int TIMESTAMP_SIZE = 8;
  static const int DATA_OFFSET = TIMESTAMP_OFFSET + TIMESTAMP_SIZE;
  static const int CHECKSUM_SIZE = 8;

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

  History.open({String fileName = DEFAULT_HISTORY_FILE_NAME, int dataSize = 0, int historySize = _DEFAULT_HISTORY_SIZE, int pageSize = _DEFAULT_HISTORY_PAGE_SIZE}) {
    this.fileName = fileName;
    this.historySize = historySize;
    this.dataSize = dataSize;
    this.pageSize = pageSize;
    entrySize = TIMESTAMP_SIZE + this.dataSize + CHECKSUM_SIZE;
    
    // Find the oldest record to start overwrite from
    int lo = 0;
    int numOfEntries = 0;
    nextEntry = 0;
    File file = new File(this.fileName);
    if (file.existsSync()) {
      ByteData bd = new ByteData(8);
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);
      FileStat stat = file.statSync();
      numOfEntries = (stat.size / entrySize).floor();
      if (numOfEntries > 0) {
        raf.setPositionSync(0);
        raf.readIntoSync(bd.buffer.asUint8List());
        int timestampMax = bd.getUint64(0);
        int hi = numOfEntries;
        while (hi - lo > 1) {
          int next = lo + ((hi - lo) / 2).floor();
          raf.setPositionSync(next * entrySize);
          raf.readIntoSync(bd.buffer.asUint8List());
          int timestamp = bd.getUint64(0);
          if (timestamp > timestampMax) {
            timestampMax = timestamp;
            lo = next;
          } else {
            hi = next;
          }
        }
        raf.closeSync();
      }
    }
    if (numOfEntries > 0) {
      nextEntry = ++lo >= this.historySize ? 0 : lo;
    }
  }

  store(int timestamp, Uint8List data) async {
    try {

      ByteData dataTimestamp = new ByteData(TIMESTAMP_SIZE);
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
      int cs = History.checksum(0, dataTimestamp.buffer.asUint8List());
      cs = History.checksum(cs, data);
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

  static checksum(int checksum, Uint8List data) {
    for (var item in data) {
      checksum += item;
    }
    return checksum;
  }

}
