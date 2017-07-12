// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dht/dht.dart';

main() async {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4);
  while (true) {
    try {
      List<num> data = await dht22.read().timeout(
          const Duration(milliseconds:550));
      if (data == null) {
        print('Timeout');
      } else {
        print('Timestamp: ${data[0]} Humidity: ${data[1]}, Temperature: ${data[2]}');
      }
    } catch(e) {
      print(e);
    }
    sleep(const Duration(seconds:2));
  }
}