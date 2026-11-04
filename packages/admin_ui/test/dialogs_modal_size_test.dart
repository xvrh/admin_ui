import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void _viewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  supportedLocales: AdminLocalizations.supportedLocales,
  home: home,
);

Widget _inline(Widget modal) => _app(Scaffold(body: Center(child: modal)));

/// A page with an Open button that runs [open] from the page's context.
Widget _host(void Function(BuildContext) open) => _app(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, WidgetBuilder builder) async {
  await tester.pumpWidget(
    _host((context) => showModal<void>(context, builder: builder)),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Material _cardMaterial(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(of: find.byType(Modal), matching: find.byType(Material)),
    )
    .first;

void main() {
  group('size', () {
    for (final (size, width) in const [
      (ModalSize.small, 400.0),
      (ModalSize.medium, 512.0),
      (ModalSize.large, 720.0),
    ]) {
      testWidgets('${size.name} is $width wide', (tester) async {
        _viewSize(tester, const Size(1200, 800));
        await tester.pumpWidget(
          _inline(Modal(size: size, title: 'Title', message: 'Body')),
        );
        expect(tester.getSize(find.byType(Modal)).width, width);
        expect(size.width, width);
      });

      testWidgets('${size.name} stops 24px short of a 360px screen', (
        tester,
      ) async {
        _viewSize(tester, const Size(360, 640));
        await _open(
          tester,
          (_) => Modal(size: size, title: 'Title', message: 'Body'),
        );
        final card = tester.getRect(find.byType(Modal));
        expect(card.left, 24);
        expect(card.width, 360 - 48);
      });
    }

    testWidgets('medium is the default, and maxWidth wins over the size', (
      tester,
    ) async {
      _viewSize(tester, const Size(1200, 800));
      await tester.pumpWidget(_inline(const Modal(title: 'Title')));
      expect(tester.getSize(find.byType(Modal)).width, 512);

      await tester.pumpWidget(
        _inline(
          const Modal(size: ModalSize.large, maxWidth: 380, title: 'Title'),
        ),
      );
      expect(tester.getSize(find.byType(Modal)).width, 380);
      expect(
        () => Modal(size: ModalSize.fullscreen, maxWidth: 380),
        throwsAssertionError,
      );
    });
  });

  group('fullscreen', () {
    Widget editor(BuildContext context) => Modal(
      size: ModalSize.fullscreen,
      title: 'Edit page',
      onDismiss: () => Navigator.of(context).maybePop(),
      message: 'Body',
      actions: [Button.primary('Save', onPressed: () {})],
    );

    testWidgets('fills the screen with square corners, no border, no shadow '
        'and no margin', (tester) async {
      _viewSize(tester, const Size(800, 600));
      await _open(tester, editor);

      expect(
        tester.getRect(find.byType(Modal)),
        Offset.zero & const Size(800, 600),
      );
      final material = _cardMaterial(tester);
      final shape = material.shape;
      expect(
        shape == null ||
            (shape is RoundedRectangleBorder &&
                shape.borderRadius == BorderRadius.zero &&
                shape.side == BorderSide.none),
        isTrue,
      );
      expect(material.elevation, 0);
      final shadows = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Modal),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.boxShadow?.isNotEmpty ?? false);
      expect(shadows, isEmpty);

      // The header on top, the footer pinned to the bottom.
      expect(tester.getRect(find.text('Edit page')).top, 24);
      final save = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(Button),
      );
      expect(tester.getRect(save).bottom, 600 - 24);
      expect(tester.getRect(save).right, 800 - 24);

      // The margin comes back for the next modal the route shows.
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.byType(Modal), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Modal)).top, 0);
    });

    testWidgets('its content keeps inside the safe area', (tester) async {
      _viewSize(tester, const Size(400, 800));
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      await _open(tester, editor);

      expect(
        tester.getRect(find.byType(Modal)),
        Offset.zero & const Size(400, 800),
      );
      expect(tester.getRect(find.text('Edit page')).top, 47 + 24);
      final save = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(Button),
      );
      expect(tester.getRect(save).bottom, 800 - 34 - 24);

      // Turned to a screen with another safe area, it follows.
      tester.view.padding = const FakeViewPadding(top: 20);
      await tester.pump();
      expect(tester.getRect(find.text('Edit page')).top, 20 + 24);
      expect(tester.getRect(save).bottom, 800 - 24);
    });

    testWidgets('a sized modal keeps 24px inside the safe area, which its '
        'content no longer sees', (tester) async {
      _viewSize(tester, const Size(360, 400));
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      late EdgeInsets seen;
      await _open(
        tester,
        (_) => Modal(
          title: 'Terms',
          body: Builder(
            builder: (context) {
              seen = MediaQuery.paddingOf(context);
              return Text(List.filled(80, 'Long terms.').join(' '));
            },
          ),
        ),
      );
      final card = tester.getRect(find.byType(Modal));
      expect(card.top, 47 + 24);
      expect(card.bottom, 400 - 34 - 24);
      expect(seen, EdgeInsets.zero);
    });

    testWidgets('a medium modal shown from inside it keeps the outer frame', (
      tester,
    ) async {
      _viewSize(tester, const Size(800, 600));
      final anchor = ModalAnchorController();
      await _open(
        tester,
        (context) => Modal(
          title: 'Outer',
          body: SizedBox(
            height: 100,
            child: ModalAnchor(
              controller: anchor,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      final outer = tester.getRect(find.byType(Modal));
      anchor.show<void>(
        builder: (_) => const Modal(size: ModalSize.fullscreen, title: 'Inner'),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Modal).first), outer);
      expect(
        tester.getRect(find.byType(Modal).last),
        Offset.zero & const Size(800, 600),
      );
    });
  });

  group('description', () {
    testWidgets('sits 8px under the title, 12px above the content', (
      tester,
    ) async {
      for (final dismissible in [false, true]) {
        await tester.pumpWidget(
          _inline(
            Modal(
              title: 'Invite teammates',
              description: 'They get an email with a link.',
              onDismiss: dismissible ? () {} : null,
              message: 'Body',
              actions: [Button.primary('Send', onPressed: () {})],
            ),
          ),
        );
        final reason = 'close $dismissible';
        final card = tester.getRect(find.byType(Modal));
        final title = tester.getRect(find.text('Invite teammates'));
        final description = tester.getRect(
          find.text('They get an email with a link.'),
        );
        final body = tester.getRect(find.text('Body'));
        final send = tester.getRect(
          find.ancestor(of: find.text('Send'), matching: find.byType(Button)),
        );
        expect(title.top - card.top, 24, reason: reason);
        expect(description.top - title.bottom, 8, reason: reason);
        expect(description.left, title.left, reason: reason);
        expect(body.top - description.bottom, 12, reason: reason);
        expect(send.top - body.bottom, 24, reason: reason);
      }
    });

    testWidgets('is muted body text', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _inline(
          Builder(
            builder: (c) {
              context = c;
              return const Modal(title: 'Title', description: 'Described');
            },
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Described'));
      expect(text.style, context.type.bodyMuted);
    });

    testWidgets('is read with the dialog, after its name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _inline(
          const Modal(
            title: 'Invite teammates',
            description: 'They get an email with a link.',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(Modal)),
        isSemantics(
          label: 'Invite teammates',
          hint: 'They get an email with a link.',
          namesRoute: true,
          scopesRoute: true,
          role: SemanticsRole.dialog,
        ),
      );
      expect(
        find.bySemanticsLabel('They get an email with a link.'),
        findsNothing,
        reason: 'read once, as the hint',
      );
      handle.dispose();
    });
  });

  group('onDismiss', () {
    testWidgets('shows the close button exactly when set', (tester) async {
      await tester.pumpWidget(_inline(const Modal(title: 'Title')));
      expect(find.byType(IconAction), findsNothing);

      var dismissed = 0;
      await tester.pumpWidget(
        _inline(Modal(title: 'Title', onDismiss: () => dismissed++)),
      );
      expect(find.byType(IconAction), findsOneWidget);
      await tester.tap(find.byType(IconAction));
      expect(dismissed, 1);

      // Without a title too.
      await tester.pumpWidget(
        _inline(Modal(message: 'Body', onDismiss: () {})),
      );
      expect(find.byType(IconAction), findsOneWidget);
    });

    testWidgets('the close glyph lines up with the content, 24px in', (
      tester,
    ) async {
      await tester.pumpWidget(
        _inline(Modal(title: 'Title', message: 'Body', onDismiss: () {})),
      );
      final card = tester.getRect(find.byType(Modal));
      final glyph = tester.getRect(
        find.descendant(
          of: find.byType(IconAction),
          matching: find.byType(Icon),
        ),
      );
      final title = tester.getRect(find.text('Title'));
      expect(card.right - glyph.right, 24);
      expect(glyph.center.dy, closeTo(title.center.dy, 0.5));
    });

    testWidgets('a leave guard around a hosted form holds the dialog', (
      tester,
    ) async {
      final form = ValueFormController<String>(
        read: (scope) => scope.text('name').value,
        write: (scope, value) => scope.text('name').set(value),
        initial: '',
      );
      addTearDown(form.dispose);
      await _open(
        tester,
        (context) => UnsavedChangesGuard(
          controller: form,
          child: ValueForm(
            controller: form,
            child: Modal(
              title: 'New contact',
              onDismiss: () => Navigator.of(context).maybePop(),
              body: Field(form.scope.text('name'), label: 'Name'),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.pump();
      expect(form.blocksNavigation, isTrue);

      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('New contact'), findsOneWidget);

      // Keeping the edits keeps the dialog.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New contact'), findsOneWidget);

      // Discarding them closes it.
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('New contact'), findsNothing);
    });
  });
}
