// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dht/dht.dart';

main() {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4);
  var future = dht22.read();

  future.then((values) {
    double humidity = values[0];
    double temperature = values[1];
    print('Humidity: ${humidity}, Temperature: ${temperature}');
  })
  .timeout(const Duration(milliseconds:550))
  .catchError((e) => print(e));

  print("Exiting");
}