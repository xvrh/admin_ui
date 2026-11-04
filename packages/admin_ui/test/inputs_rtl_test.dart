import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An 800×600 app in Arabic, so right to left, or in English with [ltr];
/// [child] sits centred in it, under a [ToastScope].
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool ltr = false,
  bool center = true,
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      locale: Locale(ltr ? 'en' : 'ar'),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      builder: (context, child) => ToastScope(child: child!),
      home: Scaffold(body: center ? Center(child: child) : child),
    ),
  );
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// The box of whatever holds keyboard focus, in global coordinates.
Rect _focusRect() => FocusManager.instance.primaryFocus!.rect;

void main() {
  group('popover', () {
    Widget popover() => Popover(
      anchor: (context, c) =>
          TextButton(onPressed: c.toggle, child: const Text('Open')),
      content: (context, c) =>
          const SizedBox(key: Key('content'), width: 240, height: 80),
    );

    testWidgets('start is the right edge in right-to-left', (tester) async {
      await _pump(tester, popover());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.byType(TextButton));
      final content = tester.getRect(find.byKey(const Key('content')));
      expect(content.width, greaterThan(trigger.width));
      expect((content.right - trigger.right).abs(), lessThan(0.5));
    });

    testWidgets('and the left edge in left-to-right', (tester) async {
      await _pump(tester, popover(), ltr: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.byType(TextButton));
      final content = tester.getRect(find.byKey(const Key('content')));
      expect((content.left - trigger.left).abs(), lessThan(0.5));
    });
  });

  group('toast', () {
    Finder card() => find.ancestor(
      of: find.text('Saved.'),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
    );

    Future<void> raise(WidgetTester tester, {bool ltr = false}) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ToastScope.of(context).show(const Toast('Saved.')),
            child: const Text('Raise'),
          ),
        ),
        ltr: ltr,
      );
      await tester.tap(find.text('Raise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('sits at the end edge, the left, and slides in from it', (
      tester,
    ) async {
      await raise(tester);
      final entering = tester.getRect(card());
      await tester.pumpAndSettle();
      final settled = tester.getRect(card());
      expect(settled.left, lessThan(32));
      expect(settled.right, lessThan(400));
      expect(entering.left, lessThan(settled.left));
    });

    testWidgets('and at the right in left-to-right', (tester) async {
      await raise(tester, ltr: true);
      final entering = tester.getRect(card());
      await tester.pumpAndSettle();
      final settled = tester.getRect(card());
      expect(settled.right, greaterThan(800 - 32));
      expect(entering.left, greaterThan(settled.left));
    });
  });

  group('menu button', () {
    Widget overlay() => SizedBox(
      width: 64,
      height: 28,
      child: MenuButton(
        icon: Icons.expand_more_rounded,
        maskColor: const Color(0xFFFFFFFF),
        width: 64,
        entries: [MenuItem('Rename', onSelect: () {})],
      ),
    );

    testWidgets('the caret and its opaque fade sit on the left', (
      tester,
    ) async {
      await _pump(tester, overlay());
      final icon = tester.getRect(find.byIcon(Icons.expand_more_rounded));
      final box = find.ancestor(
        of: find.byIcon(Icons.expand_more_rounded),
        matching: find.byType(Container),
      );
      final rect = tester.getRect(box.first);
      expect(icon.left - rect.left, AdminSpacing.xs);
      final gradient =
          (tester.widget<Container>(box.first).decoration! as BoxDecoration)
                  .gradient!
              as LinearGradient;
      // The opaque end of the fade, under the caret.
      expect(gradient.colors.last, const Color(0xFFFFFFFF));
      expect(gradient.end.resolve(TextDirection.rtl), Alignment.centerLeft);
      expect(gradient.begin.resolve(TextDirection.rtl), Alignment.centerRight);
    });

    testWidgets('and on the right in left-to-right', (tester) async {
      await _pump(tester, overlay(), ltr: true);
      final icon = tester.getRect(find.byIcon(Icons.expand_more_rounded));
      final rect = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.expand_more_rounded),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(rect.right - icon.right, AdminSpacing.xs);
    });
  });

  group('arrow keys follow the visual direction', () {
    testWidgets('segmented: → moves focus to the right', (tester) async {
      var value = 'b';
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Segmented<String>(
            value: value,
            onChanged: (v) => setState(() => value = v),
            segments: const [
              SegmentOption('a', 'One'),
              SegmentOption('b', 'Two'),
              SegmentOption('c', 'Three'),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      final before = _focusRect();
      expect(
        before.center.dx,
        moreOrLessEquals(tester.getCenter(find.text('Two')).dx, epsilon: 1),
      );
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusRect().center.dx, greaterThan(before.center.dx));
      expect(value, 'a');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusRect().center.dx, lessThan(before.center.dx));
      expect(value, 'c');
    });

    testWidgets('a horizontal radio group: → moves to the right', (
      tester,
    ) async {
      var value = 'b';
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Choice<String>(
            direction: Axis.horizontal,
            value: value,
            onChanged: (v) => setState(() => value = v),
            options: const [
              ChoiceOption('a', 'One'),
              ChoiceOption('b', 'Two'),
              ChoiceOption('c', 'Three'),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      final before = tester.getCenter(find.text('Two')).dx;
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(tester.getCenter(find.text('One')).dx, greaterThan(before));
      expect(value, 'a');
    });

    testWidgets('slider: → moves the thumb right, toward the minimum', (
      tester,
    ) async {
      var value = 0.5;
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) => ValueSlider(
              value: value,
              divisions: 10,
              showValue: false,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(value, lessThan(0.5));
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(value, greaterThan(0.5));
    });

    testWidgets('calendar: → moves to the day on the right', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: Calendar(value: DateTime(2026, 6, 17), onChanged: (_) {}),
        ),
      );
      // Past the month's two chevrons to the selected day.
      for (var i = 0; i < 3; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      final before = _focusRect();
      expect(before.width, lessThan(60), reason: 'a day holds focus');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      final after = _focusRect();
      expect(after.center.dx, greaterThan(before.center.dx));
      expect(after.center.dy, before.center.dy);
    });
  });

  testWidgets('the calendar chevrons mirror: previous on the right', (
    tester,
  ) async {
    await _pump(
      tester,
      SizedBox(
        width: 300,
        child: Calendar(value: DateTime(2026, 6, 17), onChanged: (_) {}),
      ),
    );
    final strings = MaterialLocalizations.of(
      tester.element(find.byType(Calendar)),
    );
    final previous = tester.getCenter(
      find.bySemanticsLabel(strings.previousMonthTooltip),
    );
    final next = tester.getCenter(
      find.bySemanticsLabel(strings.nextMonthTooltip),
    );
    expect(previous.dx, greaterThan(next.dx));
    // The chevron glyphs are drawn mirrored, so each points outward.
    final icon = tester.widget<Icon>(find.byIcon(Icons.chevron_left_rounded));
    expect(icon.icon!.matchTextDirection, isTrue);
  });

  group('side sheet', () {
    Widget opener({SideSheetSide side = SideSheetSide.end}) => Builder(
      builder: (context) => TextButton(
        onPressed: () => showSideSheet(
          context,
          side: side,
          width: 320,
          builder: (_) => const SideSheet(title: 'Sheet', child: SizedBox()),
        ),
        child: const Text('Open'),
      ),
    );

    testWidgets('sits on the left and slides in from it', (tester) async {
      await _pump(tester, opener());
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getRect(find.byType(SideSheet)).left, lessThan(0));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byType(SideSheet));
      expect(sheet.left, 0);
      expect(sheet.width, 320);
      // Its hairline runs along the inner edge, facing the page.
      final shape =
          tester
                  .widget<Material>(
                    find
                        .descendant(
                          of: find.byType(SideSheet),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .shape!
              as Border;
      expect(shape.left, BorderSide.none);
      expect(shape.right, isNot(BorderSide.none));
    });

    testWidgets('start is the right edge', (tester) async {
      await _pump(tester, opener(side: SideSheetSide.start));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(SideSheet)).right, 800);
    });

    testWidgets('a portal sheet docks the same way', (tester) async {
      final modals = ModalAnchorController();
      await _pump(
        tester,
        ModalAnchor(controller: modals, child: const SizedBox.expand()),
        center: false,
      );
      modals.showSheet<void>(
        width: 320,
        builder: (_) => const SideSheet(title: 'Sheet', child: SizedBox()),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(SideSheet)).left, 0);
      modals.close();
      await tester.pumpAndSettle();
    });
  });

  group('already directional, pinned', () {
    testWidgets('an on toggle holds its knob on the left', (tester) async {
      await _pump(tester, Toggle(value: true, onChanged: (_) {}));
      final track = tester.getRect(find.byType(AnimatedContainer));
      final knob = tester.getRect(
        find.descendant(
          of: find.byType(AnimatedAlign),
          matching: find.byType(Container),
        ),
      );
      expect(knob.center.dx, lessThan(track.center.dx));
    });

    testWidgets('a tag puts its remove button on the left', (tester) async {
      await _pump(tester, Tag('Design', onRemove: () {}));
      expect(
        tester.getCenter(find.byIcon(Icons.close_rounded)).dx,
        lessThan(tester.getCenter(find.text('Design')).dx),
      );
    });

    testWidgets('a count badge rides the top-left corner', (tester) async {
      await _pump(
        tester,
        const CountBadge(
          count: 3,
          child: SizedBox(key: Key('child'), width: 40, height: 40),
        ),
      );
      final child = tester.getRect(find.byKey(const Key('child')));
      final bubble = tester.getCenter(find.text('3'));
      expect(bubble.dx, moreOrLessEquals(child.left, epsilon: 1));
      expect(bubble.dy, moreOrLessEquals(child.top, epsilon: 1));
    });

    testWidgets('the notification bell badge leans out to the left', (
      tester,
    ) async {
      await _pump(
        tester,
        const NotificationCenter(
          items: [NotificationItem(title: 'Build passed', unread: true)],
        ),
      );
      final glyph = tester.getRect(
        find.byIcon(Icons.notifications_none_rounded),
      );
      final badge = tester.getCenter(find.text('1'));
      expect(badge.dx, lessThan(glyph.left));
    });
  });

  testWidgets('field chrome pads from the start edge', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 200,
        child: FieldChrome(
          padding: EdgeInsetsDirectional.only(start: 20),
          child: SizedBox(key: Key('content'), height: 20, width: 40),
        ),
      ),
    );
    final chrome = tester.getRect(find.byType(FieldChrome));
    final content = tester.getRect(find.byKey(const Key('content')));
    // The start inset sits inside the 1px border.
    expect(chrome.right - content.right, 21);
  });

  testWidgets('a menu shortcut reads left to right', (tester) async {
    await _pump(
      tester,
      Menu(
        entries: [MenuItem('Edit', shortcut: '⌘E', onSelect: () {})],
        builder: (context, c) =>
            TextButton(onPressed: c.toggle, child: const Text('Open')),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('⌘E')).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester.getCenter(find.text('⌘E')).dx,
      lessThan(tester.getCenter(find.text('Edit')).dx),
      reason: 'at the end of the row',
    );
  });

  group('left-to-right data keeps its order', () {
    testWidgets('an email field is typed left to right, its chrome still '
        'mirrored', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 320,
          child: InputField(
            icon: Icons.mail_outline_rounded,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      );
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.renderEditable.textDirection, TextDirection.ltr);
      final field = tester.getRect(find.byType(InputField));
      final hint = tester.getRect(find.text('name@example.com'));
      expect(
        hint.left - field.left,
        lessThan(field.right - hint.right),
        reason: 'the placeholder starts where the address will',
      );
      expect(
        tester.getCenter(find.byIcon(Icons.mail_outline_rounded)).dx,
        greaterThan(field.center.dx),
        reason: 'the icon stays at the start of an Arabic field',
      );
    });

    testWidgets('a key-value key is left to right, a value takes its own '
        'direction', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 480,
          child: KeyValueBody(
            value: const {'Authorization': 'Bearer …', 'lang': 'مرحبا'},
            onChanged: (_) {},
          ),
        ),
      );
      TextDirection direction(String text) => tester
          .state<EditableTextState>(
            find.byWidgetPredicate(
              (w) => w is EditableText && w.controller.text == text,
            ),
          )
          .renderEditable
          .textDirection;
      expect(direction('Authorization'), TextDirection.ltr);
      expect(direction('Bearer …'), TextDirection.ltr);
      expect(direction('مرحبا'), TextDirection.rtl);
    });

    test('an isolate keeps a path in its own direction', () {
      expect(bidiIsolate('/contact'), '\u2068/contact\u2069');
    });
  });
}
