// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:history/history.dart';

void main() {
  group('History tests', () {

  setUp(() {

    const int _TIMESTAMP_OFFSET = 0;
    const int _TIMESTAMP_SIZE = 8;
    const int _SENSOR_DATA_OFFSET = _TIMESTAMP_SIZE;
    const int _SENSOR_DATA_SIZE = 16;
    const int _CRC_OFFSET = _SENSOR_DATA_OFFSET + _SENSOR_DATA_SIZE;
    const int _CRC_SIZE = 8;
    const int _HISTORY_ENTRY_SIZE = _TIMESTAMP_SIZE + _SENSOR_DATA_SIZE + _CRC_SIZE;

    // Empty history file
    File file = new File("empty.bin");
    RandomAccessFile raf = file.openSync(mode: FileMode.WRITE);
    raf.close();

    ByteData data = new ByteData(_HISTORY_ENTRY_SIZE);
    data.setUint64(_SENSOR_DATA_OFFSET, 0);
    data.setUint64(_SENSOR_DATA_OFFSET + 8, 0);

    // 2-entries history file, not wrapped
    file = new File("2e.bin");
    raf = file.openSync(mode: FileMode.WRITE);
    for (int timestamp = 1; timestamp <= 2; timestamp++) {
      data.setUint64(_TIMESTAMP_OFFSET, timestamp);
      data.setUint64(_CRC_OFFSET, 0);
      raf.writeFromSync(data.buffer.asUint8List());
    }
    raf.close();

    // 2-entries history file, wrappped
    file = new File("2e-wrapped.bin");
    raf = file.openSync(mode: FileMode.WRITE);
    for (int timestamp = 2; timestamp > 0; timestamp--) {
      data.setUint64(_TIMESTAMP_OFFSET, timestamp);
      data.setUint64(_CRC_OFFSET, 0);
      raf.writeFromSync(data.buffer.asUint8List());
    }
    raf.close();

    // 10-entries history file, not wrapped
    file = new File("10e.bin");
    raf = file.openSync(mode: FileMode.WRITE);
    for (int timestamp = 1; timestamp <= 10; timestamp++) {
      data.setUint64(_TIMESTAMP_OFFSET, timestamp);
      data.setUint64(_CRC_OFFSET, 0);
      raf.writeFromSync(data.buffer.asUint8List());
    }
    raf.close();

    // 10-entries history file, wrapped
    file = new File("10e-wrapped.bin");
    raf = file.openSync(mode: FileMode.WRITE);
    for (int timestamp = 1; timestamp < 10; timestamp++) {
      data.setUint64(_TIMESTAMP_OFFSET, timestamp);
      data.setUint64(_CRC_OFFSET, 0);
      raf.writeFromSync(data.buffer.asUint8List());
    }
    raf.setPositionSync(0);
    for (int timestamp = 10; timestamp < 15; timestamp++) {
      data.setUint64(_TIMESTAMP_OFFSET, timestamp);
      data.setUint64(_CRC_OFFSET, 0);
      raf.writeFromSync(data.buffer.asUint8List());
    }
    raf.close();

  });

  tearDown((){
    File file;
    file = new File("empty.bin");
    file.deleteSync();
    file = new File("2e.bin");
    file.deleteSync();
    file = new File("2e-wrapped.bin");
    file.deleteSync();
    file = new File("10e.bin");
    file.deleteSync();
    file = new File("10e-wrapped.bin");
    file.deleteSync();      
  });

    test('History.open Test', () {
      History history;

      history = new History.open(fileName: "2e.bin", historyDataSize: 16);
      expect(history.t_offset, equals(0));
      
      history = new History.open(fileName: "2e-wrapped.bin", historyDataSize: 16);
      expect(history.t_offset, equals(32));
      
      history = new History.open(fileName: "10e.bin", historyDataSize: 16);
      expect(history.t_offset, equals(0));

      history = new History.open(fileName: "10e-wrapped.bin", historyDataSize: 16);
      expect(history.t_offset, equals(160));
    });
  });
}
