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

  static const int _DEFAULT_HISTORY_SIZE = 16;
  static const int _DEFAULT_HISTORY_PAGE_SIZE = 4;
  static const String DEFAULT_HISTORY_FILE_NAME = 'sensor-data-history.bin';

  String fileName = DEFAULT_HISTORY_FILE_NAME;
  int historyDataSize;
  int historyEntrySize;
  // Number of entries in the history
  int historySize = _DEFAULT_HISTORY_SIZE;
  int pageSize = _DEFAULT_HISTORY_PAGE_SIZE;

  int t_offset = 0;
  int _nextEntry = 0;

  History.open({String fileName = DEFAULT_HISTORY_FILE_NAME, int historyDataSize = 0, int historySize = _DEFAULT_HISTORY_SIZE, int pageSize = _DEFAULT_HISTORY_PAGE_SIZE}) {
    this.fileName = fileName;
    this.historySize = historySize;
    this.historyDataSize = historyDataSize;
    historyEntrySize = this.historyDataSize + 16;
    this.pageSize = pageSize;
    
    // Find the oldest record to start overwrite from
    int lo = 0;
    int numOfEntries = 0;
    File file = new File(this.fileName);
    if (file.existsSync()) {
      ByteData bd = new ByteData(8);
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);
      FileStat stat = file.statSync();
      numOfEntries = (stat.size / historyEntrySize).floor();
      if (numOfEntries > 0) {
        raf.setPositionSync(0);
        raf.readIntoSync(bd.buffer.asUint8List());
        int timestampMax = bd.getUint64(0);
        int hi = numOfEntries;
        //print("lo:$lo hi:$hi ts:$timestampMax");
        while (hi - lo > 1) {
          int next = lo + ((hi - lo) / 2).floor();
          raf.setPositionSync(next * historyEntrySize);
          raf.readIntoSync(bd.buffer.asUint8List());
          int timestamp = bd.getUint64(0);
          if (timestamp >= timestampMax) {
            timestampMax = timestamp;
            lo = next;
          } else {
            hi = next;
          }
          //print("lo:$lo hi:$hi ne:$next ts:$timestampMax");
        }
        raf.closeSync();
      }
    }
    _nextEntry = ++lo >= numOfEntries ? 0 : lo;
    print("_nextEntry:$_nextEntry ---");
    t_offset = _nextEntry * historyEntrySize;
  }

  store(int timestamp, Uint8List data) async {
    try {

      ByteData dataTimestamp = new ByteData(8);
      dataTimestamp.setUint64(0, timestamp);

      File file = new File(DEFAULT_HISTORY_FILE_NAME);
      RandomAccessFile raf;
      if (t_offset / historyEntrySize < historySize) {
        raf = await file.open(mode: FileMode.APPEND);
      } else {
        raf = await file.open(mode: FileMode.WRITE);
        raf = await raf.setPosition(t_offset);
      }
      raf = await raf.writeFrom(dataTimestamp.buffer.asUint8List());
      raf = await raf.writeFrom(data);
      t_offset = await raf.position(); 
      raf.close();

      if (t_offset / historyEntrySize >= historySize) {
        t_offset = 0;
      }

    } catch (e) {
      print('History.store failed: $e');
    }
  }

}
