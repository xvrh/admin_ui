import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A cell kind the kit does not know: neither a ValueCell nor a
/// TranslatedCell, just a Cell with its own shape.
class _RatingCell implements Cell<int> {
  _RatingCell(this.id, this.stars);

  @override
  final String id;
  int stars;
}

/// Renders the rating cells and leaves every other cell to the kit.
class _RatingBinder extends FieldBinder {
  const _RatingBinder();

  @override
  Widget? bind<V>(BuildContext context, Cell<V> cell, FieldBinding<V> binding) {
    if (cell is! _RatingCell) return null;
    final stars = (cell as _RatingCell).stars;
    return FieldShell(
      label: binding.label,
      fieldId: cell.id,
      required: binding.required,
      child: Text('${'★' * stars}${'☆' * (5 - stars)}'),
    );
  }
}

Widget _host(Widget child, {FieldBinder? binder}) => MaterialApp(
  theme: buildAppTheme(irisTheme.tokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: binder == null
          ? child
          : FieldBinderScope(binder: binder, child: child),
    ),
  ),
);

void main() {
  testWidgets('a cell kind of its own renders through its FieldBinder', (
    tester,
  ) async {
    final rating = _RatingCell('rating', 3);
    final scope = LocalScope();
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      _host(
        binder: const _RatingBinder(),
        Column(
          children: [
            NumberField(rating, label: 'Rating', required: true),
            // The kit still renders its own kinds under the same binder.
            NumberField(scope.number('count'), label: 'Count'),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('★★★☆☆'), findsOneWidget);
    final shell = tester.widget<FieldShell>(
      find.byWidgetPredicate((w) => w is FieldShell && w.label == 'Rating'),
    );
    expect(shell.fieldId, 'rating');
    expect(shell.required, isTrue);
    expect(find.byType(NumberBody), findsOneWidget);
  });

  testWidgets('a cell no binder renders fails naming its type and the fix', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(NumberField(_RatingCell('rating', 3), label: 'Rating')),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    final message = error.toString();
    expect(message, contains('_RatingCell'));
    expect(message, contains('"rating"'));
    expect(message, contains('ValueCell'));
    expect(message, contains('TranslatedCell'));
    expect(message, contains('FieldBinder'));
  });

  testWidgets('a binder that passes on the cell still gets the error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        binder: const _RatingBinder(),
        NumberField(_OtherCell('other'), label: 'Other'),
      ),
    );
    expect(tester.takeException(), isA<FlutterError>());
  });

  group('LocalScope record elements', () {
    test('hand out a string list, the same one on every read', () {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final list = scope.recordList('variants', build: (r) => r)
        ..add()
        ..add();

      final first = list.elements.first.list('tags');
      first.set(['linen', 'summer']);

      final again = list.elements.first.list('tags');
      expect(again, same(first));
      expect(again.value, ['linen', 'summer']);
      expect(again.id, 'variants/${list.elements.first.id}/tags');
      // Each element has its own.
      expect(list.elements.last.list('tags').value, isEmpty);
    });

    test('the list follows its element through a move and outlives a '
        'remove until the scope is disposed', () {
      final scope = LocalScope();
      final list = scope.recordList('variants', build: (r) => r)
        ..add()
        ..add();
      final tags = list.elements.last.list('tags')..set(['wool']);

      list.move(1, 0);
      expect(list.elements.first.list('tags'), same(tags));

      list.removeAt(0);
      expect(tags.value, ['wool']);
      scope.dispose();
    });

    testWidgets('a tags field inside a record list edits in a LocalScope', (
      tester,
    ) async {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final list = scope.recordList('variants', build: (r) => r)..add();
      await tester.pumpWidget(
        _host(
          RecordListField<RecordScope>(
            list,
            label: 'Variants',
            item: (r) => TagsField(r.list('tags'), label: 'Tags'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(TagsBody),
          matching: find.byType(EditableText),
        ),
        'linen',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(list.elements.single.list('tags').value, ['linen']);
    });

    testWidgets('removing a row before others shows and edits the rows that '
        'remain', (tester) async {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final list = scope.recordList('lines', build: (r) => r)
        ..add()
        ..add()
        ..add();
      final labels = ['Hosting', 'Support', 'Training'];
      for (final (i, e) in list.elements.indexed) {
        e.text('label').set(labels[i]);
      }
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: RecordListField<RecordScope>(
              list,
              label: 'Lines',
              item: (r) => Field(r.text('label'), label: 'Label'),
            ),
          ),
        ),
      );

      List<String> shown() => [
        for (final e in tester.widgetList<EditableText>(
          find.byType(EditableText),
        ))
          e.controller.text,
      ];
      expect(shown(), labels);

      list.removeAt(0);
      await tester.pump();
      expect(shown(), ['Support', 'Training']);

      await tester.enterText(find.byType(EditableText).first, 'Support+');
      expect(list.elements.first.text('label').value, 'Support+');
      expect(list.elements.last.text('label').value, 'Training');
    });
  });
}

class _OtherCell implements Cell<int> {
  _OtherCell(this.id);

  @override
  final String id;
}
