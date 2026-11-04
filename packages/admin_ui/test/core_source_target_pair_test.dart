import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = defaultTokens;
final _c = _tokens.palette;

Widget _host(
  Widget child, {
  double width = 760,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: buildAppTheme(_tokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: width,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

Widget _pair({
  String targetCode = 'fr',
  String? sourceText = 'Opening hours',
  Widget? targetBadge,
  Color? targetTint,
  Widget? footer,
  Widget? targetTrailing,
  Widget? target,
}) => FieldShell(
  label: 'Title',
  child: SourceTargetPair(
    sourceLocale: 'en',
    targetLocale: targetCode,
    sourceText: sourceText,
    targetBadge: targetBadge,
    targetTint: targetTint,
    footer: footer,
    targetTrailing: targetTrailing,
    target: target ?? TextBody(value: 'Horaires', onChanged: (_) {}),
  ),
);

/// A small button, taller than a line of field text.
final _copy = Button('Copy source', size: ControlSize.small, onPressed: () {});

/// The rect of the lane box under the notched label [code].
Rect _lane(WidgetTester tester, String code) => tester.getRect(
  find
      .ancestor(of: find.text(code), matching: find.byType(NotchedLabelBox))
      .first,
);

void main() {
  testWidgets('side by side the lanes share a row and a height', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_pair()));
    final source = _lane(tester, 'EN');
    final target = _lane(tester, 'FR');
    expect(source.right, lessThan(target.left));
    expect(source.top, target.top);
    expect(source.height, target.height);
    // Source 5 : target 7, around the 28px arrow gutter.
    expect(source.width / target.width, moreOrLessEquals(5 / 7, epsilon: 0.01));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('below stackBelow the target sits under the source', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_pair(), width: 420));
    final source = _lane(tester, 'EN');
    final target = _lane(tester, 'FR');
    expect(target.top, greaterThan(source.bottom));
    expect(source.left, target.left);
    expect(source.width, target.width);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  testWidgets('a one-line lane is the control height', (tester) async {
    await tester.pumpWidget(_host(_pair()));
    expect(_lane(tester, 'FR').height, _tokens.sizes.medium);
    expect(_lane(tester, 'EN').height, _tokens.sizes.medium);
  });

  testWidgets('an empty source reads as a dash', (tester) async {
    await tester.pumpWidget(_host(_pair(sourceText: null)));
    expect(find.text('—'), findsOneWidget);
  });

  for (final (name, locale) in [
    ('left to right', const Locale('en')),
    ('right to left', const Locale('ar')),
  ]) {
    testWidgets('$name: the label at the start, the badge at the end', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(locale: locale, _pair(targetBadge: const Text('Badge'))),
      );
      final target = _lane(tester, 'FR');
      final label = tester.getRect(find.text('FR'));
      final badge = tester.getRect(find.text('Badge'));
      final rtl = locale.languageCode == 'ar';
      expect(label.center.dx < target.center.dx, !rtl, reason: 'label');
      expect(badge.center.dx > target.center.dx, !rtl, reason: 'badge');
      // Both notches overhang the lane's top border.
      expect(label.top, lessThan(target.top));
      expect(badge.top, lessThan(target.top));
    });
  }

  testWidgets('the target owns the input chrome until tinted', (tester) async {
    await tester.pumpWidget(_host(_pair()));
    expect(find.byType(FieldChrome), findsOneWidget);

    await tester.pumpWidget(_host(_pair(targetTint: _c.info)));
    expect(find.byType(FieldChrome), findsNothing);
    final box = tester.widget<Container>(
      find
          .descendant(
            of: find
                .ancestor(
                  of: find.text('FR'),
                  matching: find.byType(NotchedLabelBox),
                )
                .first,
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, _c.statusFill(_c.info));
    expect((decoration.border! as Border).top.color, _c.statusBorder(_c.info));
  });

  testWidgets('the target chrome rings while its editor has focus', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_pair()));
    expect(tester.widget<FieldChrome>(find.byType(FieldChrome)).active, false);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(tester.widget<FieldChrome>(find.byType(FieldChrome)).active, true);
  });

  testWidgets('the footer and the target trailing render in place', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _pair(
          footer: const Text('Footer'),
          targetTrailing: const Text('Trailing'),
        ),
      ),
    );
    final target = _lane(tester, 'FR');
    expect(tester.getRect(find.text('Footer')).top, greaterThan(target.bottom));
    final trailing = tester.getRect(find.text('Trailing'));
    expect(target.contains(trailing.center), isTrue);
    expect(
      trailing.left,
      greaterThan(tester.getRect(find.byType(EditableText)).right),
    );
  });

  for (final (name, tint) in [('chrome', null), ('tinted', _c.info)]) {
    testWidgets('$name: a small button trailing a one-line target sits on '
        'its line and keeps the lane the control height', (tester) async {
      await tester.pumpWidget(
        _host(_pair(targetTrailing: _copy, targetTint: tint)),
      );
      final target = _lane(tester, 'FR');
      final button = tester.getRect(find.byType(Button));
      expect(button.height, greaterThan(20));
      expect(target.height, _tokens.sizes.medium);
      expect(_lane(tester, 'EN').height, _tokens.sizes.medium);
      expect(button.center.dy, target.center.dy);
      expect(
        tester.getRect(find.byType(EditableText)).center.dy,
        target.center.dy,
      );

      if (tint != null) return;
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(tester.widget<FieldChrome>(find.byType(FieldChrome)).active, true);
      expect(_lane(tester, 'FR'), target, reason: 'the focus ring');
      expect(tester.getRect(find.byType(Button)), button);
    });
  }

  testWidgets('a trailing stays on the first line of a taller target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _pair(
          targetTrailing: _copy,
          target: Builder(
            builder: (context) =>
                Text('Horaires\net accès', style: fieldTextStyle(context)),
          ),
        ),
      ),
    );
    final target = _lane(tester, 'FR');
    expect(target.height, greaterThan(_tokens.sizes.medium));
    expect(
      tester.getRect(find.byType(Button)).center.dy,
      target.top + _tokens.sizes.medium / 2,
    );
  });

  testWidgets('each lane is laid out in its own language', (tester) async {
    await tester.pumpWidget(_host(_pair(targetCode: 'ar')));
    expect(
      Directionality.of(tester.element(find.byType(EditableText))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(tester.element(find.text('Opening hours'))),
      TextDirection.ltr,
    );
    expect(
      Directionality.of(tester.element(find.text('AR'))),
      TextDirection.ltr,
      reason: 'the label stays in the admin’s direction',
    );
  });

  testWidgets('the lanes are named by language and field', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_pair()));
    expect(find.bySemanticsLabel(RegExp('^English source')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Title, French')), findsOneWidget);
    expect(find.bySemanticsLabel('EN'), findsNothing);

    await tester.pumpWidget(_host(_pair(), locale: const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^Source en anglais')), findsOneWidget);
    handle.dispose();
  });
}
