// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dht;

import 'dart:core';
import 'dart:async';
import 'dart:isolate';
import 'dart-ext:dht_native';

enum DHT_Model { DHT22, AM2302 }
enum RPI_Pin {
  GPIO2, GPIO3, GPIO4, GPIO5, GPIO6, GPIO7, GPIO8, GPIO9,
  GPIO10, GPIO11, GPIO12, GPIO13, GPIO14, GPIO15, GPIO16, GPIO17, GPIO18, GPIO19,
  GPIO20, GPIO21, GPIO22, GPIO23, GPIO24, GPIO25, GPIO26, GPIO27
}

class DHT {

  int _model;
  int _pin;

  DHT(DHT_Model model, RPI_Pin pin) {
    this._model = 22;
    this._pin = pin.index + 2;
  }

  static SendPort _sendPort;

  Future<List<num>> read() {
    Completer completer = new Completer();

    RawReceivePort receivePort = new RawReceivePort();
    receivePort.handler = (result) {
      receivePort.close();
      if (result != null) {

        // Add timestamp, complete
        int timestamp = new DateTime.now().millisecondsSinceEpoch;
        List<num> data = [timestamp, result[0], result[1]];
        completer.complete(data);

        // Store in history
        // ByteData bd = new ByteData(16);
        // bd.setFloat64(0, result[0]);
        // bd.setFloat64(8, result[1]);
        // new DHT_History().store(timestamp, bd.buffer.asUint8List());

      } else {
        completer.completeError(new Exception("DHT data read failed"));
      }
    };

    var args = [_model, _pin, receivePort.sendPort];
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

