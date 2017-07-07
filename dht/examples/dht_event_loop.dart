// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:dht/dht.dart';

readDHT22() {
  var dht22 = new DHT(DHT_Model.DHT22);
  var future = dht22.read(4);

  future.then((values) {
    double humidity = values[0];
    double temperature = values[1];
    print('Humidity: ${humidity}, Temperature: ${temperature}');
  })
  .timeout(const Duration(seconds: 5))
  .catchError((e) => print(e));

  new Future.delayed(const Duration(seconds:5), readDHT22);
}

otherActivity() {
  print("Other activity");
  new Future.delayed(const Duration(seconds:1), otherActivity);
}

main() {
  new Future(() => readDHT22());
  new Future(otherActivity);
}