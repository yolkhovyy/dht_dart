// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:dht/dht.dart';

readDHT22() {
  var dht22 = new DHT(DHT_Model.DHT22, RPI_Pin.GPIO4);
  var future = dht22.read();

  future.then((data) {
    print('Timestamp: ${data[0]} Humidity: ${data[1]}, Temperature: ${data[2]}');
  })
  .timeout(const Duration(milliseconds:550))
  .catchError((e) => print(e));

  new Future.delayed(const Duration(seconds:3), readDHT22);
}

otherActivity() {
  print("Other activity");
  new Future.delayed(const Duration(seconds:1), otherActivity);
}

main() {
  new Future(() => readDHT22());
  new Future(otherActivity);
}