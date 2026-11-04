import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/src/common/ui/modal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('confirm resolves true on confirm, false on cancel', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  result = await showConfirmDialog(
                    context,
                    title: 'Delete?',
                    message: 'Gone for good.',
                    confirmLabel: 'Delete',
                    danger: true,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Cancel path.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text('Delete?'), findsNothing);

    // Confirm path.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('async onConfirm runs in-dialog then resolves true', (
    tester,
  ) async {
    bool? result;
    var ran = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  result = await showConfirmDialog(
                    context,
                    title: 'Delete?',
                    message: 'Runs in-dialog.',
                    confirmLabel: 'Delete',
                    onConfirm: () async {
                      await Future<void>.delayed(
                        const Duration(milliseconds: 50),
                      );
                      ran = true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump(); // kick off the async action

    // Spinner shows while the action runs; dialog stays put.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Delete?'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(ran, isTrue);
    expect(result, isTrue);
    expect(find.text('Delete?'), findsNothing);
  });

  testWidgets('async onConfirm surfaces an error and stays open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showConfirmDialog(
                  context,
                  title: 'Delete?',
                  message: 'Runs in-dialog.',
                  confirmLabel: 'Delete',
                  onConfirm: () async => throw 'Boom (409).',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // The raw error never reaches the user; a generic retry prompt does.
    expect(find.textContaining('Boom'), findsNothing);
    expect(
      find.text(const AdminLocalizationsEn().somethingWentWrongTryAgain),
      findsOneWidget,
    );
    expect(find.text('Delete?'), findsOneWidget); // still open for retry
  });
}
