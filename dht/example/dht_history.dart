// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dht/dht.dart';

main() async {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4, 75);

  print('\nReading empty history...');
  var pages = dht22.readHistory(pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }
  
  print('\nSampling...');
  int begin = new DateTime.now().millisecondsSinceEpoch;
  int counter = 50;
  do {
    try {
      List<num> sample = await dht22.read();
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
      --counter;
    } catch (e) {
      print(e);
    }
    sleep(new Duration(milliseconds: 100));
  } while (counter > 0);

  for (int pageSize = 2; pageSize < 5; pageSize++) {
    print('\nReading history, page size: $pageSize');
    pages = dht22.readHistory(begin : begin, pageSize: pageSize);
    await for (var page in pages) {
      print('Page -------');
      for (var sample in page) {
        print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
      }
    }
  }

  print('\nReading all history');
  pages = dht22.readHistory(pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }

  print('\nReading last 5 seconds of the history');
  int b = new DateTime.now().millisecondsSinceEpoch - 5 * 1000;
  pages = dht22.readHistory(begin: b, pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }

  print('\nReading first 5 seconds of the history');
  int e = begin + 5 * 1000;
  pages = dht22.readHistory(begin: begin, end: e, pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }

  print('\nSampling further...');
  counter = 50;
  do {
    try {
      List<num> sample = await dht22.read();
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
      --counter;
    } catch (e) {
      print(e);
    }
    sleep(new Duration(milliseconds: 100));
  } while (counter > 0);

  print('\nReading last 5 seconds of the history');
  b = new DateTime.now().millisecondsSinceEpoch - 5 * 1000;
  pages = dht22.readHistory(begin: b, pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }

  print('\nReading all history');
  pages = dht22.readHistory(pageSize: 100);
  await for (var page in pages) {
    for (var sample in page) {
      print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)}');
    }
  }
}