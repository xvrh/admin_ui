import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source]'s ramp, geometry and anatomy in the platform's font.
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
    sizes: source.sizes,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    field: source.field,
  );
}

AdminTokens _tokens(AdminTheme theme) => _fontless(theme.tokens);

Widget _host(
  AdminTokens tokens,
  Widget field, {
  bool markOptional = false,
  Set<String>? validated,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: FieldFeedbackScope(
        markOptional: markOptional,
        validated: validated,
        child: SizedBox(width: 320, child: field),
      ),
    ),
  ),
);

Widget _shell({bool required = true, String? fieldId = 'title'}) => FieldShell(
  label: 'Title',
  fieldId: fieldId,
  required: required,
  child: const InputField(value: 'Hello'),
);

Widget _labeled({bool required = true, String? fieldId = 'title'}) =>
    LabeledField(
      label: 'Title',
      fieldId: fieldId,
      required: required,
      child: const InputField(value: 'Hello'),
    );

final _star = find.text('*');

Finder _label(AdminTokens tokens) =>
    find.text(tokens.typography.fieldLabelText('Title'));

/// The global y of [finder]'s alphabetic baseline, measured on a painter
/// given what its paragraph lays out.
double _baseline(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout();
  addTearDown(painter.dispose);
  return paragraph.localToGlobal(Offset.zero).dy +
      painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
}

