import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcHandler {
  /// Trích xuất ID thẻ (Serial Number) từ đối tượng NFCTag của flutter_nfc_kit
  /// Thư viện này tự động xử lý việc trích xuất ID từ các loại thẻ khác nhau (IsoDep, NfcA, v.v.)
  static String extractTagId(NFCTag tag) {
    print('=================================================');
    print('🔎 [SMARTCHECK DEBUG] BẮT ĐẦU DÒ TÌM DỮ LIỆU THẺ');

    // flutter_nfc_kit cung cấp trực tiếp ID trong thuộc tính .id
    String tagId = tag.id;

    if (tagId.isEmpty) {
      print('! [WARNING] Không đọc được ID thẻ.');
      return '';
    }

    // Chuẩn hóa ID: Chuyển thành chữ in hoa và loại bỏ các ký tự không phải Hex (nếu có)
    // Thông thường flutter_nfc_kit trả về dạng hex string (ví dụ: "04:A2:3C") hoặc liền nhau.
    // Ta sẽ xóa dấu ":" để đồng bộ với format của Backend
    final formattedId = tagId.replaceAll(':', '').toUpperCase();

    print('✅ Phát hiện chuẩn thẻ: ${tag.standard}');
    print('✅ Loại thẻ: ${tag.type}');
    print('🎉 [SUCCESS] ID THẺ GỐC: $tagId');
    print('🎉 [SUCCESS] ID THẺ FORMAT: $formattedId');
    print('=================================================');

    return formattedId;
  }
}