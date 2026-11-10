import 'package:flutter_test/flutter_test.dart';
import 'package:motohub_app/utils/labels.dart';

void main() {
  test('price formatting groups digits and uses the currency sign', () {
    expect(formatPrice(12500, 'USD'), '\$12,500'); // comma, like the website
    expect(formatPrice(85000000, 'UZS'), '85 000 000 so\'m');
    expect(formatPrice(999, 'USD'), '\$999');
  });

  test('enum labels are translated or title-cased', () {
    expect(label('TASHKENT'), 'Toshkent');
    expect(label('HARLEY_DAVIDSON'), 'Harley-Davidson');
    expect(label('SOME_NEW_VALUE'), 'Some New Value');
  });

  test('rich-text descriptions become plain text', () {
    expect(plainText('<p>Yaxshi&nbsp;holatda</p><p>Bir egasi</p>'),
        'Yaxshi holatda\nBir egasi');
  });
}
