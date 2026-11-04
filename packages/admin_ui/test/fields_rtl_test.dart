import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _theme = buildAppTheme(irisTheme.tokens);

/// [child] in an Arabic app, laid out right to left.
Future<void> _pumpRtl(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      locale: const Locale('ar'),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: 480, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    Directionality.of(tester.element(find.byWidget(child))),
    TextDirection.rtl,
  );
}

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  testWidgets('a tag chip starts at the right and its remove button sits '
      'flush at its left end', (tester) async {
    await _pumpRtl(tester, TagsBody(value: const ['alpha'], onChanged: (_) {}));
    final label = _rect(tester, find.text('alpha'));
    final remove = _rect(tester, find.byType(IconAction));
    final chip = _rect(
      tester,
      find
          .ancestor(of: find.text('alpha'), matching: find.byType(Container))
          .first,
    );
    expect(
      chip.right - label.right,
      AdminSpacing.md,
      reason: 'the start inset',
    );
    expect(remove.left, chip.left, reason: 'no inset beside the remove');
    expect(label.left - remove.right, 0, reason: 'the 24px target spaces it');
  });

  group('media', () {
    const items = [
      MediaItem(id: 'a', name: 'a.jpg', swatch: Color(0xFF5B5BD6)),
      MediaItem(id: 'b', name: 'b.jpg', swatch: Color(0xFF0F9D8F)),
    ];

    testWidgets('the first tile is at the right, its remove button top left '
        'and its cover badge bottom right', (tester) async {
      await _pumpRtl(
        tester,
        MediaBody(cover: true, items: items, onRemove: (_) {}),
      );
      final first = _rect(tester, find.bySemanticsLabel('a.jpg'));
      final second = _rect(tester, find.bySemanticsLabel('b.jpg'));
      expect(first.left, greaterThan(second.right), reason: 'in reading order');

      final remove = _rect(tester, find.bySemanticsLabel('إزالة a.jpg'));
      expect(
        remove.topLeft - first.topLeft,
        const Offset(AdminSpacing.xxs, AdminSpacing.xxs),
      );

      final badge = _rect(
        tester,
        find
            .ancestor(of: find.text('الغلاف'), matching: find.byType(Container))
            .first,
      );
      expect(first.right - badge.right, 4);
      expect(first.bottom - badge.bottom, 4);
    });

    testWidgets('a file row keeps its drag handle at the right', (
      tester,
    ) async {
      await _pumpRtl(
        tester,
        MediaBody(
          kind: MediaKind.file,
          items: const [
            MediaItem(id: 'a', name: 'a.pdf', bytes: 1200),
            MediaItem(id: 'b', name: 'b.pdf', bytes: 2400),
          ],
          onReorder: (_, _) {},
          onRemove: (_) {},
        ),
      );
      final handle = _rect(tester, find.byIcon(Icons.drag_indicator).first);
      final row = _rect(
        tester,
        find
            .ancestor(
              of: find.byIcon(Icons.drag_indicator).first,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).border != null,
              ),
            )
            .first,
      );
      final remove = _rect(tester, find.bySemanticsLabel('إزالة a.pdf'));
      expect(
        row.right - handle.right,
        AdminSpacing.md + 1,
        reason: 'start pad + border',
      );
      expect(
        remove.left - row.left,
        AdminSpacing.md + 1,
        reason: 'end pad + border',
      );
    });
  });

  testWidgets('a reference row has its drag handle at the right, 6px from '
      'the tile', (tester) async {
    await _pumpRtl(
      tester,
      ReferenceBody<String, String>(
        value: const ['a', 'b'],
        seed: const ['a', 'b'],
        onChanged: (_) {},
        idOf: (t) => t,
        resolve: (ids) async => ids.toList(),
        search: (q, {cursor}) async => const ReferencePage([]),
        tile: (context, t) => ReferenceTileCard(title: 'Story $t'),
      ),
    );
    final handle = _rect(tester, find.byIcon(Icons.drag_indicator).first);
    final card = _rect(tester, find.byType(ReferenceTileCard).first);
    final remove = _rect(tester, find.bySemanticsLabel('إزالة').first);
    expect(handle.left, greaterThan(card.right), reason: 'the handle leads');
    expect(handle.left - card.right, 6);
    expect(remove.right, lessThan(card.left), reason: 'the remove trails');
  });

  testWidgets('a code field keeps its gutter at the left of left-to-right '
      'code, while its footer mirrors', (tester) async {
    await _pumpRtl(tester, CodeBody(value: '{"a": 1}', onChanged: (_) {}));
    final number = _rect(tester, find.text('JSON صالح'));
    final format = _rect(tester, find.text('تنسيق'));
    expect(number.left, greaterThan(format.right), reason: 'footer mirrors');

    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.textDirection, isNull);
    expect(
      Directionality.of(tester.element(find.byType(EditableText))),
      TextDirection.ltr,
    );
    final field = _rect(tester, find.byType(TextField));
    final box = _rect(tester, find.byType(CodeBody));
    expect(field.left - box.left, greaterThan(20), reason: 'gutter at left');
  });

  testWidgets('a date & time editor mirrors the date and keeps hours before '
      'minutes', (tester) async {
    await _pumpRtl(
      tester,
      DateBody(
        value: DateTime(2026, 6, 18, 14, 30),
        granularity: DateGranularity.dateTime,
        onChanged: (_) {},
      ),
    );
    await tester.tap(find.byType(DateBody));
    await tester.pumpAndSettle();
    Rect cell(String semantic) =>
        _rect(tester, find.bySemanticsLabel(semantic));
    final day = cell('اليوم');
    final month = cell('الشهر');
    final year = cell('السنة');
    final hour = cell('الساعة');
    final minute = cell('الدقيقة');
    expect(day.left, greaterThan(month.left), reason: 'Arabic reads d/M/y');
    expect(month.left, greaterThan(year.left));
    expect(year.left, greaterThan(minute.right), reason: 'the date leads');
    expect(hour.right, lessThan(minute.left), reason: 'a clock reads HH:MM');
  });

  testWidgets('a number keeps its minus in front in right-to-left text', (
    tester,
  ) async {
    await _pumpRtl(tester, NumberBody(value: -12, onChanged: (_) {}));
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.controller.text, '-12');
    expect(editor.textDirection, TextDirection.ltr);
    expect(
      editor.textAlign,
      TextAlign.right,
      reason: 'still at the start of the field',
    );
  });

  testWidgets('a collapsed field group points its chevron along the reading '
      'direction', (tester) async {
    await _pumpRtl(
      tester,
      const FieldGroup(
        title: 'Group',
        collapsible: true,
        initiallyExpanded: false,
        children: [SizedBox(height: 20)],
      ),
    );
    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, 0.25, reason: 'down turned clockwise points left');
    final chevron = _rect(tester, find.byIcon(Icons.expand_more_rounded));
    final title = _rect(tester, find.text('Group'));
    expect(chevron.left, greaterThan(title.right));
  });

  testWidgets('a boxed field group insets its header more at the start', (
    tester,
  ) async {
    await _pumpRtl(
      tester,
      FieldGroup(
        title: 'Group',
        boxed: true,
        actions: [Button('Go', onPressed: () {})],
        children: const [SizedBox(height: 20)],
      ),
    );
    final panel = _rect(tester, find.byType(Panel));
    final title = _rect(tester, find.text('Group'));
    final action = _rect(tester, find.byType(Button));
    expect(panel.right - title.right, closeTo(AdminSpacing.xl + 1, 1));
    expect(action.left - panel.left, closeTo(AdminSpacing.lg + 1, 1));
  });
}
