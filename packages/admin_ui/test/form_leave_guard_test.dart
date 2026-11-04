import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  FormStatus _status = FormStatus.clean;

  @override
  FormStatus get status => _status;
  set status(FormStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

void main() {
  /// The calls the registry made to the browser's prompt.
  late List<bool> unload;
  late LeaveGuardRegistry registry;

  setUp(() {
    unload = [];
    registry = LeaveGuardRegistry.withUnloadGuard(unload.add);
  });

  /// Mounts [forms] as guarded editors under [registry], with a button that
  /// asks to leave, and returns that button's context.
  Future<BuildContext> pumpGuards(
    WidgetTester tester,
    List<_Form> forms, {
    bool enabled = true,
    Widget Function(Widget child)? wrap,
  }) async {
    late BuildContext asker;
    Widget page = Column(
      children: [
        for (final form in forms)
          UnsavedChangesGuard(
            controller: form,
            enabled: enabled,
            child: const SizedBox(height: 20),
          ),
        Builder(
          builder: (context) {
            asker = context;
            return const Text('page');
          },
        ),
      ],
    );
    page = wrap?.call(page) ?? page;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaveGuardScope(registry: registry, child: page),
        ),
      ),
    );
    return asker;
  }

  testWidgets('with nothing to lose, leaving is confirmed at once', (
    tester,
  ) async {
    final context = await pumpGuards(tester, []);
    expect(await LeaveGuardScope.confirmLeave(context), isTrue);
    expect(find.text('Discard changes?'), findsNothing);

    // No scope at all: nothing guards the page.
    late BuildContext bare;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            bare = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(LeaveGuardScope.maybeOf(bare), isNull);
    expect(await LeaveGuardScope.confirmLeave(bare), isTrue);
  });

  testWidgets('a clean guard lets the page go without a prompt', (
    tester,
  ) async {
    final form = _Form();
    addTearDown(form.dispose);
    final context = await pumpGuards(tester, [form]);
    expect(registry.blocks, isFalse);
    expect(await LeaveGuardScope.confirmLeave(context), isTrue);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('two dirty guards ask once, and a second ask shares the '
      'prompt', (tester) async {
    final a = _Form(), b = _Form();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final context = await pumpGuards(tester, [a, b]);
    a.status = FormStatus.dirty;
    b.status = FormStatus.dirty;

    final first = LeaveGuardScope.confirmLeave(context);
    final second = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(identical(first, second), isTrue);
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('cancel answers false, discard true, and each ask is its own '
      'prompt', (tester) async {
    final form = _Form();
    addTearDown(form.dispose);
    final context = await pumpGuards(tester, [form]);
    form.status = FormStatus.dirty;

    final cancelled = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await cancelled, isFalse);
    expect(find.text('Discard changes?'), findsNothing);

    final confirmed = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(identical(cancelled, confirmed), isFalse);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await confirmed, isTrue);
  });

  testWidgets('mid-save the prompt says a save is in flight', (tester) async {
    final form = _Form();
    addTearDown(form.dispose);
    final context = await pumpGuards(tester, [form]);
    form.status = FormStatus.submitting;
    expect(registry.blocks, isTrue);

    final leave = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(find.text('Saving in progress — leave anyway?'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(await leave, isTrue);
  });

  testWidgets('the guard’s own texts word the prompt', (tester) async {
    final form = _Form()..status = FormStatus.dirty;
    addTearDown(form.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaveGuardScope(
            registry: registry,
            child: UnsavedChangesGuard(
              controller: form,
              title: 'Drop the draft?',
              confirmLabel: 'Drop',
              child: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
    final leave = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(find.text('Drop the draft?'), findsOneWidget);
    await tester.tap(find.text('Drop'));
    await tester.pumpAndSettle();
    expect(await leave, isTrue);
  });

  testWidgets('a disabled guard does not register', (tester) async {
    final form = _Form()..status = FormStatus.dirty;
    addTearDown(form.dispose);
    final context = await pumpGuards(tester, [form], enabled: false);
    expect(registry.blocks, isFalse);
    expect(unload, isEmpty);
    expect(await LeaveGuardScope.confirmLeave(context), isTrue);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('the browser’s prompt is on while a guard blocks', (
    tester,
  ) async {
    final form = _Form();
    addTearDown(form.dispose);
    await pumpGuards(tester, [form]);
    expect(unload, isEmpty);

    form.status = FormStatus.dirty;
    expect(unload, [true]);
    form.status = FormStatus.error;
    expect(unload, [true], reason: 'still blocking: no second call');
    form.status = FormStatus.submitted;
    expect(unload, [true, false]);

    form.status = FormStatus.dirty;
    expect(unload, [true, false, true]);
    // The guard goes with its page.
    await tester.pumpWidget(const SizedBox());
    expect(unload, [true, false, true, false]);
    expect(registry.blocks, isFalse);
  });

  testWidgets('a guard mounted dirty turns the prompt on, and enabling '
      'or disabling it registers or withdraws it', (tester) async {
    final form = _Form()..status = FormStatus.dirty;
    addTearDown(form.dispose);
    await pumpGuards(tester, [form]);
    expect(unload, [true]);
    await tester.pump();

    await pumpGuards(tester, [form], enabled: false);
    expect(unload, [true, false]);
    await pumpGuards(tester, [form]);
    expect(unload, [true, false, true]);
  });

  testWidgets('disposing the registry turns its prompt off', (tester) async {
    final form = _Form()..status = FormStatus.dirty;
    addTearDown(form.dispose);
    await pumpGuards(tester, [form]);
    await tester.pumpWidget(const SizedBox());
    unload.clear();

    final other = LeaveGuardRegistry.withUnloadGuard(unload.add);
    final unregister = other.register(
      LeaveGuardEntry(
        blocks: () => form.blocksNavigation,
        confirm: (_) async => true,
        listenable: form,
      ),
    );
    expect(unload, [true]);
    other.dispose();
    expect(unload, [true, false]);
    // The guard's own removal comes after, and is a no-op.
    unregister();
    form.status = FormStatus.clean;
    expect(unload, [true, false]);
  });

  testWidgets('an open portal modal does not stand the registry down', (
    tester,
  ) async {
    final form = _Form();
    addTearDown(form.dispose);
    final modals = ModalAnchorController();
    final context = await pumpGuards(tester, [
      form,
    ], wrap: (child) => ModalAnchor(controller: modals, child: child));
    form.status = FormStatus.dirty;
    modals.show<void>(builder: (_) => const Text('sheet'));
    await tester.pumpAndSettle();
    expect(registry.blocks, isTrue);

    // A palette command runs while its modal is still closing.
    modals.close();
    final leave = LeaveGuardScope.confirmLeave(context);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await leave, isFalse);
  });

  group('AdminScope', () {
    testWidgets('mounts a registry of its own', (tester) async {
      final form = _Form()..status = FormStatus.dirty;
      addTearDown(form.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: AdminScope(
            child: UnsavedChangesGuard(
              controller: form,
              child: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      final own = LeaveGuardScope.maybeOf(context);
      expect(own, isNotNull);
      expect(own!.blocks, isTrue);
    });

    testWidgets('uses the registry of a scope above, or the one it is '
        'given', (tester) async {
      late BuildContext context;
      Widget app(LeaveGuardRegistry? given) => MaterialApp(
        home: LeaveGuardScope(
          registry: registry,
          child: AdminScope(
            leaveGuards: given,
            child: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(null));
      expect(LeaveGuardScope.maybeOf(context), same(registry));

      final given = LeaveGuardRegistry.withUnloadGuard((_) {});
      addTearDown(given.dispose);
      await tester.pumpWidget(app(given));
      expect(LeaveGuardScope.maybeOf(context), same(given));
    });

    testWidgets('keeps the page’s state as its registry changes', (
      tester,
    ) async {
      var mounts = 0;
      Widget app(LeaveGuardRegistry? given) => MaterialApp(
        home: AdminScope(leaveGuards: given, child: _Mounts(() => mounts++)),
      );
      await tester.pumpWidget(app(null));
      final given = LeaveGuardRegistry.withUnloadGuard((_) {});
      addTearDown(given.dispose);
      await tester.pumpWidget(app(given));
      await tester.pumpWidget(app(null));
      expect(mounts, 1);
    });
  });
}

/// Calls [onMount] as its state is created.
class _Mounts extends StatefulWidget {
  final VoidCallback onMount;

  const _Mounts(this.onMount);

  @override
  State<_Mounts> createState() => _MountsState();
}

class _MountsState extends State<_Mounts> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
