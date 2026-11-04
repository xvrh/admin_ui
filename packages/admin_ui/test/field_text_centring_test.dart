import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Real fonts whose ascent and descent split the em differently, by the
/// family the tests load them under.
const _fonts = {
  // Ascent 0.93 em, descent 0.24.
  'Roboto': 'example/assets/fonts/Roboto-Regular.ttf',
  // Ascent 1.03 em, descent 0.28.
  'Centring Plex': 'example/assets/fonts/IBMPlexSans-Regular.ttf',
  // Ascent 1.05 em, descent 0.27.
  'Centring Mono': 'example/test/fonts/RobotoMono-Regular.ttf',
};

const _value = 'Spring Catalogue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final MapEntry(key: family, value: path) in _fonts.entries) {
      final bytes = File(path).readAsBytesSync();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  final themes = {for (final theme in adminThemes) theme.name: theme.tokens};

  // A field's value, its hint and a number's prefix sit where the font
  // itself centres them: its ascent-to-descent box centred in the control,
  // which puts the baseline (ascent − descent) / 2 below the box's middle.
  // The engine then draws the baseline on a whole logical pixel, which this
  // leaves out: it moves every control's text alike.
  for (final MapEntry(key: name, value: tokens) in themes.entries) {
    for (final font in ['Roboto', 'Centring Plex', 'Centring Mono']) {
      testWidgets('$name in $font: field text is centred by its font', (
        tester,
      ) async {
        final themed = _inFont(tokens, font);
        await _pumpFields(tester, themed);
        final size = themed.typography.fieldText.fontSize!;
        final offset = _centreToBaseline(font, size);
        for (final (key, height) in _fieldKeys(themed.sizes)) {
          final box = tester.getRect(find.byKey(key));
          expect(box.height, height, reason: '$key keeps its control height');
          final lines = _textLines(tester, key);
          expect(lines, isNotEmpty, reason: '$key shows its text');
          for (final (text, baseline) in lines) {
            expect(
              baseline - box.center.dy,
              moreOrLessEquals(offset, epsilon: 0.01),
              reason: '"$text" in $key',
            );
          }
        }
      });
    }
  }
}

const _input = ValueKey('input');
const _inputSmall = ValueKey('input small');
const _hint = ValueKey('hint');
const _trigger = ValueKey('trigger');
const _triggerSmall = ValueKey('trigger small');
const _number = ValueKey('number');

/// Each measured field and the control height it keeps.
List<(Key, double)> _fieldKeys(AdminControlSizes sizes) => [
  (_input, sizes.medium),
  (_inputSmall, sizes.small),
  (_hint, sizes.medium),
  (_trigger, sizes.medium),
  (_triggerSmall, sizes.small),
  (_number, sizes.medium),
];

Future<void> _pumpFields(WidgetTester tester, AdminTokens tokens) async {
  Widget trigger(Key key, ControlSize size) => FieldTrigger(
    key: key,
    controller: _Closed(),
    size: size,
    chevron: true,
    child: Builder(
      builder: (context) => Text(_value, style: fieldTextStyle(context)),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InputField(key: _input, value: _value),
              const InputField(
                key: _inputSmall,
                value: _value,
                size: ControlSize.small,
              ),
              const InputField(key: _hint, hint: _value),
              trigger(_trigger, ControlSize.medium),
              trigger(_triggerSmall, ControlSize.small),
              NumberBody(
                key: _number,
                value: 12.5,
                decimals: 2,
                prefix: '€',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Each line of text under [key] and its baseline, laid out as the engine
/// lays out its render object: a value, a hint, a prefix.
List<(String, double)> _textLines(WidgetTester tester, Key key) {
  final lines = <(String, double)>[];
  void visit(RenderObject object) {
    final (text, painter) = switch (object) {
      RenderEditable(:final text?) => (
        text,
        TextPainter(
          text: text,
          textDirection: object.textDirection,
          textScaler: object.textScaler,
          strutStyle: object.strutStyle,
          textHeightBehavior: object.textHeightBehavior,
        ),
      ),
      RenderParagraph(:final text) => (
        text,
        TextPainter(
          text: text,
          textDirection: object.textDirection,
          textScaler: object.textScaler,
          strutStyle: object.strutStyle,
          textHeightBehavior: object.textHeightBehavior,
        ),
      ),
      _ => (null, null),
    };
    final plain = text?.toPlainText() ?? '';
    // Icons are text too: only the words are measured.
    if (painter != null && RegExp('[A-Za-z0-9€]').hasMatch(plain)) {
      final box = object as RenderBox;
      painter.layout(maxWidth: box.size.width);
      final top = box.localToGlobal(Offset.zero).dy;
      lines.add((
        plain,
        top + painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ));
      painter.dispose();
      return;
    }
    painter?.dispose();
    object.visitChildren(visit);
  }

  tester.renderObject(find.byKey(key)).visitChildren(visit);
  return lines;
}

/// How far below the middle of a box [family] puts its baseline at [size]
/// when its ascent-to-descent box is centred in it: (ascent − descent) / 2.
double _centreToBaseline(String family, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: 'H',
      style: TextStyle(fontFamily: family, fontSize: size),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final metrics = painter.computeLineMetrics().single;
  painter.dispose();
  return (metrics.ascent - metrics.descent) / 2;
}

/// [tokens] with its type set in [family], every other choice kept.
AdminTokens _inFont(AdminTokens tokens, String family) {
  final spec = tokens.typography.spec;
  return tokens.copyWith(
    typography: AdminTypography.from(
      tokens.palette,
      AdminTypeSpec(
        scale: spec.scale,
        ramp: spec.ramp,
        fontFamily: family,
        heading: spec.heading,
        label: spec.label,
        strong: spec.strong,
        body: spec.body,
        tracking: spec.tracking,
        uppercaseLabels: spec.uppercaseLabels,
      ),
    ),
  );
}

class _Closed implements PopoverController {
  @override
  void open() {}

  @override
  void close() {}

  @override
  void toggle() {}

  @override
  bool get isOpen => false;

  @override
  double? get anchorWidth => null;
}
