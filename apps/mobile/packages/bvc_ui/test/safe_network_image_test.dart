import 'package:bvc_ui/bvc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeNetworkImage.looksLikeHttpUrl', () {
    test('chấp nhận http/https', () {
      expect(SafeNetworkImage.looksLikeHttpUrl('https://example.com/a.png'), isTrue);
      expect(SafeNetworkImage.looksLikeHttpUrl('http://localhost/x'), isTrue);
    });

    test('từ chối rỗng / không scheme / file / data', () {
      expect(SafeNetworkImage.looksLikeHttpUrl(''), isFalse);
      expect(SafeNetworkImage.looksLikeHttpUrl('   '), isFalse);
      expect(SafeNetworkImage.looksLikeHttpUrl('ftp://x'), isFalse);
      expect(SafeNetworkImage.looksLikeHttpUrl('not-a-url'), isFalse);
    });
  });

  testWidgets('URL không hợp lệ hiển thị errorWidget, không throw', (tester) async {
    const err = Text('ERR');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeNetworkImage(
            url: '',
            width: 40,
            height: 40,
            errorWidget: err,
          ),
        ),
      ),
    );
    expect(find.text('ERR'), findsOneWidget);
  });
}
