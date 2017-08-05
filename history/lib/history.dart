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
import 'dart:math';

export 'src/history_base.dart';

class HistoryRecord {
  static const int TIMESTAMP_OFFSET = 0;
  static const int TIMESTAMP_SIZE = 8;
  static const int DATA_OFFSET = TIMESTAMP_OFFSET + TIMESTAMP_SIZE;
  static const int CHECKSUM_SIZE = 8;

  ByteData _recordBytes;
  
  int _timestamp;
  int get timestamp => _timestamp;
  
  ByteData _dataBytes;
  ByteData get dataBytes => _dataBytes;
  
  int _checksum;
  int get checksum => _checksum;

  HistoryRecord(int timestamp, ByteData dataBytes) {

    if (dataBytes == null) {
      throw new ArgumentError.notNull('dataBytes');
    }

    this._timestamp;
    this._dataBytes = dataBytes;

    _checksum = HistoryRecord.calculateChecksum(data: _recordBytes.buffer.asUint8List(0, _recordBytes.lengthInBytes - CHECKSUM_SIZE));
    _recordBytes = new ByteData(TIMESTAMP_SIZE + dataBytes.lengthInBytes + CHECKSUM_SIZE);
    
    // Timestamp
    _recordBytes.setInt64(TIMESTAMP_OFFSET, this._timestamp);
    // Data
    _recordBytes.buffer.asUint8List().setRange(DATA_OFFSET, DATA_OFFSET + dataBytes.lengthInBytes, dataBytes.buffer.asUint8List());
    // Checksum
    _recordBytes.setInt64(TIMESTAMP_SIZE + dataBytes.lengthInBytes, _checksum);
  }

  HistoryRecord.parse(ByteData recordBytes) {

    if (recordBytes == null) {
      throw new ArgumentError.notNull('recordBytes');
    } else if (recordBytes.lengthInBytes < TIMESTAMP_SIZE - CHECKSUM_SIZE) {
      throw new ArgumentError('recordBytes parameter size is too small');
    }
    
    _recordBytes = recordBytes;
    
    // Timestamp
    _timestamp = _recordBytes.getInt64(TIMESTAMP_OFFSET);
    // Data
    _dataBytes = new ByteData(recordBytes.lengthInBytes - TIMESTAMP_SIZE - CHECKSUM_SIZE);
    _dataBytes.buffer.asUint8List().setRange(0, _dataBytes.lengthInBytes - 1,
        recordBytes.buffer.asUint8List().getRange(DATA_OFFSET, DATA_OFFSET + _dataBytes.lengthInBytes - 1));
    // Checksum
    _checksum = _recordBytes.getInt64(_recordBytes.lengthInBytes - CHECKSUM_SIZE);
  }

  ByteData get bytes => _recordBytes;
  bool get isValid =>
      _checksum ==
      HistoryRecord.calculateChecksum(data: _recordBytes.buffer.asUint8List(0, _recordBytes.lengthInBytes - CHECKSUM_SIZE));

  static calculateChecksum({int checksum = 0, Uint8List data}) {
    data.forEach((item) => checksum += item);
    return checksum;
  }
}

class History {
  static const int _DEFAULT_HISTORY_SIZE = 16;
  static const int _DEFAULT_HISTORY_PAGE_SIZE = 4;
  static const String DEFAULT_HISTORY_FILE_NAME = 'history.bin';

  // History file name
  String _fileName = DEFAULT_HISTORY_FILE_NAME;
  String get fileName => _fileName;

  // History data size, in bytes
  int _dataSize;
  int get dataSize => _dataSize;

  // History record size, in bytes
  int _recordSize;
  int get recordSize => _recordSize;

  // Number of entries in the history
  int _historySize = _DEFAULT_HISTORY_SIZE;
  int get historySize => _historySize;

  // Head (latest by timestamp) entry
  int _head = 0;
  int get head => _head;

  // Tail (oldest by timestamp) entry
  int _tail = 0;
  int get tail => _tail;
  
  int _numOfEntries = 0;
  int get numOfEntries => _numOfEntries;

