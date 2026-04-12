import 'package:bvc_common/bvc_common.dart';
import 'package:test/test.dart';

void main() {
  group('formatVnd', () {
    test('phân tách hàng nghìn', () {
      expect(formatVnd(0), '0 đ');
      expect(formatVnd(1000), '1.000 đ');
      expect(formatVnd(1234567), '1.234.567 đ');
    });
  });
}
