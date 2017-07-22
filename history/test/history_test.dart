// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:history/history.dart';

void main() {
  group('History tests', () {

    setUp(() {

      const int _DATA_SIZE = 16;
      const int _ENTRY_SIZE = History.TIMESTAMP_SIZE + _DATA_SIZE + History.CHECKSUM_SIZE;
      const int _CHECKSUM_OFFSET = History.TIMESTAMP_SIZE + _DATA_SIZE;

      // Empty history file
      File file = new File("empty.bin");
      RandomAccessFile raf = file.openSync(mode: FileMode.WRITE);
      raf.close();

      ByteData data = new ByteData(_ENTRY_SIZE);
      data.setUint64(History.DATA_OFFSET, 0);
      data.setUint64(History.DATA_OFFSET + 8, 0);

      // 1-entry history file
      file = new File("1e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(History.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, not wrapped
      file = new File("2e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 2; timestamp++) {
        data.setUint64(History.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 2-entries history file, wrappped
      file = new File("2e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 2; timestamp > 0; timestamp--) {
        data.setUint64(History.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped
      file = new File("10e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(History.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, wrapped
      file = new File("10e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(History.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 10; timestamp < 15; timestamp++) {
        data.setUint64(History.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped, all timestamps the same
      file = new File("10e-flat.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(History.TIMESTAMP_OFFSET, 1);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, History.checksum(0, data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

    });

    tearDown(() {
      File file;
      file = new File("empty.bin");
      file.deleteSync();
      file = new File("1e.bin");
      file.deleteSync();
      file = new File("2e.bin");
      file.deleteSync();
      file = new File("2e-wrapped.bin");
      file.deleteSync();
      file = new File("10e.bin");
      file.deleteSync();
      file = new File("10e-wrapped.bin");
      file.deleteSync();
      file = new File("10e-flat.bin");
      file.deleteSync();      
    });

    test('History.open() test', () {
      History history;

      history = new History.open(fileName: "non-existing.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));

      history = new History.open(fileName: "empty.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));
      
      history = new History.open(fileName: "1e.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));

      history = new History.open(fileName: "2e.bin", dataSize: 16);
      expect(history.nextEntry, equals(2));
      
      history = new History.open(fileName: "2e-wrapped.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));
      
      history = new History.open(fileName: "10e.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));

      history = new History.open(fileName: "10e-wrapped.bin", dataSize: 16);
      expect(history.nextEntry, equals(5));

      history = new History.open(fileName: "10e-flat.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));
    });
  });
}
