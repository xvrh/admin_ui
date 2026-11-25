import 'dart:typed_data';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

const _data = 'https://admin.example.com/orders/48213';

Widget _host(Widget child, {AdminTokens? tokens, String locale = 'en'}) =>
    MaterialApp(
      theme: buildAppTheme(tokens ?? AdminTokens.from(palette: irisPalette)),
      locale: Locale(locale),
      supportedLocales: _kitLanguages.locales,
      localizationsDelegates: _kitLanguages.delegates,
      home: Scaffold(
        body: Center(child: RepaintBoundary(child: child)),
      ),
    );

/// The pixels of the [QrCodeView] on screen, at the device's resolution.
Future<(ByteData, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .ancestor(
          of: find.byType(QrCodeView),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final ratio = tester.view.devicePixelRatio;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData();
    final width = image.width;
    image.dispose();
    return (bytes!, width);
  }))!;
}

/// Whether the pixel at ([x], [y]) is black, white, or neither.
String _ink(ByteData bytes, int width, double x, double y) {
  final i = (y.floor() * width + x.floor()) * 4;
  final rgb = [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2)];
  if (rgb.every((c) => c < 16)) return 'black';
  if (rgb.every((c) => c > 239)) return 'white';
  return 'other';
}

void main() {
  testWidgets('is a square of its size, 176 by default', (tester) async {
    await tester.pumpWidget(_host(const QrCodeView(_data)));
    expect(tester.getSize(find.byType(QrCodeView)), const Size.square(176));

    await tester.pumpWidget(_host(const QrCodeView(_data, size: 96)));
    expect(tester.getSize(find.byType(QrCodeView)), const Size.square(96));
  });

  testWidgets('is an image named for a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const QrCodeView(_data)));
    expect(
      tester.getSemantics(find.byType(QrCodeView)),
      isSemantics(label: 'QR code', isImage: true),
    );

    await tester.pumpWidget(_host(const QrCodeView(_data), locale: 'fr'));
    expect(
      tester.getSemantics(find.byType(QrCodeView)),
      isSemantics(label: 'Code QR', isImage: true),
    );

    await tester.pumpWidget(
      _host(const QrCodeView(_data, semanticLabel: 'Order 48213')),
    );
    expect(
      tester.getSemantics(find.byType(QrCodeView)),
      isSemantics(label: 'Order 48213', isImage: true),
    );
    semantics.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('draws black modules inside a white quiet zone, '
        '${dark ? 'in a dark theme too' : 'in a light theme'}', (tester) async {
      final theme = dark ? irisTheme.dark! : irisTheme.tokens;
      await tester.pumpWidget(
        _host(const QrCodeView(_data, size: 200), tokens: theme),
      );
      final (bytes, width) = await _pixels(tester);
      final ratio = tester.view.devicePixelRatio;
      final count = QrCode.fromData(
        data: _data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      ).moduleCount;
      // As the painter lays it out: whole device pixels per module, the
      // rest added to the quiet zone.
      final module = (200 * ratio / (count + 8)).floorToDouble();
      final origin = ((200 * ratio - module * count) / 2).floorToDouble();
      double at(int cell) => origin + (cell + 0.5) * module;

      // The quiet zone, just outside the top-left finder pattern.
      expect(_ink(bytes, width, origin - module / 2, at(0)), 'white');
      // The finder pattern: a dark ring, a light ring, a dark centre.
      expect(_ink(bytes, width, at(0), at(0)), 'black');
      expect(_ink(bytes, width, at(1), at(1)), 'white');
      expect(_ink(bytes, width, at(3), at(3)), 'black');
      // The top-right and bottom-left ones.
      expect(_ink(bytes, width, at(count - 1), at(0)), 'black');
      expect(_ink(bytes, width, at(0), at(count - 1)), 'black');
      // The quiet zone past the bottom-right corner.
      expect(_ink(bytes, width, at(count), at(count)), 'white');
    });
  }

  testWidgets('data too long for a code throws', (tester) async {
    await tester.pumpWidget(_host(QrCodeView('x' * 4000)));
    expect(tester.takeException(), isA<InputTooLongException>());
  });
}
