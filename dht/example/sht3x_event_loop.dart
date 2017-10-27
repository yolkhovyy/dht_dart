// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:dht/dht.dart';

readSHT30x() {
  var sht3x = new DHT(DHT_Model.SHT3x, RPI_Pin.I2C1, 0x45);
  var future = sht3x.read();

  future.then((data) {
    print('Timestamp: ${data[0]} Humidity: ${data[1]}, Temperature: ${data[2]}');
  })
  .timeout(const Duration(milliseconds:750))
  .catchError((e) => print(e));

  new Future.delayed(const Duration(seconds:5), readSHT30x);
}

otherActivity() {
  print("Other activity");
  new Future.delayed(const Duration(seconds:1), otherActivity);
}

main() {
  new Future(() => readSHT30x());
  new Future(otherActivity);
}