import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/notifications/phone_maker_guide.dart';

void main() {
  test('Xiaomi family shares one guide with an auto-start page', () {
    for (final m in ['Xiaomi', 'Redmi', 'POCO', ' xiaomi ']) {
      final g = guideFor(m)!;
      expect(g.brand, 'Xiaomi, Redmi or POCO');
      expect(g.hasAutoStartPage, isTrue);
      expect(g.steps, isNotEmpty);
    }
  });

  test('each common brand gets a guide', () {
    expect(guideFor('OPPO')!.brand, contains('OPPO'));
    expect(guideFor('realme')!.brand, contains('realme'));
    expect(guideFor('vivo')!.brand, 'vivo');
    expect(guideFor('INFINIX MOBILITY LIMITED')!.brand, contains('Infinix'));
    expect(guideFor('TECNO')!.brand, contains('TECNO'));
    expect(guideFor('HUAWEI')!.brand, contains('Huawei'));
  });

  test('Samsung has steps but no auto-start page', () {
    final g = guideFor('samsung')!;
    expect(g.hasAutoStartPage, isFalse);
    expect(g.steps.length, 2);
  });

  test('stock Android needs nothing extra', () {
    expect(guideFor('Google'), isNull);
    expect(guideFor(''), isNull);
  });

  test('steps never blame or rush', () {
    for (final m in [
      'xiaomi',
      'oppo',
      'vivo',
      'infinix',
      'huawei',
      'samsung',
    ]) {
      for (final s in guideFor(m)!.steps) {
        expect(s.toLowerCase(), isNot(contains('must')));
        expect(s, isNot(contains('!')));
      }
    }
  });
}
