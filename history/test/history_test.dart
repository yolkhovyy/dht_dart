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
      const int _ENTRY_SIZE = HistoryEntry.TIMESTAMP_SIZE + _DATA_SIZE + HistoryEntry.CHECKSUM_SIZE;
      const int _CHECKSUM_OFFSET = HistoryEntry.TIMESTAMP_SIZE + _DATA_SIZE;

      // Empty history file
      File file = new File("0e.bin");
      RandomAccessFile raf = file.openSync(mode: FileMode.WRITE);
      raf.close();

      ByteData data = new ByteData(_ENTRY_SIZE);
      data.setUint64(HistoryEntry.DATA_OFFSET, 0);
      data.setUint64(HistoryEntry.DATA_OFFSET + 8, 0);

      // 1-entry history file
      file = new File("1e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 29);
      raf.close();

      // 1-entry history file
      file = new File("1e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();
      
      // 1-entry history file, invalid entry
      file = new File("1e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, not wrapped
      file = new File("2e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 2; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 2-entries history file, incomplete
      file = new File("2e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 30);
      raf.close();
      
      // 2-entries history file, not wrapped, 1st inavlid
      file = new File("2e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, not wrapped, 2nd inavlid
      file = new File("2e-invalid-1.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, wrappped
      file = new File("2e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 2; timestamp > 0; timestamp--) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 2-entries history file, wrapped, 1st inavlid
      file = new File("2e-wrapped-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 2-entries history file, wrapped, 2nd inavlid
      file = new File("2e-wrapped-invalid-1.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 2);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, not wrapped
      file = new File("10e.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, incomplete
      file = new File("10e-incomplete.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List(), 0, 27);
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 0
      file = new File("10e-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 2; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 3
      file = new File("10e-invalid-3.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 4; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 4);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 5; timestamp < 11; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped, invalid entry 6
      file = new File("10e-invalid-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 6; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 6);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 7; timestamp < 11; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, not wrapped, invalid entry 6
      file = new File("10e-invalid-3-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 4; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 4);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 5);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
      raf.writeFromSync(data.buffer.asUint8List());
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 6);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 7; timestamp < 11; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, invalid entry 0
      file = new File("10e-invalid-9.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp < 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, wrapped
      file = new File("10e-wrapped.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 10; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, wrapped, invalid entry 0
      file = new File("10e-wrapped-invalid-0.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      for (int timestamp = 11; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, wrapped, invalid entry 3
      file = new File("10e-wrapped-invalid-3.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(3 * _ENTRY_SIZE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 16);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, wrapped, invalid entry 6
      file = new File("10e-wrapped-invalid-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(6 * _ENTRY_SIZE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 16);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();
      
      // 10-entries history file, wrapped, invalid entries 3 and 6
      file = new File("10e-wrapped-invalid-3-6.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(0);
      for (int timestamp = 11; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.setPositionSync(3 * _ENTRY_SIZE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 16);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.setPositionSync(6 * _ENTRY_SIZE);
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 17);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());
      raf.close();

      // 10-entries history file, wrapped, invalid entry 9
      file = new File("10e-wrapped-invalid-9.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 10);
      data.setUint64(_CHECKSUM_OFFSET, 0);
      data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
      raf.writeFromSync(data.buffer.asUint8List());      
      raf.setPositionSync(0);
      for (int timestamp = 10; timestamp < 15; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();

      // 10-entries history file, all entries invalid
      file = new File("10e-invalid-all.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, timestamp);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()) + 1);
        raf.writeFromSync(data.buffer.asUint8List());
      }
      raf.close();
      
      // 10-entries history file, not wrapped, all timestamps the same
      file = new File("10e-flat.bin");
      raf = file.openSync(mode: FileMode.WRITE);
      for (int timestamp = 1; timestamp <= 10; timestamp++) {
        data.setUint64(HistoryEntry.TIMESTAMP_OFFSET, 1);
        data.setUint64(_CHECKSUM_OFFSET, 0);
        data.setUint64(_CHECKSUM_OFFSET, HistoryEntry.calculateChecksum(data: data.buffer.asUint8List()));
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
      expect(history.nextEntry, equals(0));

      history = new History.open(fileName: "0e.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));
      
      history = new History.open(fileName: "1e.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));

      history = new History.open(fileName: "1e-incomplete.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));
      
      history = new History.open(fileName: "1e-invalid-0.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));

      history = new History.open(fileName: "2e.bin", dataSize: 16);
      expect(history.nextEntry, equals(2));
      
      history = new History.open(fileName: "2e-incomplete.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));

      history = new History.open(fileName: "2e-invalid-0.bin", dataSize: 16);
      expect(history.nextEntry, equals(2));
      
      history = new History.open(fileName: "2e-invalid-1.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));

      history = new History.open(fileName: "2e-wrapped.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));
      
      history = new History.open(fileName: "2e-wrapped-invalid-0.bin", dataSize: 16);
      expect(history.nextEntry, equals(2));
      
      history = new History.open(fileName: "2e-wrapped-invalid-1.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));

      history = new History.open(fileName: "10e.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));

      history = new History.open(fileName: "10e-incomplete.bin", dataSize: 16);
      expect(history.nextEntry, equals(9));

      history = new History.open(fileName: "10e-invalid-0.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));

      history = new History.open(fileName: "10e-invalid-3.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));
      
      history = new History.open(fileName: "10e-invalid-6.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));
      
      history = new History.open(fileName: "10e-invalid-3-6.bin", dataSize: 16);
      expect(history.nextEntry, equals(10));

      history = new History.open(fileName: "10e-invalid-9.bin", dataSize: 16);
      expect(history.nextEntry, equals(9));
      
      history = new History.open(fileName: "10e-wrapped-invalid-0.bin", dataSize: 16);
      expect(history.nextEntry, equals(5));

      history = new History.open(fileName: "10e-wrapped-invalid-3.bin", dataSize: 16);
      expect(history.nextEntry, equals(3));

      history = new History.open(fileName: "10e-wrapped-invalid-6.bin", dataSize: 16);
      expect(history.nextEntry, equals(4));
      
      history = new History.open(fileName: "10e-wrapped-invalid-3-6.bin", dataSize: 16);
      expect(history.nextEntry, equals(3));
      
      history = new History.open(fileName: "10e-wrapped-invalid-9.bin", dataSize: 16);
      expect(history.nextEntry, equals(5));
      
      history = new History.open(fileName: "10e-invalid-all.bin", dataSize: 16);
      expect(history.nextEntry, equals(0));
      
      history = new History.open(fileName: "10e-flat.bin", dataSize: 16);
      expect(history.nextEntry, equals(1));
    });


    test('History.read() test', () async {
      History history;

      history = new History.open(fileName: "10e-invalid-6.bin", dataSize: 16);

      Stream<List<HistoryEntry>> readStream = history.read(3);
      await for (List<HistoryEntry> page in readStream) {
        for (HistoryEntry entry in page) {
          print('Timestamp: ${entry.timestamp} Checksum:${entry.checksum}');
        }
        print('---');
      }

    });



  });


}
