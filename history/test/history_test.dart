// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:path/path.dart' as p;

import 'package:test/test.dart';
import 'package:history/history.dart';

void main() {
  group('History tests', () {

    setUp(() {

      const int _DATA_SIZE = 16;
      const int _ENTRY_SIZE = HistoryRecord.TIMESTAMP_SIZE + _DATA_SIZE + HistoryRecord.CHECKSUM_SIZE;
      const int _CHECKSUM_OFFSET = HistoryRecord.TIMESTAMP_SIZE + _DATA_SIZE;

      // Empty history file
      File file = new File("0e.bin");
      RandomAccessFile raf = file.openSync(mode: FileMode.WRITE);
      raf.close();

      ByteData data = new ByteData(_ENTRY_SIZE);
      data.setUint64(HistoryRecord.DATA_OFFSET, 0);
      data.setUint64(HistoryRecord.DATA_OFFSET + 8, 0);

      // 1-entry history file
      file = new File("1e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 29);
      raf.close();

      // 1-entry history file
      file = new File("1e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();
      
      // 1-entry history file, invalid entry
      file = new File("1e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, not wrapped
      file = new File("2e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 2; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 2-entries history file, incomplete
      file = new File("2e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 30);
      raf.close();
      
      // 2-entries history file, not wrapped, 1st inavlid
      file = new File("2e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, not wrapped, 2nd inavlid
      file = new File("2e-invalid-1.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, wrappped
      file = new File("2e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 2; timestamp > 0; timestamp--) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 2-entries history file, wrapped, 1st inavlid
      file = new File("2e-wrapped-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, wrapped, 2nd inavlid
      file = new File("2e-wrapped-invalid-1.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, not wrapped
      file = new File("10e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, incomplete
      file = new File("10e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 27);
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 0
      file = new File("10e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 2; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 3
      file = new File("10e-invalid-3.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 4; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 4);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 5; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped, invalid entry 6
      file = new File("10e-invalid-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 6; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 6);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 7; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped, invalid entry 6
      file = new File("10e-invalid-3-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 4; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 4);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 5);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 6);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 7; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 0
      file = new File("10e-invalid-9.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, wrapped
      file = new File("10e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 10; timestamp < 15; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, wrapped, invalid entry 0
      file = new File("10e-wrapped-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 11; timestamp < 15; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, wrapped, invalid entry 3
      file = new File("10e-wrapped-invalid-3.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 16; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(3 * _ENTRY_SIZE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 14);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, wrapped, invalid entry 6
      file = new File("10e-wrapped-invalid-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 16; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(6 * _ENTRY_SIZE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 7);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();
      
      // 10-entries history file, wrapped, invalid entries 3 and 6
      file = new File("10e-wrapped-invalid-3-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 11; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 16; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(3 * _ENTRY_SIZE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 14);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.setPositionSync(6 * _ENTRY_SIZE);
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 7);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());      
      raf.close();

      // 10-entries history file, wrapped, invalid entry 9
      file = new File("10e-wrapped-invalid-9.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());      
      raf.setPositionSync(0);
      for (int timestamp = 10; timestamp < 15; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, all entries invalid
      file = new File("10e-invalid-all.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()) + 1);
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, all timestamps the same
      file = new File("10e-all-the-same.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryRecord.TIMESTAMP_OFFSET, 1);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryRecord.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

    });

    tearDown(() {
      var dir = new Directory('.');
      List<FileSystemEntity> entities = dir.listSync();
      for (FileSystemEntity entity in entities) {
        if (entity is File && p.basename(entity.path).contains('.bin')) {
          entity.deleteSync();
        }
      }
    });

    test('History.open() test', () {

      Map<String, List<int>> expectedResults = {
        'non-existing.bin' : [0, 0, 0],
        '0e.bin' : [0, 0, 0],
        '1e.bin' : [0, 0, 1],
        '1e-incomplete.bin' : [0, 0, 0],
        '1e-invalid-0.bin' : [0, 0, 1],
        '2e.bin' : [1, 0, 2],
        '2e-incomplete.bin' : [0, 0, 1],
        '2e-invalid-0.bin' : [1, 0, 2],
        '2e-invalid-1.bin' : [0, 1, 2],
        '2e-wrapped.bin' : [0, 1, 2],
        '2e-wrapped-invalid-0.bin' : [1, 0, 2],
        '2e-wrapped-invalid-1.bin' : [0, 1, 2],
        '10e.bin' : [9, 0, 10],
        '10e-incomplete.bin' : [8, 0, 9],
        '10e-invalid-0.bin' : [9, 0, 10],
        '10e-invalid-3.bin' : [9, 0, 10],
        '10e-invalid-6.bin' : [9, 0, 10],
        '10e-invalid-3-6.bin' : [9, 0, 10],
        '10e-invalid-9.bin' : [8, 9, 10],
        '10e-invalid-all.bin' : [0, 0, 10],
        '10e-wrapped.bin' : [4, 5, 10],
        '10e-wrapped-invalid-0.bin' : [4, 5, 10],
        '10e-wrapped-invalid-3.bin' : [4, 5, 10],
        '10e-wrapped-invalid-6.bin' : [4, 5, 10],
        '10e-wrapped-invalid-3-6.bin' : [4, 5, 10],
        '10e-wrapped-invalid-9.bin' : [4, 5, 10],
        '10e-all-the-same.bin' : [0, 1, 10],
      };

      for (String fileName in expectedResults.keys) {
        //print('*** File:$fileName ***');
        History history = new History.open(fileName: fileName, dataSize: 16);
        expect(history.head, equals(expectedResults[fileName].elementAt(0)));
        expect(history.tail, equals(expectedResults[fileName].elementAt(1)));
        expect(history.numOfRecords, equals(expectedResults[fileName].elementAt(2)));
      }
    });


    test('History.find() test', () async {

      Map<String, List<int>> expectedResults = {
        "0e.bin" : [-1, -1, -1],
        "1e.bin" : [0, 0, 0],
        "1e-incomplete.bin" : [-1, -1, -1],
        "1e-invalid-0.bin" : [-1, -1, -1],
        "2e.bin" : [0, 0, 0, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "2e-incomplete.bin" : [0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "2e-invalid-0.bin" : [1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "2e-invalid-1.bin" : [0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "2e-wrapped-invalid-0.bin" : [1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "2e-wrapped-invalid-1.bin" : [0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "10e.bin" : [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1],
        "10e-incomplete.bin" : [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, -1, -1, -1, -1, -1],
        "10e-invalid-0.bin" : [1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1],
        "10e-invalid-3.bin" : [0, 0, 0, 1, 2, 4, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1],
        "10e-invalid-6.bin" : [0, 0, 0, 1, 2, 3, 4, 6, 6, 7, 8, 9, -1, -1, -1, -1],
        "10e-invalid-3-6.bin" : [0, 0, 0, 1, 2, 4, 4, 6, 6, 7, 8, 9, -1, -1, -1, -1],
        "10e-invalid-9.bin" : [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, -1, -1, -1, -1, -1],
        "10e-invalid-all.bin" : [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        "10e-wrapped-invalid-0.bin" : [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 9, 1, 2, 3, 4, -1],
        "10e-wrapped-invalid-3.bin" : [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 9, 0, 1, 2, 4, 4, -1],
        "10e-wrapped-invalid-6.bin" : [5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 8, 9, 0, 1, 2, 3, 4, -1],
        "10e-wrapped-invalid-3-6.bin" : [5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 8, 9, 0, 1, 2, 4, 4, -1],
        "10e-wrapped-invalid-9.bin" : [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 0, 1, 2, 3, 4, -1],
        // TODO fix the test
        //"10e-all-the-same.bin" : [1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
      };

      for (String fileName in expectedResults.keys) {
        //print('*** File:$fileName ***');
        History history = new History.open(fileName: fileName, dataSize: 16);
        for (int t = 0; t < expectedResults[fileName].length; t++) {
          int r = history.find(timestampBegin: t - 1);
          expect(r, equals(expectedResults[fileName].elementAt(t)));
        }
      }
    });

    test('History.read() page size test', () async {
      
      Map<String, List<int>> expectedResults = {
        '10e.bin' : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        '10e-wrapped.bin' : [6, 7, 8, 9, 10, 10, 11, 12, 13, 14],
        '10e-incomplete.bin' : [1, 2, 3, 4, 5, 6, 7, 8, 9],
        '10e-invalid-0.bin' : [2, 3, 4, 5, 6, 7, 8, 9, 10],
        '10e-invalid-3.bin' : [1, 2, 3, 5, 6, 7, 8, 9, 10],
        '10e-invalid-6.bin' : [1, 2, 3, 4, 5, 7, 8, 9, 10],
        '10e-invalid-3-6.bin' : [1, 2, 3, 5, 7, 8, 9, 10],
        '10e-invalid-9.bin' : [1, 2, 3, 4, 5, 6, 7, 8, 9],
        '10e-wrapped-invalid-0.bin' : [6, 7, 8, 9, 10, 11, 12, 13, 14],
        '10e-wrapped-invalid-3.bin' : [6, 7, 8, 9, 10, 11, 12, 13, 15],
        '10e-wrapped-invalid-6.bin' : [6, 8, 9, 10, 11, 12, 13, 14, 15],
        '10e-wrapped-invalid-3-6.bin' : [6, 8, 9, 10, 11, 12, 13, 15],
        '10e-wrapped-invalid-9.bin' : [6, 7, 8, 9, 10, 11, 12, 13, 14],
        '10e-all-the-same.bin' : [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        '10e-invalid-all.bin' : [],
      };

      for (String fileName in expectedResults.keys) {
        //print('*** File:$fileName ***');
        for (int pageSize = 1; pageSize < 15; pageSize++) {
          History history = new History.open(fileName: fileName, dataSize: 16);
          Stream<List<HistoryRecord>> pages = history.read(PAGE_SIZE: pageSize);
          int numOfPages = (history.numOfRecords / pageSize).ceil();
          int lastPageSize = history.numOfRecords.remainder(pageSize);
          if (lastPageSize == 0) {
            lastPageSize = pageSize;
          }
          int pageIndex = 0;
          int recordIndex = 0;
          await for (List<HistoryRecord> page in pages) {
            //print('--- Page:$pageIndex ---');
            if (!fileName.contains('invalid')) {
              expect(page.length, equals(pageIndex < numOfPages - 1 ? pageSize : lastPageSize));
            }
            for (HistoryRecord record in page) {
              //print('Timestamp:${record.timestamp} Checksum:${record.checksum}');
              expect(record.isValid, equals(true));
              expect(record.timestamp, equals(expectedResults[fileName].elementAt(recordIndex)));
              recordIndex++;
            }
            pageIndex++;
          }
        }
      }
    }, timeout: new Timeout(new Duration(minutes: 3)));


  });


}
