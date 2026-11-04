import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _locales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'ES', native: 'Español', status: LocaleStatus.translated),
  LocaleInfo(code: 'FR', native: 'Français', status: LocaleStatus.outdated),
];

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'live',
    current: true,
  ),
  FieldVersion(
    label: 'Published v3',
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: 'Yesterday',
  ),
];

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '14m',
    body: 'Keep the rhythm in ES.',
  ),
];

/// [source] with its theme's ramp, weights and geometry, in the platform's
/// font: a Google font would be fetched on every `weighted` call.
AdminTokens _fontless(AdminTokens source) {
  final spec = source.typography.spec;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    type: AdminTypeSpec(
      ramp: spec.ramp,
      scale: spec.scale,
      heading: spec.heading,
      strong: spec.strong,
      body: spec.body,
      tracking: spec.tracking,
      uppercaseLabels: spec.uppercaseLabels,
    ),
    elevation: source.elevation,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
  );
}

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: tokens == null ? null : buildAppTheme(tokens),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      child: Align(alignment: Alignment.topRight, child: child),
    ),
  ),
);

/// Every run of text on screen with its font size, spans included.
List<(String, double)> _textSizes(WidgetTester tester) {
  final out = <(String, double)>[];
  void visit(InlineSpan span, double inherited) {
    final size = span.style?.fontSize ?? inherited;
    if (span is TextSpan) {
      if (span.text case final text? when text.trim().isNotEmpty) {
        out.add((text, size));
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, size);
      }
    }
  }

  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    visit(paragraph.text, 14);
  }
  return out;
}

/// The translation and capability chrome, each with the control that opens
/// its popover, if it has one.
final _cases = <String, (Widget, Finder?)>{
  'LanguagePill': (
    LanguagePill(
      value: const {'EN', 'ES'},
      activeLocale: 'ES',
      locales: _locales,
      sourceLocale: 'EN',
      onChanged: (_) {},
    ),
    find.byKey(const Key('language-pill')),
  ),
  'InheritModeDropdown': (
    InheritModeDropdown(
      mode: LaneMode.inherit,
      onModeChanged: (_) {},
      sourceLabel: 'English',
    ),
    find.text('Inherited'),
  ),
  'HistoryButton': (
    const HistoryButton(
      draft: 'A coast that marks its own time',
      baseline: 'A coast that keeps its own time',
      versions: _versions,
      onRevert: _noop,
    ),
    find.text('Edited'),
  ),
  'CommentsButton': (
    const CommentsButton(
      count: 1,
      messages: _comments,
      anchor: 'its own time',
      onResolve: _noop,
    ),
    find.byType(CommentsButton),
  ),
  'HelpButton': (
    const HelpButton(text: 'Renders as the page H1.'),
    find.byType(HelpButton),
  ),
  'LaneStack': (
    SizedBox(
      width: 480,
      child: LaneStack(
        lanes: _locales,
        activeLocale: 'ES',
        modifiedLanes: const {'ES'},
        retranslate: (_) => _noop,
        laneBuilder: (lane) => TextBody(value: lane.native),
      ),
    ),
    null,
  ),
  'SourceTargetPair': (
    const SizedBox(
      width: 480,
      child: SourceTargetPair(
        sourceLocale: 'en',
        targetLocale: 'fr',
        sourceText: 'A coast that keeps its own time',
        target: TextBody(value: 'Une côte'),
      ),
    ),
    null,
  ),
};

void _noop() {}

void main() {
  testWidgets('the language picker marks each locale with the kit Check', (
    tester,
  ) async {
    Set<String>? emitted;
    await tester.pumpWidget(
      _host(
        LanguagePill(
          value: const {'ES'},
          activeLocale: 'ES',
          locales: _locales,
          sourceLocale: 'EN',
          onChanged: (s) => emitted = s,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('language-pill')));
    await tester.pumpAndSettle();

    final checks = tester.widgetList<Check>(find.byType(Check)).toList();
    expect(checks.map((c) => c.value), [false, true, false]);
    // The cell around each box takes the tap, hover and focus; the box only
    // shows the state, at its enabled contrast.
    for (final check in find.byType(Check).evaluate()) {
      expect(
        find.ancestor(
          of: find.byWidget(check.widget),
          matching: find.byType(ExcludeFocus),
        ),
        findsWidgets,
      );
      expect((check.widget as Check).onChanged, isNotNull);
    }

    await tester.tap(find.byKey(const ValueKey('lang-check-FR')));
    await tester.pumpAndSettle();
    expect(emitted, {'EN', 'ES', 'FR'});
    expect(tester.widgetList<Check>(find.byType(Check)).map((c) => c.value), [
      true,
      true,
      true,
    ]);
  });

  testWidgets('the lane mode menu is the kit Menu, driven from the keyboard', (
    tester,
  ) async {
    final chosen = <LaneMode>[];
    await tester.pumpWidget(
      _host(
        InheritModeDropdown(
          mode: LaneMode.inherit,
          onModeChanged: chosen.add,
          sourceLabel: 'English',
        ),
      ),
    );
    expect(find.byType(Menu), findsOneWidget);
    expect(find.byType(PopupMenuButton<LaneMode>), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Open on its first item, the current mode checked as a menu radio,
    // each mode saying what it does under its name.
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Set your own value'), findsOneWidget);
    final items = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.role == SemanticsRole.menuItemRadio)
        .map((s) => s.properties.checked)
        .toList();
    expect(items, [true, false]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(chosen, [LaneMode.custom]);
    expect(find.text('Custom'), findsNothing);
  });

  testWidgets('choosing the current lane mode reports nothing', (tester) async {
    final chosen = <LaneMode>[];
    await tester.pumpWidget(
      _host(
        InheritModeDropdown(
          mode: LaneMode.custom,
          onModeChanged: chosen.add,
          sourceLabel: 'English',
        ),
      ),
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    expect(chosen, isEmpty);
  });

  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final name = '${theme.name} ${dark ? 'Dark' : 'Light'}';
      final tokens = _fontless(dark ? theme.dark! : theme.tokens);

      testWidgets('$name: translation chrome sets no text below 10px', (
        tester,
      ) async {
        for (final MapEntry(key: widget, value: (child, opener))
            in _cases.entries) {
          await tester.pumpWidget(_host(child, tokens: tokens));
          if (opener != null) {
            await tester.tap(opener.first);
            await tester.pumpAndSettle();
          }

          final small = [
            for (final (text, size) in _textSizes(tester))
              if (size < 10) '"$text" at $size',
          ];
          expect(small, isEmpty, reason: '$widget in $name');
          expect(tester.takeException(), isNull, reason: '$widget in $name');
        }
      });
    }
  }
}
