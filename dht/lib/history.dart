
import 'dart:typed_data';
import 'dart:io';

class History {

  static const int _DEFAULT_HISTORY_SIZE = 16;
  static const int _DEFAULT_HISTORY_PAGE_SIZE = 4;

  int historySize = _DEFAULT_HISTORY_SIZE;
  int pageSize = _DEFAULT_HISTORY_PAGE_SIZE;

  static const String fileName = 'dht-history.bin';

  History([int historySize = _DEFAULT_HISTORY_SIZE]) {
    this.historySize = historySize;
  }

  store(int timestamp, Uint8List data) async {
    try {

      ByteData dataTimestamp = new ByteData(8);
      dataTimestamp.setUint64(0, timestamp);

      File file = new File(fileName);
      RandomAccessFile raf = await file.open(mode: FileMode.APPEND);
      raf = await raf.writeFrom(dataTimestamp.buffer.asUint8List());
      raf = await raf.writeFrom(data);
      raf.close();

    } catch (e) {
      print('History.store failed: $e');
    }
  }

}