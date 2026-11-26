import 'package:admin_ui/src/theme/text_case.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Turkish and Azerbaijani capitals keep the dot on i', () {
    expect(upperCaseIn('Değiştirildi', const Locale('tr')), 'DEĞİŞTİRİLDİ');
    expect(upperCaseIn('ılık', const Locale('tr', 'TR')), 'ILIK');
    expect(upperCaseIn('bilgi', const Locale('az')), 'BİLGİ');
  });

  test('every other language capitalizes as Dart does', () {
    expect(upperCaseIn('Edited', const Locale('en')), 'EDITED');
    expect(upperCaseIn('modifié', const Locale('fr')), 'MODIFIÉ');
    expect(upperCaseIn('Edited', null), 'EDITED');
  });
}
