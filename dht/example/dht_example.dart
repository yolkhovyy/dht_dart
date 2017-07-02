// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dht/dht.dart';

main() {
  var dht22 = new DHT(DHT_Model.DHT22);
  while (true) {
    print('Reading...');
    dht22.read(4)
        .then((data) {
      print('Received');
      double humidity = data[0];
      double temperature = data[1];
      print('Humidity: ${humidity}, Temperature: ${temperature}');
    })
        .timeout(const Duration(seconds: 5), onTimeout: () {
      print('Timeout');
    })
        .catchError((error) {
      print('Error: ${error}');
    });
    print('Sleeping...');
    sleep(const Duration(seconds:7));
  }
}