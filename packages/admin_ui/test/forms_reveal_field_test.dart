import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Product(FormScope _s) {
  ValueCell<String> text(int i) => _s.text('field$i');
  ValueCell<String> get sku => _s.text('sku');
}

const _fields = 8;

ValueFormController<String> productForm({
  String sku = '',
  Future<void> Function(String)? onSubmit,
}) => ValueFormController<String>(
  read: (s) => Product(s).sku.value,
  write: (s, v) {
    final f = Product(s);
    for (var i = 0; i < _fields; i++) {
      f.text(i).set('Value $i');
    }
    f.sku.set(v);
  },
  initial: sku,
  rules: (s) => [
    FieldRules(Product(s).sku, validators: [Validators.required()]),
  ],
  requireChanges: false,
  onSubmit: onSubmit ?? (_) async {},
);

/// A page whose last field, the SKU, sits under the fold, over a save bar
/// docked at the bottom.
Future<void> pumpPage(
  WidgetTester tester,
  ValueFormController<String> form, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(900, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final f = Product(form.scope);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        body: ValueForm(
          controller: form,
          child: PageScaffold(
            title: 'Product',
            bottomBar: FormSaveBar(
              controller: form,
              placement: SaveBarPlacement.bottom,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _fields; i++)
                  Field(f.text(i), label: 'Field $i'),
                Field(f.sku, label: 'SKU'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get skuShell =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == 'SKU');

Finder get saveBar => find.byType(SaveBar);

Finder messageOf(String text) =>
    find.descendant(of: skuShell, matching: find.text(text));

/// The part of the page the scroll view shows.
Rect viewportOf(WidgetTester tester) => tester.getRect(
  find.ancestor(of: skuShell, matching: find.byType(Scrollable)).first,
);

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.descendant(of: saveBar, matching: find.text('Save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a refused save shows the whole field, its message a gutter '
      'above the save bar', (tester) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form);
    expect(
      tester.getRect(skuShell).top,
      greaterThan(viewportOf(tester).bottom),
    );

    await save(tester);

    final message = tester.getRect(messageOf('Required'));
    final bar = tester.getRect(saveBar);
    final view = viewportOf(tester);
    expect(view.bottom, lessThanOrEqualTo(bar.top));
    expect(message.bottom, lessThanOrEqualTo(bar.top - AdminSpacing.lg));
    expect(
      tester.getRect(skuShell).bottom,
      moreOrLessEquals(view.bottom - AdminSpacing.lg, epsilon: 0.5),
      reason: 'it scrolls no further than it needs',
    );
    expect(tester.getRect(skuShell).top, greaterThan(view.top));
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(of: skuShell, matching: find.byWidget(focused.widget)),
      findsOneWidget,
      reason: 'the field is focused',
    );
  });

  testWidgets("a server's message shows above the save bar too", (
    tester,
  ) async {
    final form = productForm(
      sku: 'PS-0100',
      onSubmit: (_) async => throw const FormSubmitException(
        fieldErrors: {'sku': 'Another product already uses this SKU'},
      ),
    );
    addTearDown(form.dispose);
    await pumpPage(tester, form);

    await save(tester);

    final message = tester.getRect(
      messageOf('Another product already uses this SKU'),
    );
    expect(
      message.bottom,
      lessThanOrEqualTo(tester.getRect(saveBar).top - AdminSpacing.lg),
    );
  });

  testWidgets('under reduced motion it lands at once', (tester) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form, reduceMotion: true);

    await save(tester);

    expect(
      tester.getRect(messageOf('Required')).bottom,
      lessThanOrEqualTo(tester.getRect(saveBar).top - AdminSpacing.lg),
    );
  });

  testWidgets('focusing alone scrolls only the caret in: the message stays '
      'under the fold', (tester) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form);
    await form.submit();
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    scrollableOf(tester).position.jumpTo(0);
    await tester.pumpAndSettle();

    entryOf(tester, 'sku').focus();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(messageOf('Required')).bottom,
      greaterThan(viewportOf(tester).bottom - AdminSpacing.lg),
      reason: 'what reveal() fixes',
    );
  });

  testWidgets('on a touch platform, no selection handle covers the message '
      'of a field revealed with text in it', (tester) async {
    final form = productForm(
      sku: 'PS-0100',
      onSubmit: (_) async => throw const FormSubmitException(
        fieldErrors: {'sku': 'Another product already uses this SKU'},
      ),
    );
    addTearDown(form.dispose);
    await pumpPage(tester, form);

    await save(tester);

    final editable = tester.state<EditableTextState>(
      find.descendant(of: skuShell, matching: find.byType(EditableText)),
    );
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(editable.selectionOverlay?.handlesAreVisible ?? false, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a reveal the user scrolls away from leaves the view where '
      'they took it', (tester) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form);
    final position = scrollableOf(tester).position;

    entryOf(tester, 'sku').reveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(position.isScrollingNotifier.value, isTrue);
    await tester.dragFrom(viewportOf(tester).center, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(position.pixels, 0, reason: 'dragged back to the top');
  });

  testWidgets('a finger put down on the view stops the reveal where it is', (
    tester,
  ) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form);
    final position = scrollableOf(tester).position;

    entryOf(tester, 'sku').reveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final finger = await tester.startGesture(viewportOf(tester).center);
    await tester.pump();
    final held = position.pixels;
    await tester.pump(const Duration(milliseconds: 500));
    await finger.up();
    await tester.pumpAndSettle();

    expect(position.pixels, held);
  });

  testWidgets('a field cut at the top edge shows its label', (tester) async {
    final form = productForm();
    addTearDown(form.dispose);
    await pumpPage(tester, form);
    final field = find.byWidgetPredicate(
      (w) => w is FieldShell && w.label == 'Field 2',
    );
    final position = scrollableOf(tester).position;
    position.jumpTo(
      position.pixels +
          tester.getRect(field).top -
          viewportOf(tester).top +
          AdminSpacing.xl,
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(field).top, lessThan(viewportOf(tester).top));

    entryOf(tester, 'field2').reveal();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(field).top,
      greaterThanOrEqualTo(viewportOf(tester).top + AdminSpacing.lg - 0.5),
    );
  });
}

ScrollableState scrollableOf(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find.ancestor(of: skuShell, matching: find.byType(Scrollable)).first,
    );

FormFieldEntry entryOf(WidgetTester tester, String id) =>
    FormFieldScope.maybeOf(tester.element(skuShell))!.entries
        .firstWhere((e) => e.id == id);
