import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An empty library: enough for the fields to take drops and picks.
class _Source implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => const AssetBrowseResult([], 0);

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

typedef _Values = ({String? hero, bool show});

ValueFormController<_Values> _form() => ValueFormController<_Values>(
  read: (s) =>
      (hero: s.assetRef('hero').assetId.value, show: s.boolean('show').value),
  write: (s, v) {
    s.assetRef('hero').assetId.set(v.hero);
    s.boolean('show').set(v.show);
  },
  initial: (hero: null, show: true),
  mode: ValidationMode.always,
  rules: (s) {
    final hero = s.assetRef('hero');
    final show = s.boolean('show');
    return [
      FieldRules(
        hero.assetId,
        validators: [Validators.required()],
        id: hero.id,
        visibleWhen: () => show.value,
        dependsOn: [show],
      ),
    ];
  },
);

Future<void> _pump(
  WidgetTester tester,
  ValueFormController<_Values> controller, {
  bool readOnly = false,
}) async {
  final gallery = controller.scope.recordList('gallery', build: (r) => r);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: AssetSourceScope(
          source: _Source(),
          child: ModalAnchor(
            child: SingleChildScrollView(
              child: ValueForm(
                controller: controller,
                readOnly: readOnly,
                child: Column(
                  children: [
                    AssetRefField(
                      controller.scope.assetRef('hero'),
                      label: 'Hero image',
                    ),
                    AssetListField<RecordScope>(
                      gallery,
                      label: 'Gallery',
                      image: (r) => r.assetRef('image'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FieldShell _shell(WidgetTester tester, String label) => tester.widget(
  find.byWidgetPredicate((w) => w is FieldShell && w.label == label),
);

void main() {
  testWidgets('an asset ref follows the rules filed under its id', (
    tester,
  ) async {
    final controller = _form();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final hero = _shell(tester, 'Hero image');
    expect(hero.required, isTrue);
    expect(hero.errorText, 'Required');
    expect(find.text('Required'), findsOneWidget);
    expect(_shell(tester, 'Gallery').required, isFalse);

    controller.scope.boolean('show').set(false);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is FieldShell && w.label == 'Hero image'),
      findsNothing,
    );
    expect(controller.errors, isEmpty);
  });

  testWidgets('a gallery shows the server message filed under its id', (
    tester,
  ) async {
    final controller = _form();
    addTearDown(controller.dispose);
    controller.scope.assetRef('hero').assetId.set('hero-1');
    await _pump(tester, controller);

    controller.setErrors({'gallery': 'Add at least one image'});
    await tester.pumpAndSettle();
    expect(_shell(tester, 'Gallery').errorText, 'Add at least one image');
  });

  testWidgets('a read-only form takes no dropped file', (tester) async {
    Iterable<bool> dropsTaken() => tester
        .widgetList<AssetDropTarget>(find.byType(AssetDropTarget))
        .map((t) => t.enabled);

    final editable = _form();
    addTearDown(editable.dispose);
    await _pump(tester, editable);
    expect(dropsTaken(), [true, true]);

    final readOnly = _form();
    addTearDown(readOnly.dispose);
    await _pump(tester, readOnly, readOnly: true);
    expect(dropsTaken(), [false, false]);
  });
}
