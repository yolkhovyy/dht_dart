// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dht/dht.dart';

main() async {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4);
  int counter = 10;
  await for (List<num> data in dht22.readStream(new Duration(seconds: 2))) { 
    print('Timestamp: ${data[0]}, humidity: ${data[1]}, temperature: ${data[2]}');
    if (--counter <= 0) {
      break;
    }
  }
}