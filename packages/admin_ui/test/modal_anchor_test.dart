import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Count extends InheritedWidget {
  final int n;
  const _Count(this.n, {required super.child});

  static int of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_Count>()!.n;

  @override
  bool updateShouldNotify(_Count old) => n != old.n;
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final controller = ModalAnchorController();
  final triggerFocus = FocusNode();
  final pickFocus = FocusNode(debugLabel: 'pick');
  final otherFocus = FocusNode(debugLabel: 'other');
  int n = 0;
  Future<String?>? result;

  void bump() => setState(() => n++);

  void _open() {
    result = controller.show<String>(
      builder: (context) => Material(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('modal n=${_Count.of(context)}'),
            TextButton(
              focusNode: pickFocus,
              onPressed: () => controller.close('picked'),
              child: const Text('pick'),
            ),
            TextButton(
              focusNode: otherFocus,
              onPressed: () {},
              child: const Text('other'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    triggerFocus.dispose();
    pickFocus.dispose();
    otherFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _Count(
          n,
          child: ModalAnchor(
            controller: controller,
            child: Center(
              child: Column(
                children: [
                  TextButton(
                    focusNode: triggerFocus,
                    onPressed: _open,
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<_HostState> _open(WidgetTester tester) async {
  await tester.pumpWidget(const _Host());
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('call-site InheritedWidget propagates into the open modal, live', (
    tester,
  ) async {
    final host = await _open(tester);
    expect(find.text('modal n=0'), findsOneWidget);

    // Mutate call-site state while the modal is open (as a refetch/socket push
    // would) — a route-pushed dialog would never see this.
    host.bump();
    await tester.pump();

    expect(find.text('modal n=1'), findsOneWidget);
  });

  testWidgets('close(result) resolves the show future', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    expect(await host.result, 'picked');
    expect(find.text('modal n=0'), findsNothing);
    expect(host.controller.isOpen, isFalse);
  });

  testWidgets('a modal shown while one closes opens once it has gone', (
    tester,
  ) async {
    final host = await _open(tester);

    host.controller.close('first');
    final next = host.controller.show<String>(
      builder: (context) => const Material(child: Text('next')),
    );
    await tester.pump();
    expect(find.text('next'), findsNothing, reason: 'the first is leaving');
    await tester.pumpAndSettle();

    expect(await host.result, 'first');
    expect(find.text('modal n=0'), findsNothing);
    expect(find.text('next'), findsOneWidget);
    expect(host.controller.isOpen, isTrue);
    host.controller.close('second');
    await tester.pumpAndSettle();
    expect(await next, 'second');
  });

  testWidgets('tapping the barrier dismisses with null', (tester) async {
    final host = await _open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await host.result, isNull);
    expect(find.text('modal n=0'), findsNothing);
  });

  testWidgets('Escape dismisses with null', (tester) async {
    final host = await _open(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(await host.result, isNull);
    expect(find.text('modal n=0'), findsNothing);
  });

  testWidgets('unmounting the anchor resolves the future with null', (
    tester,
  ) async {
    final host = await _open(tester);

    await tester.pumpWidget(const SizedBox());

    expect(await host.result, isNull);
  });

  testWidgets('back (maybePop) closes the modal, not the page', (tester) async {
    final host = await _open(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    final handled = await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(await host.result, isNull);
    expect(find.text('modal n=0'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('programmatic close releases the back interception', (
    tester,
  ) async {
    await _open(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    // The local history entry is gone: back reaches the (root) page route.
    expect(await navigator.maybePop(), isFalse);
  });

  testWidgets('Tab traversal stays trapped inside the modal', (tester) async {
    final host = await _open(tester);

    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(host.triggerFocus.hasFocus, isFalse);
      expect(
        host.pickFocus.hasPrimaryFocus || host.otherFocus.hasPrimaryFocus,
        isTrue,
        reason: 'tab #${i + 1} left the modal',
      );
    }
  });

  testWidgets('nested anchors: Escape and back close the innermost modal '
      'first', (tester) async {
    final outer = ModalAnchorController();
    final inner = ModalAnchorController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalAnchor(
            controller: outer,
            child: Center(
              child: TextButton(
                onPressed: () => outer.show<void>(
                  // The outer modal hosts its own anchor, like the asset
                  // editor does for the picker.
                  builder: (_) => ModalAnchor(
                    controller: inner,
                    child: Material(
                      child: TextButton(
                        onPressed: () => inner.show<void>(
                          builder: (_) => const Material(child: Text('inner')),
                        ),
                        child: const Text('open inner'),
                      ),
                    ),
                  ),
                ),
                child: const Text('open outer'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open outer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open inner'));
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsOneWidget);

    // Escape reaches the innermost modal's shortcut, not the outer's.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsNothing);
    expect(find.text('open inner'), findsOneWidget);

    // Back pops local history LIFO: reopen inner, maybePop closes it only.
    await tester.tap(find.text('open inner'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsNothing);
    expect(find.text('open inner'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('open inner'), findsNothing);
    expect(find.text('open outer'), findsOneWidget);
  });

  testWidgets('openCountOn tracks show/close and anchor unmount', (
    tester,
  ) async {
    final host = await _open(tester);
    final count = ModalAnchor.openCountOn(
      ModalRoute.of(tester.element(find.text('open')))!,
    );
    expect(count.value, 1);

    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    expect(count.value, 0);

    host.controller.show<void>(builder: (_) => const Text('again'));
    await tester.pumpAndSettle();
    expect(count.value, 1);

    await tester.pumpWidget(const SizedBox());
    expect(count.value, 0);
  });

  testWidgets('openCountOn counts only the modals on that route', (
    tester,
  ) async {
    final host = await _open(tester);
    final home = ModalRoute.of(tester.element(find.text('open')))!;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    host.controller.close();
    await tester.pumpAndSettle();

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ModalAnchor(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ModalAnchor.of(context)
                      .show<void>(builder: (_) => const Text('sheet')),
              child: const Text('open on page'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final page = ModalRoute.of(tester.element(find.text('open on page')))!;

    await tester.tap(find.text('open on page'));
    await tester.pumpAndSettle();
    expect(ModalAnchor.openCountOn(page).value, 1);
    expect(ModalAnchor.openCountOn(home).value, 0);

    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(ModalAnchor.openCountOn(page).value, 0);
  });

  testWidgets('focus returns to the previously focused node on close', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    final host = tester.state<_HostState>(find.byType(_Host));
    host.triggerFocus.requestFocus();
    await tester.pump();
    expect(host.triggerFocus.hasPrimaryFocus, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(host.triggerFocus.hasPrimaryFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(host.triggerFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('assistive technology reaches the open modal, not the page '
      'under it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());
    expect(find.semantics.byLabel('open'), findsOne);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('pick'), findsOne);
    expect(find.semantics.byLabel('open'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('pick'), findsNothing);
    expect(find.semantics.byLabel('open'), findsOne);
    semantics.dispose();
  });

  testWidgets('Escape still closes once focus falls back to the modal scope', (
    tester,
  ) async {
    final host = await _open(tester);
    host.pickFocus.requestFocus();
    await tester.pump();
    host.pickFocus.unfocus(disposition: UnfocusDisposition.scope);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(host.controller.isOpen, isFalse);
    expect(await host.result, isNull);
  });

  testWidgets('under reduced motion the modal opens and closes at once', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('open'));
    await tester.pump();
    final scrim = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(ModalBarrier),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(scrim.opacity.value, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('modal n=0'), findsNothing);
  });
}
