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
      History history;

      history = new History.open(fileName: "non-existing.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(0));

      history = new History.open(fileName: "0e.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(0));
      
      history = new History.open(fileName: "1e.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(1));

      history = new History.open(fileName: "1e-incomplete.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(0));
      
      history = new History.open(fileName: "1e-invalid-0.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(1));

      history = new History.open(fileName: "2e.bin", dataSize: 16);
      expect(history.head, equals(1));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(2));
      
      history = new History.open(fileName: "2e-incomplete.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(1));

      history = new History.open(fileName: "2e-invalid-0.bin", dataSize: 16);
      expect(history.head, equals(1));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(2));      

      history = new History.open(fileName: "2e-invalid-1.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(1));
      expect(history.numOfRecords, equals(2));

      history = new History.open(fileName: "2e-wrapped.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(1));
      expect(history.numOfRecords, equals(2));
      
      history = new History.open(fileName: "2e-wrapped-invalid-0.bin", dataSize: 16);
      expect(history.head, equals(1));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(2));
      
      history = new History.open(fileName: "2e-wrapped-invalid-1.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(1));
      expect(history.numOfRecords, equals(2));

      history = new History.open(fileName: "10e.bin", dataSize: 16);
      expect(history.head, equals(9));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-incomplete.bin", dataSize: 16);
      expect(history.head, equals(8));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(9));

      history = new History.open(fileName: "10e-invalid-0.bin", dataSize: 16);
      expect(history.head, equals(9));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-invalid-3.bin", dataSize: 16);
      expect(history.head, equals(9));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));
      
      history = new History.open(fileName: "10e-invalid-6.bin", dataSize: 16);
      expect(history.head, equals(9));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));
      
      history = new History.open(fileName: "10e-invalid-3-6.bin", dataSize: 16);
      expect(history.head, equals(9));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-invalid-9.bin", dataSize: 16);
      expect(history.head, equals(8));
      expect(history.tail, equals(9));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped-invalid-0.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped-invalid-3.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped-invalid-6.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped-invalid-3-6.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-wrapped-invalid-9.bin", dataSize: 16);
      expect(history.head, equals(4));
      expect(history.tail, equals(5));
      expect(history.numOfRecords, equals(10));
      
      history = new History.open(fileName: "10e-invalid-all.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(0));
      expect(history.numOfRecords, equals(10));

      history = new History.open(fileName: "10e-all-the-same.bin", dataSize: 16);
      expect(history.head, equals(0));
      expect(history.tail, equals(1));
      expect(history.numOfRecords, equals(10));
    });


    test('History.find() test', () async {
      History history;

      history = new History.open(fileName: "0e.bin", dataSize: 16);
      for (int t = -1; t < 2; t++) {
        int r = history.find(timestampBegin: t);
        expect(r, equals(-1));
      }

      history = new History.open(fileName: "1e.bin", dataSize: 16);
      for (int t = -1; t < 2; t++) {
        int r = history.find(timestampBegin: t);
        expect(r, equals(0));
      }

      history = new History.open(fileName: "1e-incomplete.bin", dataSize: 16);
      for (int t = -1; t < 2; t++) {
        int r = history.find(timestampBegin: t);
        expect(r, equals(-1));
      }

      history = new History.open(fileName: "1e-invalid-0.bin", dataSize: 16);
      for (int t = -1; t < 2; t++) {
        int r = history.find(timestampBegin: t);
        expect(r, equals(-1));
      }

      var expected_results = [0, 0, 0, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e-incomplete.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e-invalid-0.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }
    
      expected_results = [0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e-invalid-1.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e-wrapped-invalid-0.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }
    
      expected_results = [0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "2e-wrapped-invalid-1.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }
    
      expected_results = [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1];
      history = new History.open(fileName: "10e.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-incomplete.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-invalid-0.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [0, 0, 0, 1, 2, 4, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-invalid-3.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [0, 0, 0, 1, 2, 3, 4, 6, 6, 7, 8, 9, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-invalid-6.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [0, 0, 0, 1, 2, 4, 4, 6, 6, 7, 8, 9, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-invalid-3-6.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      } 

      history = new History.open(fileName: "10e-invalid-all.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(-1));
      }

      expected_results = [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 9, 1, 2, 3, 4, -1];
      history = new History.open(fileName: "10e-wrapped-invalid-0.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 9, 0, 1, 2, 4, 4, -1];
      history = new History.open(fileName: "10e-wrapped-invalid-3.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 8, 9, 0, 1, 2, 3, 4, -1];
      history = new History.open(fileName: "10e-wrapped-invalid-6.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 8, 9, 0, 1, 2, 4, 4, -1];
      history = new History.open(fileName: "10e-wrapped-invalid-3-6.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [5, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 0, 1, 2, 3, 4, -1];
      history = new History.open(fileName: "10e-wrapped-invalid-9.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        expect(r, equals(expected_results[t]));
      }

      expected_results = [1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
      history = new History.open(fileName: "10e-all-the-same.bin", dataSize: 16);
      for (int t = 0; t < expected_results.length; t++) {
        int r = history.find(timestampBegin: t - 1);
        // TODO fix this test
        //expect(r, equals(expected_results[t]));
      }
    });

    test('History.read() test', () async {
      History history;

      history = new History.open(fileName: "10e.bin", dataSize: 16);
      for (int pageSize = 1; pageSize < 3; pageSize++) {
        Stream<List<HistoryRecord>> readStream = history.read(PAGE_SIZE: pageSize);
        int numOfPages = (history.numOfRecords / pageSize).ceil();
        int lastPageSize = history.numOfRecords.remainder(pageSize);
        if (lastPageSize == 0) {
          lastPageSize = pageSize;
        }
        int pageIndex = 0;
        await for (List<HistoryRecord> page in readStream) {
          //print('--- Page:$pageIndex ---');
          expect(page.length, equals(pageIndex < numOfPages - 1 ? pageSize : lastPageSize));
          for (HistoryRecord record in page) {
            //print('Timestamp:${record.timestamp} Checksum:${record.checksum}');
            expect(record.isValid, equals(true));
            // TODO check data
          }
          pageIndex++;
        }
      }
    }, timeout: new Timeout(new Duration(minutes: 3)));


  });


}
