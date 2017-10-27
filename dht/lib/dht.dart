// Copyright (c) 2017, see the AUTHORS file. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dht;

import 'dart:core';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart-ext:dht_native';

enum DHT_Model { DHT22, AM2302, SHT3x }
enum RPI_Pin {
  GPIO2, GPIO3, GPIO4, GPIO5, GPIO6, GPIO7, GPIO8, GPIO9,
  GPIO10, GPIO11, GPIO12, GPIO13, GPIO14, GPIO15, GPIO16, GPIO17, GPIO18, GPIO19,
  GPIO20, GPIO21, GPIO22, GPIO23, GPIO24, GPIO25, GPIO26, GPIO27, I2C0, I2C1
}

class DHT {

  static const int _DEFAULT_BUFFER_SIZE = 0;
  static const int _DEFAULT_HISTORY_PAGE_SIZE = 10;

  static const int TIMESTAMP_MIN = -9223372036854775808;  // -pow(2, 63);
  static const int TIMESTAMP_MAX = 9223372036854775807;   //pow(2, 63) - 1;

  int _model;
  int _pin;
  int _i2cAddress;
  
  List<List<num>> _buffer;
  int _bufferSize;
  int _bufferHead = 0;
  int _bufferTail = 0;
  int _bufferNumOfEntries = 0;

  DHT(DHT_Model model, RPI_Pin pin, [int i2cAddress = 0x45, int bufferSize = _DEFAULT_BUFFER_SIZE]) {

    if (bufferSize == null) {
      throw new ArgumentError.notNull('bufferSize');
    } else if (bufferSize < 0) {
      throw new ArgumentError("Parameter (bufferSize) must be greater than or equal to 0");
    }

    if (model == DHT_Model.DHT22 || model == DHT_Model.AM2302) {
      if (pin.index > 25) {
        throw new ArgumentError("Parameter (pin) must be one of the RPI_Pin.GPIOxx");
      }
      this._model = 22;
      this._pin = pin.index + 2;
      this._i2cAddress = 0;
    } else if (model == DHT_Model.SHT3x) {
      if (pin.index < 26) {
        throw new ArgumentError("Parameter (pin) must be one of the RPI_Pin.I2Cx");
      }
      this._model = 30;
      this._pin = pin == RPI_Pin.I2C0 ? 0 : 1;
      this._i2cAddress = i2cAddress;
    }
    
    this._bufferSize = bufferSize;
  }

  static SendPort _sendPort;

  Future<List<num>> read() {
    Completer completer = new Completer();

    RawReceivePort receivePort = new RawReceivePort();
    receivePort.handler = (TypedData result) {
      receivePort.close();
      if (result != null) {

        // Add timestamp
        int timestamp = new DateTime.now().millisecondsSinceEpoch;
        List<num> sample = [timestamp, result.buffer.asFloat32List().elementAt(0), result.buffer.asFloat32List().elementAt(1)];

        // Insert into buffer
        if (_bufferSize > 0) {
          if (_buffer == null) {
            _buffer = new List<List<num>>(_bufferSize);
          }
          _buffer[_bufferHead] = sample;
          _bufferHead = (++_bufferHead).remainder(_bufferSize);
          if (_bufferHead == _bufferTail) {
            _bufferTail = (++_bufferTail).remainder(_bufferSize);
          }
          if (_bufferNumOfEntries < _bufferSize) {
            ++_bufferNumOfEntries;
          }
          // Debug, add sample[3] = _bufferHead;
          // print('Timestamp: ${sample[0]}, humidity: ${sample[1].toStringAsFixed(1)}, temperature: ${sample[2].toStringAsFixed(1)} i:${sample[3]} n:$_bufferNumOfEntries h:$_bufferHead t:$_bufferTail');
        }

        // Complete
        completer.complete(sample);

      } else {
        completer.completeError(new Exception("DHT.read() failed"));
      }
    };

    var args = [_model, _pin, _i2cAddress, receivePort.sendPort];
    _getDHTServicePort.send(args);

    return completer.future;
  }

  Stream<List<num>> readStream(Duration interval) async* {
    while (true) {
      try {
        yield await read();
        sleep(interval);
      } catch (e) {
        print(e);
      }
    }
  }

  Future<int> _find({final int timestamp}) async {

    int result = -1;  // -1 if nothing found

    if (_bufferNumOfEntries > 0) {
      List<num> entry = _buffer[_bufferTail];
      if (entry[0] >= timestamp) {
        // Found, the tail
        result = _bufferTail;
      } else {
        int lastSampleIndex = (_bufferHead - 1).remainder(_bufferNumOfEntries);
        entry = _buffer[lastSampleIndex];
        if (entry[0] == timestamp) {
          // Found, the last sample
          result = lastSampleIndex ;
        } else if (entry[0] < timestamp) {
          // Nothing found
        } else {
          int a = _bufferHead;
          int b = lastSampleIndex;
          int step;
          while ((step = ((b - a + _bufferNumOfEntries).remainder(_bufferNumOfEntries) / 2).floor()) >= 1) {
            int next = (a + step).remainder(_bufferNumOfEntries);
            entry = _buffer[next];
            if (entry[0] == timestamp) {
              result = next;
              break;
            } else if (entry[0] < timestamp) {
              a = next;
            } else {
              b = next;
              result = next;
            }
          }
          if (result == -1) {
            entry = _buffer[b];
            if (entry[0] >= timestamp) {
              result = b;
            }
          }
        }
      }
    }

    return result;
  }

  Stream<List<List<num>>> readHistory({final int begin = TIMESTAMP_MIN, final int end = TIMESTAMP_MAX,
    final int pageSize  = _DEFAULT_HISTORY_PAGE_SIZE}) async* {

    if (pageSize == null) {
      throw new ArgumentError.notNull('pageSize');
    } else if (pageSize <= 0) {
      throw new ArgumentError("Parameter (pageSize) must be greater than 0");
    } else if (end <= begin) {
      throw new ArgumentError("The (end) parameter must be greater than the (begin) parameter");
    }

    if (_bufferNumOfEntries > 0) {
      int entryCounter = _bufferNumOfEntries;
      int pageCounter = (entryCounter / pageSize).ceil();
      int next = await _find(timestamp : begin);
      if (next >= 0) {
        while (pageCounter-- > 0) {
          int sizePage = pageSize;
          List<List<num>> result = new List<List<num>>();
          while (sizePage > 0 && entryCounter-- > 0) {
            List<num> entry = _buffer[next];
            if (entry[0] >= begin && entry[0] <= end) {
              result.add(entry);
              sizePage--;
            }
            next = (++next).remainder(_bufferNumOfEntries);
            if (next == _bufferTail) {
              break;
            }
          }
          yield result;
          if (next == _bufferTail) {
            break;
          }
        }
      }
    }
  }

  SendPort get _getDHTServicePort {
    if (_sendPort == null) {
      _sendPort = _DHTServicePort();
    }
    return _sendPort;
  }

  SendPort _DHTServicePort() native "DHTRead_ServicePort";
}

