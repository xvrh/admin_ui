import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps a bare app and returns what [read] throws from inside it, or null.
Future<Object?> _errorOf(
  WidgetTester tester,
  void Function(BuildContext) read,
) async {
  Object? error;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          try {
            read(context);
          } catch (e) {
            error = e;
          }
          return const SizedBox();
        },
      ),
    ),
  );
  return error;
}

void main() {
  group('a required scope that is missing names the widget to add', () {
    final lookups = <String, void Function(BuildContext)>{
      'LangScope': LangScope.of,
      'ToastScope': ToastScope.of,
      'ModalAnchor': ModalAnchor.of,
      'CommandScope': CommandScope.of,
      'AssetSourceScope': AssetSourceScope.of,
    };
    for (final MapEntry(key: scope, value: read) in lookups.entries) {
      testWidgets('$scope.of', (tester) async {
        final error = await _errorOf(tester, read);
        expect(error, isA<FlutterError>());
        final message = (error! as FlutterError).message;
        expect(message, contains('$scope.of()'));
        expect(message.toLowerCase(), contains('mount'));
        expect(message, contains(scope));
      });
    }

    testWidgets('maybeOf still answers null', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      expect(LangScope.maybeOf(ctx), isNull);
      expect(CommandScope.maybeOf(ctx), isNull);
      expect(AssetSourceScope.maybeOf(ctx), isNull);
    });

    testWidgets('LangScope.of finds the nearest scope', (tester) async {
      LangScope? found;
      await tester.pumpWidget(
        LangScope(
          locales: const [],
          visibleLocales: const {'en'},
          sourceLocale: 'en',
          activeLocale: 'en',
          onVisibleLocalesChanged: (_) {},
          child: Builder(
            builder: (context) {
              found = LangScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found?.activeLocale, 'en');
    });
  });
}
