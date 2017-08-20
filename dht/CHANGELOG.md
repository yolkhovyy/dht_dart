# Changelog

## 0.0.6

- Implemented sampling history:
    * Constructor DHT(DHT_Model model, RPI_Pin pin, [int bufferSize = _DEFAULT_BUFFER_SIZE])
    * Stream DHT.readHistory({final int begin = TIMESTAMP_MIN, final int end = TIMESTAMP_MAX, final int pageSize  = _DEFAULT_HISTORY_PAGE_SIZE})

## 0.0.5

- Implemented stream read:
    * DHT.readStream(Duration interval)

## 0.0.4

- Native library is not binary compatible with version 0.0.3 - please upgrade as described further in [Native lib installation/upgrade]
    * Native library's DHT.read() returns sensor data as TypedData i.s.o. an array of two Doubles

## 0.0.1

- Initial version, created by Stagehand
