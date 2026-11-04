import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a focusable Tappable around a Button reports the doubled '
      'Tab stop, naming focusable: false', (tester) async {
    await tester.pumpWidget(
      _host(
        Tappable(
          onTap: () {},
          child: Button('Save', onPressed: () {}),
        ),
      ),
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    final message = '$error';
    expect(message, contains('A Tappable wraps a Tab stop of its own'));
    expect(message, contains('focusable: false'));
  });

  testWidgets('focusable: false keeps it silent', (tester) async {
    await tester.pumpWidget(
      _host(
        Tappable(
          onTap: () {},
          focusable: false,
          child: Button('Save', onPressed: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('so does a Tappable that takes no focus, or a roving one', (
    tester,
  ) async {
    final roving = FocusNode(skipTraversal: true);
    addTearDown(roving.dispose);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            Tappable(onTap: null, child: Button('Save', onPressed: () {})),
            Tappable(
              onTap: () {},
              focusNode: roving,
              child: Button('Open', onPressed: () {}),
            ),
            Tappable(onTap: () {}, child: const Text('Plain')),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Tappable that becomes focusable is checked then', (
    tester,
  ) async {
    Widget target(VoidCallback? onTap) => _host(
      Tappable(
        onTap: onTap,
        child: Button('Save', onPressed: () {}),
      ),
    );
    await tester.pumpWidget(target(null));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(target(() {}));
    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('a small control of its own inside the target is a separate '
      'stop, and is left alone', (tester) async {
    await tester.pumpWidget(
      _host(
        Tappable(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 120, height: 32, child: Text('Chip')),
              IconAction(Icons.close, label: 'Remove', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [2.0, 0.5]) {
    testWidgets('the check measures the same under a ${scale}x scale', (
      tester,
    ) async {
      Widget target(Widget inner) => _host(
        Transform.scale(
          scale: scale,
          child: Tappable(
            onTap: () {},
            child: SizedBox(width: 200, height: 100, child: inner),
          ),
        ),
      );
      // A focusable on an eighth of the target is a stop of its own.
      await tester.pumpWidget(
        target(
          const Align(
            alignment: Alignment.topLeft,
            child: Focus(child: SizedBox(width: 100, height: 25)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(target(const Focus(child: SizedBox.expand())));
      expect(tester.takeException(), isA<FlutterError>());
    });
  }

  testWidgets('a focusable inside a skipped subtree is no Tab stop', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Tappable(
          onTap: () {},
          child: ExcludeFocus(child: Button('Save', onPressed: () {})),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
