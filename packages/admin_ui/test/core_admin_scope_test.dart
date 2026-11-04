import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = AdminTokens.from(palette: irisDarkPalette);

/// A child that hands out its context.
Widget _probe(void Function(BuildContext) grab, [Widget? child]) => Builder(
  builder: (context) {
    grab(context);
    return child ?? const SizedBox();
  },
);

void main() {
  testWidgets('every scope it mounts is reachable below it', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(child: _probe((c) => context = c)),
      ),
    );
    expect(ToastScope.of(context), isA<ToastScopeState>());
    expect(CommandScope.of(context), isA<CommandRegistry>());
    expect(ModalAnchor.of(context), isA<ModalAnchorController>());

    ToastScope.of(context).show(const Toast('Saved'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);

    final modal = ModalAnchor.of(context)
        .show<void>(builder: (_) => const Text('In the modal'));
    await tester.pumpAndSettle();
    expect(find.text('In the modal'), findsOneWidget);
    ModalAnchor.of(context).close();
    await tester.pumpAndSettle();
    await modal;
    expect(find.text('In the modal'), findsNothing);
  });

  testWidgets('a modal sees the command registry', (tester) async {
    final commands = CommandRegistry();
    addTearDown(commands.dispose);
    final modals = ModalAnchorController();
    CommandRegistry? seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(
          commands: commands,
          modals: modals,
          child: const SizedBox(),
        ),
      ),
    );
    modals.show<void>(
      builder: (context) => _probe((c) => seen = CommandScope.maybeOf(c)),
    );
    await tester.pumpAndSettle();
    expect(seen, same(commands));
    modals.close();
    await tester.pumpAndSettle();
  });

  testWidgets('reuses a ToastScope above it', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        builder: (context, child) => ToastScope(child: child!),
        home: AdminScope(child: _probe((c) => context = c)),
      ),
    );
    expect(find.byType(ToastScope), findsOneWidget);
    expect(
      ToastScope.of(context),
      same(tester.state<ToastScopeState>(find.byType(ToastScope))),
    );
  });

  testWidgets('leaves a given registry alone, and disposes its own', (
    tester,
  ) async {
    final given = CommandRegistry();
    addTearDown(given.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(commands: given, child: _probe((c) => context = c)),
      ),
    );
    expect(CommandScope.of(context), same(given));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(child: _probe((c) => context = c)),
      ),
    );
    final own = CommandScope.of(context);
    expect(own, isNot(same(given)));

    await tester.pumpWidget(const SizedBox());
    void listener() {}
    given
      ..addListener(listener)
      ..removeListener(listener);
    expect(() => own.addListener(listener), throwsFlutterError);
  });

  testWidgets('gives its own registry up for a given one', (tester) async {
    late BuildContext context;
    Widget app({CommandRegistry? commands}) => MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: AdminScope(commands: commands, child: _probe((c) => context = c)),
    );
    await tester.pumpWidget(app());
    final own = CommandScope.of(context);

    final given = CommandRegistry();
    addTearDown(given.dispose);
    await tester.pumpWidget(app(commands: given));
    expect(CommandScope.of(context), same(given));
    expect(() => own.addListener(() {}), throwsFlutterError);
  });

  group('the theme', () {
    testWidgets('is mounted only when given tokens', (tester) async {
      late BuildContext context;
      final theme = buildAppTheme(defaultTokens);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: AdminScope(child: _probe((c) => context = c)),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AdminScope),
          matching: find.byType(Theme),
        ),
        findsNothing,
      );
      expect(context.adminTokens, same(defaultTokens));

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: AdminScope(tokens: _tokens, child: _probe((c) => context = c)),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AdminScope),
          matching: find.byType(Theme),
        ),
        findsOneWidget,
      );
      expect(context.adminTokens, same(_tokens));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('is built once for equal tokens', (tester) async {
      late BuildContext context;
      Widget app(AdminTokens tokens) => MaterialApp(
        home: AdminScope(tokens: tokens, child: _probe((c) => context = c)),
      );
      await tester.pumpWidget(app(_tokens));
      final first = Theme.of(context);
      await tester.pumpWidget(app(_tokens.copyWith()));
      expect(Theme.of(context), same(first));
      await tester.pumpWidget(app(defaultTokens));
      expect(context.adminTokens, same(defaultTokens));
    });

    testWidgets('showConfirmDialog opens under a plain MaterialApp, in the '
        "scope's theme", (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: AdminScope(tokens: _tokens, child: _probe((c) => context = c)),
        ),
      );
      final answer = showConfirmDialog(
        context,
        title: 'Delete the page?',
        message: 'It cannot be undone.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete the page?'), findsOneWidget);
      final dialog = tester.element(find.text('Delete the page?'));
      expect(dialog.adminTokens, same(_tokens));

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
    });

    testWidgets('a pushed route is outside it, and takes a scope of its own', (
      tester,
    ) async {
      late BuildContext home;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: AdminScope(tokens: _tokens, child: _probe((c) => home = c)),
        ),
      );
      BuildContext? bare;
      unawaited(
        Navigator.of(home).push(
          MaterialPageRoute<void>(builder: (_) => _probe((c) => bare = c)),
        ),
      );
      await tester.pumpAndSettle();
      expect(bare!.adminTokens, same(defaultTokens));
      expect(CommandScope.maybeOf(bare!), isNull);

      BuildContext? scoped;
      unawaited(
        Navigator.of(home).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                AdminScope(tokens: _tokens, child: _probe((c) => scoped = c)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scoped!.adminTokens, same(_tokens));
      expect(CommandScope.maybeOf(scoped!), isNotNull);
      expect(ModalAnchor.of(scoped!), isA<ModalAnchorController>());
    });
  });
}