void main() {
  // By name: the mark's enum is read off the tokens rather than named, so
  // this reads the same through the package's barrels or around them.
  group('the theme sets the mark', () {
    const expected = {
      'Iris': 'trailing',
      'Material': 'trailing',
      'shadcn': 'trailing',
      'Ant': 'leading',
      'Fluent': 'trailing',
      'Carbon': 'optionalText',
    };
    for (final theme in adminThemes) {
      test(theme.name, () {
        expect(theme.tokens.field.requiredMark.name, expected[theme.name]);
        expect(
          theme.dark!.field.requiredMark.name,
          expected[theme.name],
          reason: 'dark keeps it',
        );
      });
    }

    test('AdminFieldStyle carries it through copyWith, lerp and ==', () {
      const style = AdminFieldStyle();
      expect(style.requiredMark.name, 'trailing');
      final mark = antTheme.tokens.field.requiredMark;
      final leading = style.copyWith(requiredMark: mark);
      expect(leading.requiredMark.name, 'leading');
      expect(leading, isNot(style));
      expect(leading, AdminFieldStyle(requiredMark: mark));
      expect(leading.hashCode, AdminFieldStyle(requiredMark: mark).hashCode);
      expect(leading.copyWith().requiredMark, mark);
      expect(
        AdminFieldStyle.lerp(style, leading, 0.4).requiredMark.name,
        'trailing',
      );
      expect(AdminFieldStyle.lerp(style, leading, 0.5).requiredMark, mark);
    });
  });

  for (final (name, build)
      in <(String, Widget Function({bool required, String? fieldId}))>[
        ('FieldShell', _shell),
        ('LabeledField', _labeled),
      ]) {
    group(name, () {
      testWidgets('Ant puts the star 4 before the label', (tester) async {
        final tokens = _tokens(antTheme);
        await tester.pumpWidget(_host(tokens, build()));
        final star = tester.getRect(_star);
        final label = tester.getRect(_label(tokens));
        expect(star.right + AdminSpacing.xs, moreOrLessEquals(label.left));
      });

      testWidgets('Ant leads from the right in a right-to-left form', (
        tester,
      ) async {
        final tokens = _tokens(antTheme);
        await tester.pumpWidget(
          _host(tokens, build(), direction: TextDirection.rtl),
        );
        final star = tester.getRect(_star);
        final label = tester.getRect(_label(tokens));
        expect(star.left - AdminSpacing.xs, moreOrLessEquals(label.right));
      });

      testWidgets('Iris puts the star 2 after the label', (tester) async {
        final tokens = _tokens(irisTheme);
        await tester.pumpWidget(_host(tokens, build()));
        final star = tester.getRect(_star);
        final label = tester.getRect(_label(tokens));
        expect(star.left, moreOrLessEquals(label.right + AdminSpacing.xxs));
      });

      for (final theme in adminThemes) {
        testWidgets('${theme.name}: the star sits on the label baseline', (
          tester,
        ) async {
          final tokens = _tokens(theme);
          await tester.pumpWidget(_host(tokens, build()));
          expect(
            _baseline(tester, _star),
            moreOrLessEquals(_baseline(tester, _label(tokens))),
          );
        });
      }

      testWidgets('no star on a field that is not required', (tester) async {
        for (final theme in adminThemes) {
          await tester.pumpWidget(
            _host(_tokens(theme), build(required: false)),
          );
          expect(_star, findsNothing, reason: theme.name);
          expect(find.text('(optional)'), findsNothing, reason: theme.name);
        }
      });

      testWidgets('Carbon marks the optional fields, under markOptional', (
        tester,
      ) async {
        final tokens = _tokens(carbonTheme);
        await tester.pumpWidget(
          _host(tokens, build(required: false), markOptional: true),
        );
        expect(find.text('(optional)'), findsOneWidget);
        expect(_star, findsNothing);
        final optional = tester.getRect(find.text('(optional)'));
        final label = tester.getRect(_label(tokens));
        expect(optional.left, moreOrLessEquals(label.right + AdminSpacing.xs));
        expect(
          _baseline(tester, find.text('(optional)')),
          moreOrLessEquals(_baseline(tester, _label(tokens))),
        );
        expect(
          tester.widget<Text>(find.text('(optional)')).style,
          tokens.typography.fieldDescription,
        );

        await tester.pumpWidget(_host(tokens, build(), markOptional: true));
        expect(find.text('(optional)'), findsNothing);
        expect(_star, findsNothing, reason: 'a required field is bare');
      });

      testWidgets('Carbon leaves bare a field the form does not validate', (
        tester,
      ) async {
        final tokens = _tokens(carbonTheme);
        for (final (field, validated) in [
          (build(required: false), const {'other'}),
          (build(required: false, fieldId: null), null),
          (build(fieldId: null), null),
        ]) {
          await tester.pumpWidget(
            _host(tokens, field, markOptional: true, validated: validated),
          );
          expect(find.text('(optional)'), findsNothing);
          expect(_star, findsNothing, reason: 'the form marks no stars');
        }
      });

      testWidgets('Carbon stars a required field outside such a form', (
        tester,
      ) async {
        final tokens = _tokens(carbonTheme);
        await tester.pumpWidget(_host(tokens, build()));
        final star = tester.getRect(_star);
        final label = tester.getRect(_label(tokens));
        expect(star.left, moreOrLessEquals(label.right + AdminSpacing.xxs));
      });

      testWidgets('the other themes ignore markOptional', (tester) async {
        for (final theme in adminThemes.where((t) => t != carbonTheme)) {
          await tester.pumpWidget(
            _host(_tokens(theme), build(required: false), markOptional: true),
          );
          expect(find.text('(optional)'), findsNothing, reason: theme.name);
          await tester.pumpWidget(
            _host(_tokens(theme), build(), markOptional: true),
          );
          expect(_star, findsOneWidget, reason: theme.name);
        }
      });

      testWidgets('the control is announced required; the marks are not read', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        for (final theme in adminThemes) {
          await tester.pumpWidget(
            _host(_tokens(theme), build(), markOptional: true),
          );
          final node = tester.getSemantics(find.byType(EditableText));
          expect(node, isSemantics(isRequired: true), reason: theme.name);
          expect(find.bySemanticsLabel(RegExp(r'\*')), findsNothing);
          await tester.pumpWidget(
            _host(_tokens(theme), build(required: false), markOptional: true),
          );
          expect(find.bySemanticsLabel(RegExp('optional')), findsNothing);
        }
        semantics.dispose();
      });
    });
  }
}
