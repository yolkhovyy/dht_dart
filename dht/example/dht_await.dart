// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dht/dht.dart';

main() async {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4);
  while (true) {
    try {
      List<double> values = await dht22.read().timeout(
          const Duration(milliseconds:550));
      if (values == null) {
        print('Timeout');
      } else {
        double humidity = values[0];
        double temperature = values[1];
        print('Humidity: ${humidity}, Temperature: ${temperature}');
      }
    } catch(e) {
      print(e);
    }
    sleep(const Duration(seconds:2));
  }
}