  History.open({String fileName = DEFAULT_HISTORY_FILE_NAME,
                int dataSize = 0,
                int historySize = _DEFAULT_HISTORY_SIZE}) {

    _fileName = fileName;
    _historySize = historySize;
    _dataSize = dataSize;
    _recordSize = HistoryRecord.TIMESTAMP_SIZE + this._dataSize + HistoryRecord.CHECKSUM_SIZE;
    _init();
  }

  _init() {

    int a = 0;

    File file = new File(this._fileName);
    if (file.existsSync())  {

      FileStat stat = file.statSync();
      _numOfEntries = (stat.size / _recordSize).floor();

      if (_numOfEntries > 0) {
        int b = _numOfEntries;
        int timestampMax = 0;

        ByteData bytes = new ByteData(_recordSize);
        RandomAccessFile raf = file.openSync(mode: FileMode.READ);
        raf.setPositionSync(a * _recordSize);   
        raf.readIntoSync(bytes.buffer.asUint8List());
        HistoryRecord record = new HistoryRecord.parse(bytes);
        if (!record.isValid) {
          int a_ = _linearSearchMax(raf, a, b - 1, timestampMax);
          _head = a_;
          if (a_ == a) {
            _tail = a_;
          } else {
            _tail = _numOfEntries > 0 ? (_head + 1).remainder(_numOfEntries) : 0;
          }
        } else {
          timestampMax = record._timestamp;
          while (b - a > 1) {
            int next = a + ((b - a) / 2).floor();
            raf.setPositionSync(next * _recordSize);
            raf.readIntoSync(bytes.buffer.asUint8List());
            record = new HistoryRecord.parse(bytes);
            if (!record.isValid) {
              a = _linearSearchMax(raf, a, b < _numOfEntries ? b : b - 1, timestampMax);
              break;
            } else if (record._timestamp > timestampMax) {
              timestampMax = record._timestamp;
              a = next;
            } else {
              b = next;
            }            
          }
          _head = a;
          _tail = _numOfEntries > 0 ? (_head + 1).remainder(_numOfEntries) : 0;
        }
        raf.closeSync();
      }
    }
  }

  // Searches in history range (a, b] a record with max timestamp greater or equal to the (timestamp) parameter
  int _linearSearchMax(RandomAccessFile raf, int a, int b, final int TIMESTAMP) {

    if (a == null) {
      throw new ArgumentError.notNull('a');
    } else if (a < 0 || a >= _numOfEntries) {
      throw new ArgumentError("Parameter (a) is out of range");
    }

    if (b == null) {
      throw new ArgumentError.notNull('a');
    } else if (b < 0 || b >= _numOfEntries) {
      throw new ArgumentError("Parameter (b) is out of range");
    }

    int result = a;
    int timestamp = TIMESTAMP;
    ByteData bytes = new ByteData(_recordSize);

    while (a != b) {
      a = (a + 1).remainder(_numOfEntries);
      raf.setPositionSync(a * _recordSize);
      raf.readIntoSync(bytes.buffer.asUint8List());
      HistoryRecord record = new HistoryRecord.parse(bytes);
      if (record.isValid) {
        if (record._timestamp >= timestamp) {
          timestamp = record._timestamp;
          result = a;
        }
      }
    }

    return result;
  }

  // Searches in history range (a, b] first record with timestamp greater or equal to the (timestamp) parameter
  int _linearSearchGE(RandomAccessFile raf, int a, int b, int timestampMax) {
    int result = -1;
    if (a != b) {
      result = a;
      ByteData bytes = new ByteData(_recordSize);
      while (a != b) {
        a = (a + 1).remainder(_numOfEntries);
        raf.setPositionSync(a * _recordSize);
        raf.readIntoSync(bytes.buffer.asUint8List());
        HistoryRecord record = new HistoryRecord.parse(bytes);
        if (record.isValid) {
          if (record._timestamp >= timestampMax) {
            timestampMax = record._timestamp;
            result = a;
            break;
          }
        }
      }
    }
    return result;
  }

  int find({int timestampBegin = 0}) {
    int i = _find(timestampBegin);
    //print('find($timestampBegin) => record:$i');
    return i;
  }

