import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

void main() {
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    group(name, () {
      final tokens = AdminTokens.from(palette: palette);

      Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
            ),
          ),
        ),
      );

      /// The ring outlines: a [BoxDecoration] border in the focus colour.
      Finder rings() => find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        if (d is! BoxDecoration || d.border is! Border) return false;
        final border = d.border! as Border;
        return border.isUniform &&
            border.top.style == BorderStyle.solid &&
            border.top.color == palette.focusRing;
      });

      void expectOpaqueRing(WidgetTester tester) {
        expect(rings(), findsOneWidget);
        final side =
            ((tester.widget<DecoratedBox>(rings()).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        expect(side.width, tokens.focus.width);
        expect(side.color.a, 1, reason: 'the ring is opaque');
        expect(
          contrastRatio(side.color, palette.surface),
          greaterThanOrEqualTo(3),
          reason: 'ring vs surface',
        );
      }

      testWidgets('Button shows a ring outside its edge on keyboard focus', (
        tester,
      ) async {
        await pump(tester, const Button.primary('Save', onPressed: _noop));
        expect(rings(), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expectOpaqueRing(tester);
        final button = tester.getRect(
          find
              .ancestor(of: find.text('Save'), matching: find.byType(Material))
              .first,
        );
        final spec = tokens.focus;
        expect(
          tester.getRect(rings()),
          button.inflate(spec.offset + spec.width),
        );
      });

      testWidgets('Button drops the ring once the pointer takes over', (
        tester,
      ) async {
        await pump(tester, const Button('Save', onPressed: _noop));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(rings(), findsOneWidget);

        // Still focused, but a pointer press switches to touch highlighting.
        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.context, isNotNull);
        expect(rings(), findsNothing);
      });

      testWidgets('Tabs show a ring inside the focused tab', (tester) async {
        await pump(
          tester,
          Tabs(
            tabs: const [TabItem('General'), TabItem('SEO')],
            selected: 0,
            onChanged: (_) {},
          ),
        );
        expect(rings(), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expectOpaqueRing(tester);
        final label = tester.getRect(find.text('General'));
        expect(tester.getRect(rings()).contains(label.center), isTrue);
      });
    });
  }

  for (final spec in const [
    AdminFocusSpec(width: 2, offset: -2),
    AdminFocusSpec(width: 3, offset: 0),
  ]) {
    testWidgets('Button ring at offset ${spec.offset}, width ${spec.width}', (
      tester,
    ) async {
      // Carbon's own ring is the primary's colour; an inset ring keeps a line
      // of the page colour between it and the fill, and a flush one moves
      // out by one.
      const palette = carbonPalette;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: palette, focus: spec)),
          home: const Scaffold(
            body: Center(child: Button.primary('Save', onPressed: _noop)),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      Finder band(Color color) => find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border is Border &&
            ((w.decoration as BoxDecoration).border! as Border).isUniform &&
            ((w.decoration as BoxDecoration).border! as Border).top.color ==
                color,
      );
      final button = tester.getRect(
        find
            .ancestor(of: find.text('Save'), matching: find.byType(Material))
            .first,
      );
      final offset = spec.offset == 0 ? 1.0 : spec.offset;
      expect(
        tester.getRect(band(palette.focusRing)),
        button.inflate(offset + spec.width),
      );
      expect(tester.getRect(band(palette.surface)), button.inflate(offset));
    });
  }

  group('FocusRing', () {
    const palette = irisPalette;
    final tokens = AdminTokens.from(palette: palette);
    final spec = tokens.focus;

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens),
        home: Scaffold(body: Center(child: child)),
      ),
    );

    Finder ring() => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border! as Border).top.color ==
              palette.focusRing,
    );

    /// The box of the nearest [FocusRing] around [target].
    Rect ringed(WidgetTester tester, Finder target) => tester.getRect(
      find.ancestor(of: target, matching: find.byType(FocusRing)).first,
    );

    testWidgets('a Button in a tight parent fills it, ring and all', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: Button.primary('Save', onPressed: _noop),
        ),
      );
      final button = find
          .ancestor(of: find.text('Save'), matching: find.byType(Material))
          .first;
      expect(tester.getSize(button).width, 300);
      expect(
        tester.getCenter(find.text('Save')).dx,
        closeTo(tester.getCenter(button).dx, 0.5),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.getRect(ring()),
        tester.getRect(button).inflate(spec.offset + spec.width),
      );
    });

    for (final (name, widget, target) in [
      (
        'CopyButton',
        const CopyButton('id-42') as Widget,
        find.byIcon(Icons.copy_rounded),
      ),
      (
        'a breadcrumb link',
        const Breadcrumbs([Crumb('Home', onTap: _noop), Crumb('Page')]),
        find.text('Home'),
      ),
      (
        'the tree caret',
        SizedBox(
          width: 300,
          child: Tree(
            roots: const [
              TreeNode(
                id: 'a',
                children: [TreeNode(id: 'b')],
              ),
            ],
            itemBuilder: (_, id, _) => Text(id),
          ),
        ),
        find.byIcon(Icons.chevron_right_rounded),
      ),
      (
        'the upload zone',
        const SizedBox(width: 400, child: UploadZone(onBrowse: _noop)),
        find.byIcon(Icons.cloud_upload_outlined),
      ),
    ]) {
      testWidgets('$name draws the ring on keyboard focus only', (
        tester,
      ) async {
        await pump(tester, widget);
        expect(ring(), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(ring(), findsOneWidget);
        expect(
          tester.getRect(ring()),
          ringed(tester, target).inflate(spec.offset + spec.width),
        );

        // A pointer press switches to touch highlighting: the ring goes.
        await tester.tap(target, warnIfMissed: false);
        await tester.pump();
        expect(ring(), findsNothing);
      });
    }
  });

  testWidgets('fill Tabs keep each label centred, focused or not', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: Tabs(
                alignment: TabsAlignment.fill,
                tabs: const [TabItem('Day'), TabItem('Week'), TabItem('Month')],
                selected: 1,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    void expectCentred() {
      for (final (i, label) in ['Day', 'Week', 'Month'].indexed) {
        expect(
          tester.getCenter(find.text(label)).dx,
          closeTo(tester.getTopLeft(find.byType(Tabs)).dx + 100 + 200 * i, 1),
          reason: label,
        );
      }
    }

    expectCentred();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expectCentred();
  });

  group('a flush ring (shadcn)', () {
    Future<Rect> ringAround(WidgetTester tester, AdminTokens tokens) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: const Scaffold(
            body: Center(child: Button.primary('Save', onPressed: _noop)),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ring = find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        return d is BoxDecoration &&
            d.border is Border &&
            (d.border! as Border).top.color == tokens.palette.focusRing;
      });
      expect(ring, findsOneWidget);
      return tester.getRect(ring);
    }

    Rect button(WidgetTester tester) => tester.getRect(
      find
          .ancestor(of: find.text('Save'), matching: find.byType(Material))
          .first,
    );

    testWidgets('hugs a primary it stands 3:1 off', (tester) async {
      final tokens = shadcnTheme.tokens;
      expect(tokens.focus.offset, 0);
      final ring = await ringAround(tester, tokens);
      expect(ring, button(tester).inflate(tokens.focus.width));
    });

    testWidgets('keeps 1px off a primary in its own colour', (tester) async {
      final tokens = shadcnTheme.tokens.branded(const Color(0xFFD97706));
      final ring = await ringAround(tester, tokens);
      expect(ring, button(tester).inflate(1 + tokens.focus.width));
    });
  });
}

void _noop() {}
