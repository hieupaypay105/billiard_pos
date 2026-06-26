int calculateModbusCRC(List<int> bytes) {
  int crc = 0xFFFF;
  for (int pos = 0; pos < bytes.length; pos++) {
    crc ^= bytes[pos];
    for (int i = 8; i != 0; i--) {
      if ((crc & 0x0001) != 0) {
        crc >>= 1;
        crc ^= 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

void main() {
  // Test data for channel 1 ON: 01 05 00 00 FF 00 -> Expected CRC: 8C 3A (which is low byte 8C, high byte 3A)
  final cmdOn = [0x01, 0x05, 0x00, 0x00, 0xFF, 0x00];
  final crcOn = calculateModbusCRC(cmdOn);
  print('On CRC: ${crcOn.toRadixString(16).padLeft(4, '0').toUpperCase()}');
  
  final cmdOff = [0x01, 0x05, 0x00, 0x00, 0x00, 0x00];
  final crcOff = calculateModbusCRC(cmdOff);
  print('Off CRC: ${crcOff.toRadixString(16).padLeft(4, '0').toUpperCase()}');
  
  // High / Low byte order verification
  // Standard Modbus RTU sends CRC with Low Byte first, then High Byte.
  final lowByteOn = crcOn & 0xFF;
  final highByteOn = (crcOn >> 8) & 0xFF;
  print('On full Hex: 01 05 00 00 FF 00 ${lowByteOn.toRadixString(16).padLeft(2, '0').toUpperCase()}${highByteOn.toRadixString(16).padLeft(2, '0').toUpperCase()}');
}
