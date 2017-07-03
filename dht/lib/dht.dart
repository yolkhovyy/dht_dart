// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dht;

import 'dart:async';
import 'dart:isolate';
import 'dart-ext:dht_native';

export 'src/dht_base.dart';

enum DHT_Model { DHT11, DHT22, AM2302 }

class DHT {

  int model;

  DHT(DHT_Model model) {
    this.model = model == DHT_Model.DHT11 ? 11 : 22;
  }

  static SendPort _sendPort;

  Future<List<double>> read(int pin) {
    Completer completer = new Completer();

    RawReceivePort receivePort = new RawReceivePort();
    receivePort.handler = (result) {
      receivePort.close();
      if (result != null) {
        completer.complete(result);
      } else {
        completer.completeError(new Exception("DHT data read failed"));
      }
    };

    var args = [model, pin, receivePort.sendPort];
    _getDHTServicePort.send(args);

    return completer.future;
  }

  SendPort get _getDHTServicePort {
    if (_sendPort == null) {
      _sendPort = _DHTServicePort();
    }
    return _sendPort;
  }

  SendPort _DHTServicePort() native "DHTRead_ServicePort";
}
