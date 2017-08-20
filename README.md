# DHT Dart/Native library

A library for DHTxx sensor (see https://www.adafruit.com/product/385).
Supported devices:
- Raspberry Pi 3
- DHT22 and AM2302

## Copyright notice

Use of the DHT Dart/Native source code is governed by a BSD-style license that can be found in the LICENSE files in corresponding folders.

The Native library uses:
- Adafruit Industries software which is governed by the license text in the headers of the corresponding files
https://github.com/adafruit/Adafruit_Python_DHT

- DHT22 Sensor Driver
https://github.com/Filkolev/DHT22-sensor-driver

Your use of the DHT Dart/Native signifies acknowledgement of and agreement to the aforementioned licenses.

## Content

  dht/ - Dart library

  dht_native/ - Native library, includes Adafruit Industries source code

  third_party/
	DHT22-sensor-driver/ - Linux driver

## Native lib installation/upgrade

  $ sudo cp libdht_native.so /usr/local/lib/
  $ sudo ldconfig

## Linux driver insertion example (optional)

  $ sudo insmod dht22_driver.ko gpio=4 autoupdate=1

## Usage

Simple usage examples see in the dht/example/ folder

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/yolkhovyy/dht_dart/issues

