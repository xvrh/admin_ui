import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders initials, uppercased and capped to two', (tester) async {
    await tester.pumpWidget(_host(const Avatar(initials: 'abcd')));
    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('same initials get a stable auto colour', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            Avatar(initials: 'LF', key: Key('a')),
            Avatar(initials: 'LF', key: Key('b')),
          ],
        ),
      ),
    );

    Color bg(Key k) => (tester
        .widget<ColoredBox>(
          find.descendant(of: find.byKey(k), matching: find.byType(ColoredBox)),
        )
        .color);

    expect(bg(const Key('a')), bg(const Key('b')));
  });

  testWidgets('explicit colour wins', (tester) async {
    await tester.pumpWidget(
      _host(const Avatar(initials: 'XH', color: Color(0xFF123456))),
    );
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(Avatar),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, const Color(0xFF123456));
  });

  testWidgets('a name gives the initials', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            Avatar(name: 'Lena Fritz'),
            Avatar(name: '  Diego  de la Ruiz '),
            Avatar(name: 'Mononym'),
          ],
        ),
      ),
    );
    expect(find.text('LF'), findsOneWidget);
    expect(find.text('DR'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('the auto colour comes from the theme chart series', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: const Scaffold(body: Avatar(initials: 'LF')),
      ),
    );
    final fill = tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(Avatar),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;
    expect(defaultTokens.palette.chart, contains(fill));
  });

  testWidgets('the auto colour skips near-white and near-black series', (
    tester,
  ) async {
    final palette = carbonDarkPalette;
    final names = [for (var i = 0; i < 40; i++) 'Person $i'];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens.copyWith(palette: palette)),
        home: Scaffold(
          body: Wrap(children: [for (final n in names) Avatar(name: n)]),
        ),
      ),
    );
    final fills = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(Avatar),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((b) => b.color)
        .toSet();
    expect(palette.chart, contains(const Color(0xFFFFF1F1)));
    expect(fills, isNot(contains(const Color(0xFFFFF1F1))));
    expect(fills.length, greaterThan(4), reason: 'the rest still spread');
  });

  testWidgets('small avatars keep 10px initials', (tester) async {
    await tester.pumpWidget(_host(const Avatar(initials: 'AB', size: 20)));
    expect(tester.widget<Text>(find.text('AB')).style!.fontSize, 10);
  });

  testWidgets('shows the initials until the image has a frame', (tester) async {
    final image = _PendingImage();
    await tester.pumpWidget(_host(Avatar(initials: 'NA', image: image)));
    expect(find.text('NA'), findsOneWidget);
  });
}

/// An image that never finishes loading.
class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => _Never();
}

class _Never extends ImageStreamCompleter {}
