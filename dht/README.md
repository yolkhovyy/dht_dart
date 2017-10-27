# DHT Dart/Native library

A library for DHTxx and SHT3x sensors.
Supported devices:
- Raspberry Pi 3
- DHT22/AM2302 (see https://www.adafruit.com/product/385)
- SHT3x (see https://www.sensirion.com/en/environmental-sensors/humidity-sensors/digital-humidity-sensors-for-various-applications/)

## Release notes
0.0.7
- Implemented SHT3x sensor support

0.0.6
- Implemented sampling history

0.0.5
- Added DHT22.readStream(Duration)

0.0.4
- Native library is not binary compatible with version 0.0.3 - please upgrade as described further in [Native lib installation/upgrade]
- Native library's DHT22.read() returns sensor data as TypedData i.s.o. an array of two Doubles

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

