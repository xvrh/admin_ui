import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

// An empty state with a tone is the end of something, not the lack of it:
// the tone colours the icon and, where no icon is given, picks it. Nothing
// else moves, and an empty state with no tone is what it was.

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AdminTokens? tokens,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? irisTheme.tokens),
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 480, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Icon _icon(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(of: find.byType(EmptyState), matching: find.byType(Icon)),
);

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(EmptyState));

const _action = Key('action');

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  testWidgets('with no tone it is a muted inbox, as it was', (tester) async {
    await _pump(tester, const EmptyState(title: 'No orders'));
    final icon = _icon(tester);
    expect(icon.icon, Icons.inbox_outlined);
    expect(icon.color, _context(tester).colors.foregroundMuted);
  });

  testWidgets('with no tone an icon given is drawn muted', (tester) async {
    await _pump(
      tester,
      const EmptyState(icon: Icons.image_outlined, title: 'No media'),
    );
    final icon = _icon(tester);
    expect(icon.icon, Icons.image_outlined);
    expect(icon.color, _context(tester).colors.foregroundMuted);
  });

  for (final tone in Severity.values) {
    testWidgets('${tone.name}: the icon is in the tone\'s text-safe colour', (
      tester,
    ) async {
      await _pump(tester, EmptyState(title: 'Done', tone: tone));
      final context = _context(tester);
      final style = severityStyleOf(context, tone);
      expect(_icon(tester).color, style.foreground);
      expect(
        _icon(tester).color,
        isNot(context.colors.foregroundMuted),
        reason: 'a tone is not the grey of an empty list',
      );
    });

    testWidgets('${tone.name}: with no icon given, the glyph is the tone\'s', (
      tester,
    ) async {
      await _pump(tester, EmptyState(title: 'Done', tone: tone));
      expect(_icon(tester).icon, severityStyleOf(_context(tester), tone).icon);
      expect(_icon(tester).icon, isNot(Icons.inbox_outlined));
    });
  }

  testWidgets('the four tones are four colours and four glyphs', (
    tester,
  ) async {
    final colors = <Color?>{};
    final glyphs = <IconData?>{};
    for (final tone in Severity.values) {
      await _pump(tester, EmptyState(title: 'Done', tone: tone));
      colors.add(_icon(tester).color);
      glyphs.add(_icon(tester).icon);
    }
    expect(colors, hasLength(Severity.values.length));
    expect(glyphs, hasLength(Severity.values.length));
  });

  testWidgets('an icon given is kept under a tone, in the tone\'s colour', (
    tester,
  ) async {
    await _pump(
      tester,
      const EmptyState(
        icon: Icons.storefront_rounded,
        title: 'Your shop is ready',
        tone: Severity.success,
      ),
    );
    final icon = _icon(tester);
    expect(icon.icon, Icons.storefront_rounded);
    expect(
      icon.color,
      severityStyleOf(_context(tester), Severity.success).foreground,
    );
  });

  testWidgets('a tone leaves the title and the message their colours', (
    tester,
  ) async {
    await _pump(
      tester,
      const EmptyState(title: 'All caught up', message: 'Nothing waits.'),
    );
    final title = _styleOf(tester, 'All caught up');
    final message = _styleOf(tester, 'Nothing waits.');

    await _pump(
      tester,
      const EmptyState(
        title: 'All caught up',
        message: 'Nothing waits.',
        tone: Severity.success,
      ),
    );
    expect(_styleOf(tester, 'All caught up'), title);
    expect(_styleOf(tester, 'Nothing waits.'), message);
  });

  testWidgets('a tone moves nothing: the state is the size it was, its icon '
      'where it was', (tester) async {
    Widget state(Severity? tone) => EmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: 'All caught up',
      message: 'Nothing waits.',
      action: const SizedBox(key: _action, width: 96, height: 32),
      tone: tone,
    );

    await _pump(tester, state(null));
    final size = tester.getSize(find.byType(EmptyState));
    final icon = tester.getRect(find.byType(Icon).first);

    await _pump(tester, state(Severity.success));
    expect(tester.getSize(find.byType(EmptyState)), size);
    expect(tester.getRect(find.byType(Icon).first), icon);
    expect(find.byKey(_action), findsOneWidget);
  });

  testWidgets('the tone follows the theme: a dark theme draws its own', (
    tester,
  ) async {
    const state = EmptyState(title: 'Done', tone: Severity.success);
    await _pump(tester, state);
    final light = _icon(tester).color;

    await _pump(tester, state, tokens: irisTheme.dark);
    expect(_icon(tester).color, irisTheme.dark!.palette.successText);
    expect(_icon(tester).color, isNot(light));
  });

  // The icon is a graphic that carries meaning: 3:1 against what it sits on,
  // a panel or the page. The text-safe colour gives it 4.5:1; the raw status
  // colour would not, a warning's amber on white least of all.
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    test('$name: every tone\'s icon reads on a panel and on the page', () {
      for (final (tone, color) in [
        (Severity.info, palette.infoText),
        (Severity.success, palette.successText),
        (Severity.warning, palette.warningText),
        (Severity.danger, palette.dangerText),
      ]) {
        for (final surface in [palette.surface, palette.background]) {
          expect(
            contrastRatio(color, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name ${tone.name} on $surface',
          );
        }
      }
    });
  }

  testWidgets('the colour drawn is the palette\'s text role for its tone', (
    tester,
  ) async {
    for (final (tone, read) in <(Severity, Color Function(AdminPalette))>[
      (Severity.info, (p) => p.infoText),
      (Severity.success, (p) => p.successText),
      (Severity.warning, (p) => p.warningText),
      (Severity.danger, (p) => p.dangerText),
    ]) {
      await _pump(tester, EmptyState(title: 'Done', tone: tone));
      expect(_icon(tester).color, read(_context(tester).colors));
    }
  });
}
