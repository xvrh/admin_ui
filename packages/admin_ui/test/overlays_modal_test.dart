import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderCustomPaint;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A page with an Open button that runs [open] from the page's context.
Widget _host(void Function(BuildContext) open, {ThemeData? theme}) =>
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: TextButton(
              onPressed: () => open(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

void _viewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _sixtySentences = [
  for (var i = 1; i <= 60; i++) 'Sentence $i of a very long message.',
].join(' ');

/// Opens a confirm and records what it resolves to in [result].
Future<void> _openConfirm(
  WidgetTester tester,
  void Function(bool) result, {
  bool danger = false,
  Future<void> Function()? onConfirm,
  String Function(Object)? errorText,
}) async {
  await tester.pumpWidget(
    _host(
      (context) => showConfirmDialog(
        context,
        title: 'Delete page?',
        message: 'This cannot be undone.',
        confirmLabel: 'Delete',
        danger: danger,
        onConfirm: onConfirm,
        errorText: errorText,
      ).then(result),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('layout', () {
    testWidgets('a long message scrolls inside a 640×420 window', (
      tester,
    ) async {
      _viewSize(tester, const Size(640, 420));
      await tester.pumpWidget(
        _host(
          (context) => showModal<void>(
            context,
            builder: (context) => Modal(
              title: 'Terms',
              onDismiss: () => Navigator.of(context).maybePop(),
              message: _sixtySentences,
              actions: [
                Button.ghost('Decline', onPressed: () {}),
                Button.primary('Accept', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(Modal));
      expect(card.top, greaterThanOrEqualTo(24));
      expect(card.bottom, lessThanOrEqualTo(420 - 24));
      // Title and footer stay on screen, pinned around the scrolling body.
      expect(tester.getRect(find.text('Terms')).top, card.top + 24);
      final accept = find.ancestor(
        of: find.text('Accept'),
        matching: find.byType(Button),
      );
      expect(tester.getRect(accept).bottom, card.bottom - 24);

      final body = find.byType(SingleChildScrollView);
      expect(tester.widget<SingleChildScrollView>(body).controller, isNotNull);
      await tester.dragFrom(tester.getCenter(body), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Terms')).top, card.top + 24);
      expect(
        tester.widget<SingleChildScrollView>(body).controller!.offset,
        greaterThan(0),
      );
    });

    testWidgets('hairlines mark only the edges with content beyond them', (
      tester,
    ) async {
      _viewSize(tester, const Size(640, 420));
      await tester.pumpWidget(
        _host(
          (context) => showModal<void>(
            context,
            builder: (_) => Modal(title: 'Terms', message: _sixtySentences),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final region = find.ancestor(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(CustomPaint),
      );
      final box = tester.renderObject<RenderCustomPaint>(region.first);
      final separator = irisPalette.separator;
      final width = box.size.width;
      final bottom = Rect.fromLTWH(0, box.size.height - 1, width, 1);
      final top = Rect.fromLTWH(0, 0, width, 1);

      // At rest: more below, nothing above.
      expect(box, paints..rect(rect: bottom, color: separator));
      expect(box, isNot(paints..rect(rect: top)));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      expect(
        box,
        paints
          ..rect(rect: top, color: separator)
          ..rect(rect: bottom, color: separator),
      );
    });

    testWidgets('three actions stack at 360px, primary on top', (tester) async {
      _viewSize(tester, const Size(360, 640));
      await tester.pumpWidget(
        _host(
          (context) => showModal<void>(
            context,
            builder: (_) => Modal(
              title: 'Unsaved changes',
              message: 'Save before closing?',
              actions: [
                Button.ghost('Keep editing', onPressed: () {}),
                Button.danger('Discard changes', onPressed: () {}),
                Button.primary('Save and close', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final keep = tester.getRect(find.text('Keep editing'));
      final discard = tester.getRect(find.text('Discard changes'));
      final save = tester.getRect(find.text('Save and close'));
      expect(save.top, lessThan(discard.top));
      expect(discard.top, lessThan(keep.top));
      final card = tester.getRect(find.byType(Modal));
      expect(card.width, 360 - 48);

      // Stacked, the buttons share the content width, flush on both sides.
      final buttons = [
        for (final label in [
          'Keep editing',
          'Discard changes',
          'Save and close',
        ])
          tester.getRect(
            find.ancestor(of: find.text(label), matching: find.byType(Button)),
          ),
      ];
      for (final button in buttons) {
        expect(button.left, card.left + 24);
        expect(button.right, card.right - 24);
      }
    });

    testWidgets('24px padding, 12px title to message, 512 wide by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Modal(
                title: 'Delete page?',
                message: 'This cannot be undone.',
                actions: [Button.primary('Delete', onPressed: () {})],
              ),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(Modal));
      final title = tester.getRect(find.text('Delete page?'));
      final message = tester.getRect(find.text('This cannot be undone.'));
      final action = tester.getRect(
        find.ancestor(of: find.text('Delete'), matching: find.byType(Button)),
      );
      expect(card.width, 512);
      expect(title.left - card.left, 24);
      expect(title.top - card.top, 24);
      expect(message.top - title.bottom, 12);
      expect(action.top - message.bottom, 24);
      expect(card.bottom - action.bottom, 24);
      expect(card.right - action.right, 24);
    });

    for (final (theme, radius) in const [
      ('Material', 28.0),
      ('Carbon', 0.0),
      ('shadcn', 12.0),
    ]) {
      testWidgets('$theme: the card takes the dialog radius ($radius)', (
        tester,
      ) async {
        final preset = adminThemes.firstWhere((t) => t.name == theme);
        // The theme's radii on its palette, without its font.
        final radii = preset.tokens.radii;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(
              AdminTokens.from(palette: preset.palette, radii: radii),
            ),
            home: const Scaffold(
              body: Center(
                child: Modal(title: 'Title', message: 'Body'),
              ),
            ),
          ),
        );
        final material = tester
            .widgetList<Material>(
              find.descendant(
                of: find.byType(Modal),
                matching: find.byType(Material),
              ),
            )
            .first;
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(radius));
      });
    }
  });

  group('semantics', () {
    testWidgets('a Modal is a dialog named by its title, which is a header', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Modal(title: 'Rename', message: 'Pick a name.'),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(Modal)),
        isSemantics(
          label: 'Rename',
          scopesRoute: true,
          namesRoute: true,
          role: SemanticsRole.dialog,
        ),
      );
      expect(
        tester.getSemantics(find.text('Rename')),
        isSemantics(label: 'Rename', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('confirm is an alert dialog named by its title', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _openConfirm(tester, (_) {});
      expect(
        tester.getSemantics(find.byType(Modal)),
        isSemantics(
          label: 'Delete page?',
          namesRoute: true,
          role: SemanticsRole.alertDialog,
        ),
      );
      handle.dispose();
    });

    testWidgets('the Modal close button is a labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Modal(title: 'Rename', onDismiss: () {}, message: 'x'),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      final close = tester.getRect(find.byType(IconAction));
      expect(close.width, greaterThanOrEqualTo(24));
      expect(close.height, greaterThanOrEqualTo(24));
      handle.dispose();
    });
  });

  group('confirm', () {
    testWidgets('Cancel takes the initial focus', (tester) async {
      await _openConfirm(tester, (_) {});
      final cancel = Focus.of(tester.element(find.text('Cancel')));
      expect(cancel.hasPrimaryFocus, isTrue);
    });

    testWidgets('with onConfirm, idle Escape cancels', (tester) async {
      bool? result;
      await _openConfirm(tester, (r) => result = r, onConfirm: () async {});
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byType(Modal), findsNothing);
    });

    testWidgets('with onConfirm, an idle tap outside cancels', (tester) async {
      bool? result;
      await _openConfirm(tester, (r) => result = r, onConfirm: () async {});
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byType(Modal), findsNothing);
    });

    testWidgets('Escape and the scrim are ignored while the action runs', (
      tester,
    ) async {
      bool? result;
      final running = Completer<void>();
      await _openConfirm(
        tester,
        (r) => result = r,
        onConfirm: () => running.future,
      );
      await tester.tap(find.text('Delete'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.byType(Modal), findsOneWidget);
      expect(result, isNull);

      running.complete();
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('a danger confirm ignores the scrim but Escape cancels', (
      tester,
    ) async {
      bool? result;
      await _openConfirm(tester, (r) => result = r, danger: true);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Modal), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byType(Modal), findsNothing);
    });

    testWidgets('errorText maps the failure; the alert is a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _openConfirm(
        tester,
        (_) {},
        onConfirm: () async => throw const FormatException('409'),
        errorText: (e) => 'Mapped ${e.runtimeType}',
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Mapped FormatException'), findsOneWidget);
      expect(find.textContaining('409'), findsNothing);
      expect(
        tester.getSemantics(find.byType(Alert)),
        isSemantics(isLiveRegion: true),
      );
      // Focus returns to Cancel, so Escape still answers after a failure.
      expect(
        Focus.of(tester.element(find.text('Cancel'))).hasPrimaryFocus,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('an Error out of onConfirm is a bug: shown, and reported', (
      tester,
    ) async {
      await _openConfirm(
        tester,
        (_) {},
        onConfirm: () async => throw StateError('bug'),
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
      expect(find.byType(Modal), findsOneWidget);
    });
  });

  group('ModalAnchor', () {
    testWidgets('the overlay scopes a route and labels its barrier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final anchor = ModalAnchorController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModalAnchor(
              controller: anchor,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      anchor.show<void>(
        builder: (_) => const Modal(title: 'Anchored', message: 'Body'),
      );
      await tester.pumpAndSettle();

      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.semanticsLabel, 'Dismiss');
      final overlay = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(ModalBarrier).last,
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(overlay.properties.scopesRoute, isTrue);
      expect(overlay.explicitChildNodes, isTrue);
      handle.dispose();
    });
  });
}
