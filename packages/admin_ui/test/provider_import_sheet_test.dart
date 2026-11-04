import 'package:admin_ui/src/assets/external_provider.dart';
import 'package:admin_ui/src/assets/ui/provider_import_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _sizes = [
  ProviderSize(id: 's', label: 'Small', width: 500, height: 333, format: 'jpg'),
  ProviderSize(id: 'l', label: 'Large', width: 4000, height: 2667),
];

Future<String?> _open(
  WidgetTester tester, {
  required ProviderItem item,
  bool choosesSize = true,
  List<ProviderSize> sizes = _sizes,
  Future<String> Function(ProviderSize?)? onImport,
}) async {
  String? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showProviderImport(
                  context,
                  item: item,
                  providerLabel: 'Stockly',
                  choosesSize: choosesSize,
                  loadSizes: () async => sizes,
                  onImport: onImport ?? (s) async => '4242',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('shows size rows and the license note', (tester) async {
    await _open(
      tester,
      item: const ProviderItem(id: 'a', title: 'x'),
    );
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
    expect(find.textContaining('uses 1 download'), findsOneWidget);
  });

  testWidgets('confirm runs import and resolves the new asset id', (
    tester,
  ) async {
    ProviderSize? importedAt;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showProviderImport(
                  context,
                  item: const ProviderItem(id: 'a', title: 'x'),
                  providerLabel: 'Stockly',
                  choosesSize: true,
                  loadSizes: () async => _sizes,
                  onImport: (s) async {
                    importedAt = s;
                    return '4242';
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('License & add'));
    await tester.pumpAndSettle();

    // Defaulted to the first size and imported at it; sheet has popped.
    expect(importedAt?.id, 's');
    expect(find.text('License & add'), findsNothing);
  });

  testWidgets('no size chooser when the provider auto-sizes', (tester) async {
    await _open(
      tester,
      item: const ProviderItem(id: 'a', title: 'x'),
      choosesSize: false,
    );
    expect(find.text('Small'), findsNothing);
    expect(find.text('License & add'), findsOneWidget);
  });
}
