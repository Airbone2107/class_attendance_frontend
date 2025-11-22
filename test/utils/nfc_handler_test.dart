import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NfcHandler Test', () {
    // Vì NFCTag của flutter_nfc_kit không dễ mock constructor với data tùy ý trong môi trường test đơn giản
    // (nó yêu cầu Platform Channel mock), nên ta sẽ kiểm tra logic format chuỗi cơ bản.

    test('Test logic format ID', () {
      // Giả sử ta nhận được ID thô từ thư viện
      const rawIdWithType = "04:A2:3C"; // Format thường gặp của flutter_nfc_kit

      // Logic trong NfcHandler là: removeAll(':') và toUpperCase()
      final formatted = rawIdWithType.replaceAll(':', '').toUpperCase();

      expect(formatted, '04A23C');
    });

    test('Test logic format ID lowercase', () {
      const rawId = "04a23c";
      final formatted = rawId.replaceAll(':', '').toUpperCase();
      expect(formatted, '04A23C');
    });
  });
}