import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

enum _Size { small, large }

const _options = [
  SelectOption(value: 'a', label: 'Alpha'),
  SelectOption(value: 'b', label: 'Beta'),
  SelectOption(value: 'c', label: 'Gamma'),
];

/// Every bound preset over a seeded [LocalScope], noting each cell that
/// changes once [watch] is called.
class _Presets {
  final scope = LocalScope();
  final _cells = <String, Listenable>{};
  final edited = <String>{};

  ValueCell<T> _seed<T>(ValueCell<T> cell, T value) {
    cell.set(value);
    _cells[cell.id] = cell;
    return cell;
  }

  void watch() {
    for (final MapEntry(:key, :value) in _cells.entries) {
      value.addListener(() => edited.add(key));
    }
  }

  List<Widget> build() {
    final s = scope;
    final records = s.recordList('rows', build: (r) => r)
      ..add()
      ..add();
    _cells['rows'] = records;
    return [
      Field(_seed(s.text('text'), 'Hello'), label: 'Text'),
      OptionalField(
        _seed(s.textOrNull('optional'), 'Maybe'),
        label: 'Optional',
        maxLength: 20,
      ),
      NumberField(_seed(s.number('number'), 4), label: 'Number'),
      OptionalNumberField(_seed(s.numberOrNull('n?'), 2), label: 'Number?'),
      DecimalField(_seed(s.decimal('decimal'), 1.5), label: 'Decimal'),
      BooleanField(_seed(s.boolean('bool'), true), label: 'Bool'),
      OptionalBooleanField(_seed(s.booleanOrNull('b?'), true), label: 'B?'),
      DateField(_seed(s.date('date'), DateTime(2026, 3, 4)), label: 'Date'),
      OptionalDateField(
        _seed(s.dateOrNull('d?'), DateTime(2026, 3, 4)),
        label: 'Date?',
      ),
      SelectField(
        _seed(s.text('select'), 'a'),
        label: 'Select',
        options: _options,
      ),
      EnumSelectField<_Size>(
        _seed(
          s.enumCell<_Size>(
            'size',
            encode: (e) => e.name,
            decode: _Size.values.byName,
            fallback: _Size.small,
          ),
          _Size.small,
        ),
        label: 'Size',
        values: _Size.values,
        labelOf: (e) => e.name,
      ),
      TagsField(_seed(s.list('tags'), ['one', 'two']), label: 'Tags'),
      KeyValueField(_kv(), label: 'Pairs'),
      MaskedField(
        _seed(s.text('masked'), '1234'),
        label: 'Masked',
        mask: '## ##',
      ),
      ColorField(_seed(s.text('color'), '#112233'), label: 'Color'),
      MultiSelectField(
        _seed(s.list('multi'), ['a', 'b']),
        label: 'Multi',
        options: _options,
      ),
      ReferenceField<int, int>(
        _seed(s.relation('refs'), [1, 2]),
        label: 'Refs',
        idOf: (v) => v,
        resolve: (ids) async => ids.toList(),
        search: (q, {cursor}) async => const ReferencePage([1, 2, 3]),
        tile: (context, v) => Text('Ref $v'),
      ),
      RecordListField<RecordScope>(
        records,
        label: 'Rows',
        item: (r) => Field(r.text('label'), label: 'Label'),
      ),
    ];
  }

  ValueCell<Map<String, String>> _kv() =>
      _seed(_KeyValueCell('kv', const {}), const {'a': '1', 'b': '2'});
}

class _KeyValueCell extends ValueNotifier<Map<String, String>>
    implements ValueCell<Map<String, String>> {
  _KeyValueCell(this.id, super.value);

  @override
  final String id;

  @override
  void set(Map<String, String> value) => this.value = value;
}

/// Performs every tap, increase and decrease any semantics node offers,
/// twice over (the first round opens menus, the second picks from them),
/// pressing a few editing keys on whatever has focus after each.
Future<void> _pokeEverything(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    final nodes = find.semantics
        .byAnyAction(const [
          SemanticsAction.tap,
          SemanticsAction.increase,
          SemanticsAction.decrease,
        ])
        .evaluate()
        .toList();
    for (final node in nodes) {
      if (node.owner == null) continue;
      final data = node.getSemanticsData();
      for (final action in const [
        SemanticsAction.tap,
        SemanticsAction.increase,
        SemanticsAction.decrease,
      ]) {
        if (!data.hasAction(action) || node.owner == null) continue;
        node.owner!.performAction(node.id, action);
        await tester.pump(const Duration(milliseconds: 50));
      }
      for (final key in const [
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.backspace,
      ]) {
        await tester.sendKeyEvent(key);
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  await tester.pumpAndSettle();
}

/// The cells a sweep over every preset edits.
Future<Set<String>> _sweep(
  WidgetTester tester, {
  required bool readOnly,
}) async {
  final presets = _Presets();
  addTearDown(presets.scope.dispose);
  final semantics = tester.ensureSemantics();
  // Tall enough that every field is built and on screen.
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fields = presets.build();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: FieldStateScope(
          readOnly: readOnly,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: fields),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  presets.watch();
  await _pokeEverything(tester);
  semantics.dispose();
  return presets.edited;
}

void main() {
  testWidgets('the sweep reaches the presets: editable, they change', (
    tester,
  ) async {
    final edited = await _sweep(tester, readOnly: false);
    expect(
      edited,
      containsAll(['text', 'optional', 'number', 'bool', 'tags', 'kv']),
    );
    expect(edited, containsAll(['masked', 'multi', 'refs', 'rows']));
  });

  testWidgets('under a read-only FieldStateScope no preset takes an edit', (
    tester,
  ) async {
    final changed = await _sweep(tester, readOnly: true);
    expect(find.byType(AddRowButton), findsNothing);
    expect(changed, isEmpty);
  });
}