  int _find(int timestampBegin) {

    int result = -1;  // returns -1 if nothing found

    File file = new File(_fileName);
    if (file.existsSync() && _numOfEntries > 0) {
      RandomAccessFile raf = file.openSync(mode: FileMode.READ);
      ByteData bytes = new ByteData(_recordSize);

      raf.setPositionSync(_head * _recordSize);
      raf.readIntoSync(bytes.buffer.asUint8List());
      HistoryRecord record = new HistoryRecord.parse(bytes);
      if (!record.isValid) {
        result = _linearSearchGE(raf, _tail, _head, timestampBegin);
      } else if (record._timestamp == timestampBegin) {
        // Done, the head
        result = _head;
      } else if (record._timestamp < timestampBegin) {
        // Done, nothing found
      } else {
        raf.setPositionSync(_tail * _recordSize);
        raf.readIntoSync(bytes.buffer.asUint8List());
        record = new HistoryRecord.parse(bytes);
        if (!record.isValid) {
          result = _linearSearchGE(raf, _tail, _head, timestampBegin);
        } else if (record._timestamp >= timestampBegin) {
          // Found, the tail
          result = _tail;
        } else {
          int a = _tail;
          int b = _head;

          while (a != b) {
            int step = (b - a + _numOfEntries).remainder(_numOfEntries);
            step = step > 1 ? (step / 2).floor() : 1;
            int next = (a + step).remainder(_numOfEntries);
            //print('head:$head tail:$tail step:$step');
            raf.setPositionSync(next * _recordSize);
            raf.readIntoSync(bytes.buffer.asUint8List());

            record = new HistoryRecord.parse(bytes);
            if (!record.isValid) {
              result = _linearSearchGE(raf, a, b, timestampBegin);
              break;
            } else if (record._timestamp == timestampBegin) {
              result = next;
              break;
            } else if (record._timestamp < timestampBegin) {
              a = next;
              result = a;
            } else {
              b = next;
            }
          }
        }
      }

      raf.closeSync();
    }

    return result;
  }

  Stream<List<HistoryRecord>> read({int timestampBegin = 0, int timestampEnd = 0x7FFFFFFFFFFFFFFF,
    final int PAGE_SIZE  = _DEFAULT_HISTORY_PAGE_SIZE}) async* {

    if (PAGE_SIZE == null) {
      throw new ArgumentError.notNull('PAGE_SIZE');
    } else if (PAGE_SIZE <= 0) {
      throw new ArgumentError("PAGE_SIZE parameter must be greater than 0");
    }

    File file = new File(this._fileName);
    if (file.existsSync()) {
      ByteData bytes = new ByteData(_recordSize);
      RandomAccessFile raf = await file.open(mode: FileMode.READ);
      int numOfEntries = _numOfEntries;
      int numOfPages = (numOfEntries / PAGE_SIZE).ceil();
      int next = _find(timestampBegin);
      while (numOfPages-- > 0) {
        int pageSize = PAGE_SIZE;
        List<HistoryRecord> result = new List<HistoryRecord>();
        while (pageSize > 0 && numOfEntries-- > 0) {
          raf = await raf.setPosition(next * _recordSize);
          var r = await raf.readInto(bytes.buffer.asUint8List());
          if (r == _recordSize) {
            HistoryRecord record = new HistoryRecord.parse(bytes);
            if (record.isValid) {
              result.add(record);
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
      ByteData dataTimestamp = new ByteData(HistoryRecord.TIMESTAMP_SIZE);
      dataTimestamp.setUint64(0, timestamp);

      File file = new File(DEFAULT_HISTORY_FILE_NAME);
      RandomAccessFile raf;
      if (_head < _historySize) {
        raf = await file.open(mode: FileMode.APPEND);
      } else {
        raf = await file.open(mode: FileMode.WRITE);
        raf = await raf.setPosition(_head * _recordSize);
      }
      // Timestamp
      raf = await raf.writeFrom(dataTimestamp.buffer.asUint8List());
      // Data
      raf = await raf.writeFrom(data);
      // Checksum
      int cs = HistoryRecord.calculateChecksum(data: dataTimestamp.buffer.asUint8List());
      cs = HistoryRecord.calculateChecksum(checksum: cs, data: data);
      ByteData bd = new ByteData(8);
      bd.setUint64(0, cs);
      raf = await raf.writeFrom(bd.buffer.asUint8List());
      raf.close();

      if (++_head / _recordSize >= _historySize) {
        _head = 0;
      }
    } catch (e) {
      print('History.store failed: $e');
    }
  }
}
