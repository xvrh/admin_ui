import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// One related record held as its id or null: the field shows the link
// button or that record's row, never both, and the row's Replace button
// opens the picker to choose another in its place.

class _Maker {
  final String id;
  final String name;
  const _Maker(this.id, this.name);
}

const _makers = [
  _Maker('m-1', 'Northwind'),
  _Maker('m-2', 'Harbour & Pine'),
  _Maker('m-3', 'Atelier Vento'),
];

const _replace = Icons.swap_horiz_rounded;
const _remove = Icons.close_rounded;
const _retry = Icons.refresh_rounded;

/// What the field under test was asked to resolve, a batch per call.
final _asked = <List<String>>[];

Future<List<_Maker>> _resolve(Iterable<String> ids) async {
  _asked.add(ids.toList());
  return [
    for (final m in _makers)
      if (ids.contains(m.id)) m,
  ];
}

Future<ReferencePage<_Maker>> _search(String query, {String? cursor}) async =>
    const ReferencePage(_makers);

Widget _tile(BuildContext context, _Maker m) => Text(m.name);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  bool atFoot = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: _kitLanguages.locales,
      localizationsDelegates: _kitLanguages.delegates,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: atFoot
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [child],
                    )
                  : child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _field(
  Cell<String?> cell, {
  _Maker? seed,
  bool readOnly = false,
  bool enabled = true,
  ReferenceResolver<_Maker, String> resolve = _resolve,
  ReferenceSearch<_Maker> search = _search,
}) => SingleReferenceField<_Maker, String>(
  cell,
  label: 'Maker',
  addLabel: 'Choose a maker',
  idOf: (m) => m.id,
  resolve: resolve,
  search: search,
  tile: _tile,
  seed: seed,
  readOnly: readOnly,
  enabled: enabled,
);

/// More results than a short window has room for.
Future<ReferencePage<_Maker>> _searchMany(
  String query, {
  String? cursor,
}) async =>
    ReferencePage([for (var i = 1; i <= 20; i++) _Maker('m-$i', 'Maker $i')]);

/// [matching] in the open picker.
Finder _inPicker(Finder matching) =>
    find.descendant(of: find.byType(PopoverMenuSurface), matching: matching);

FocusNode _focusOf(WidgetTester tester, Finder finder) =>
    Focus.of(tester.element(finder));

void main() {
  late LocalScope scope;
  late ValueCell<String?> cell;

  setUp(() {
    _asked.clear();
    scope = LocalScope();
    cell = scope.textOrNull('maker');
  });

  tearDown(() => scope.dispose());

  group('with no record', () {
    testWidgets('it shows the link button and no row', (tester) async {
      await _pump(tester, _field(cell));
      expect(find.text('Choose a maker'), findsOneWidget);
      expect(find.byIcon(_replace), findsNothing);
      expect(find.byIcon(_remove), findsNothing);
      expect(_asked, isEmpty);
    });

    testWidgets('a pick is the cell\'s id, and closes the picker', (
      tester,
    ) async {
      await _pump(tester, _field(cell));
      await tester.tap(find.text('Choose a maker'));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Harbour & Pine')));
      await tester.pumpAndSettle();

      expect(cell.value, 'm-2');
      expect(find.byType(PopoverMenuSurface), findsNothing);
      expect(find.text('Harbour & Pine'), findsOneWidget);
      // The record picked is the one shown: nothing is resolved again.
      expect(_asked, isEmpty);
    });

    testWidgets('at the foot of a short window the picker opens above the '
        'button, and scrolls there', (tester) async {
      tester.view
        ..physicalSize = const Size(640, 360)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, _field(cell, search: _searchMany), atFoot: true);
      await tester.tap(find.text('Choose a maker'));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.text('Choose a maker'));
      final picker = tester.getRect(find.byType(PopoverMenuSurface));
      expect(picker.bottom, lessThan(button.top));
      expect(picker.top, greaterThanOrEqualTo(0));
      expect(picker.height, lessThan(400));
    });

    testWidgets('read-only, it says there is none', (tester) async {
      await _pump(tester, _field(cell, readOnly: true));
      expect(find.text('No reference'), findsOneWidget);
      expect(find.text('Choose a maker'), findsNothing);
    });
  });

  group('with a record', () {
    setUp(() => cell.set('m-1'));

    testWidgets('it shows the row alone: nothing adds a second', (
      tester,
    ) async {
      await _pump(tester, _field(cell));
      expect(find.text('Northwind'), findsOneWidget);
      expect(find.text('Choose a maker'), findsNothing);
      expect(find.byIcon(_replace), findsOneWidget);
      expect(find.byIcon(_remove), findsOneWidget);
      expect(_asked, [
        ['m-1'],
      ]);
    });

    testWidgets('Replace opens the picker with the record marked', (
      tester,
    ) async {
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();

      expect(find.byType(PopoverMenuSurface), findsOneWidget);
      expect(_inPicker(find.text('Northwind')), findsOneWidget);
      expect(_inPicker(find.byIcon(Icons.check_circle_rounded)), findsOne);
      // The picker stands under the row, from its start, as the link
      // button's does.
      final row = tester.getRect(find.byType(FieldChrome).last);
      final picker = tester.getRect(find.byType(PopoverMenuSurface));
      expect(picker.left, row.left);
      expect(picker.top, greaterThan(row.bottom));
    });

    testWidgets('another pick takes its place', (tester) async {
      var changes = 0;
      cell.addListener(() => changes++);
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Atelier Vento')));
      await tester.pumpAndSettle();

      expect(cell.value, 'm-3');
      expect(changes, 1);
      expect(find.byType(PopoverMenuSurface), findsNothing);
      expect(find.text('Atelier Vento'), findsOneWidget);
      expect(find.text('Northwind'), findsNothing);
      expect(find.byIcon(_replace), findsOneWidget);
    });

    testWidgets('picking the same record closes and changes nothing', (
      tester,
    ) async {
      var changes = 0;
      cell.addListener(() => changes++);
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Northwind')));
      await tester.pumpAndSettle();

      expect(cell.value, 'm-1');
      expect(changes, 0);
      expect(find.byType(PopoverMenuSurface), findsNothing);
    });

    testWidgets('in a short window the picker scrolls beside the row', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(640, 360)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, _field(cell, search: _searchMany));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();

      // The row stays in view above the picker, which takes the room under
      // it and no more.
      final row = tester.getRect(find.byType(FieldChrome).last);
      final picker = tester.getRect(find.byType(PopoverMenuSurface));
      expect(picker.top, greaterThan(row.bottom));
      expect(picker.bottom, lessThanOrEqualTo(360));
      expect(picker.height, lessThan(400));
      expect(_inPicker(find.text('Maker 1')), findsOneWidget);
    });

    testWidgets('Replace pressed again closes the picker', (tester) async {
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      expect(find.byType(PopoverMenuSurface), findsOneWidget);
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      expect(find.byType(PopoverMenuSurface), findsNothing);
      expect(cell.value, 'm-1');
    });

    testWidgets('Remove sets the cell to null and brings the button back', (
      tester,
    ) async {
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_remove));
      await tester.pumpAndSettle();

      expect(cell.value, isNull);
      expect(find.text('Northwind'), findsNothing);
      expect(find.text('Choose a maker'), findsOneWidget);
      expect(find.byIcon(_replace), findsNothing);
    });

    testWidgets('a record the host holds shows without being resolved', (
      tester,
    ) async {
      await _pump(tester, _field(cell, seed: _makers[0]));
      expect(find.text('Northwind'), findsOneWidget);
      expect(_asked, isEmpty);
    });

    testWidgets('read-only or disabled, the row has no button', (tester) async {
      await _pump(tester, _field(cell, readOnly: true));
      expect(find.text('Northwind'), findsOneWidget);
      expect(find.byIcon(_replace), findsNothing);
      expect(find.byIcon(_remove), findsNothing);

      await _pump(tester, _field(cell, enabled: false));
      expect(find.text('Northwind'), findsOneWidget);
      expect(find.byIcon(_replace), findsNothing);
      expect(find.byIcon(_remove), findsNothing);
    });

    testWidgets('a record that failed to load can still be replaced', (
      tester,
    ) async {
      await _pump(
        tester,
        _field(cell, resolve: (ids) async => throw StateError('offline')),
      );
      expect(find.text('Couldn’t load'), findsOneWidget);
      // Replace, then Retry, then Remove.
      final x = [
        for (final icon in [_replace, _retry, _remove])
          tester.getCenter(find.byIcon(icon)).dx,
      ];
      expect(x[0], lessThan(x[1]));
      expect(x[1], lessThan(x[2]));

      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Harbour & Pine')));
      await tester.pumpAndSettle();
      expect(cell.value, 'm-2');
      expect(find.text('Harbour & Pine'), findsOneWidget);
      expect(find.byIcon(_retry), findsNothing);
    });
  });

  group('from the keyboard', () {
    setUp(() => cell.set('m-1'));

    testWidgets('Replace opens the picker on its search box', (tester) async {
      await _pump(tester, _field(cell));
      _focusOf(tester, find.byIcon(_replace)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(PopoverMenuSurface), findsOneWidget);
      final search = tester.widget<TextField>(
        _inPicker(find.byType(TextField)),
      );
      expect(search.focusNode!.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes it and hands focus back to Replace', (
      tester,
    ) async {
      await _pump(tester, _field(cell));
      _focusOf(tester, find.byIcon(_replace)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(PopoverMenuSurface), findsNothing);
      expect(cell.value, 'm-1');
      expect(_focusOf(tester, find.byIcon(_replace)).hasPrimaryFocus, isTrue);
    });

    testWidgets('a pick hands focus back to Replace too', (tester) async {
      await _pump(tester, _field(cell));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Atelier Vento')));
      await tester.pumpAndSettle();

      expect(cell.value, 'm-3');
      expect(_focusOf(tester, find.byIcon(_replace)).hasPrimaryFocus, isTrue);
    });
  });

  group('the Replace button', () {
    setUp(() => cell.set('m-1'));

    CircleButton button(WidgetTester tester) => tester.widget<CircleButton>(
      find.widgetWithIcon(CircleButton, _replace),
    );

    testWidgets('is named in the app\'s language', (tester) async {
      await _pump(tester, _field(cell, seed: _makers[0]));
      expect(button(tester).label, 'Replace');
      await _pump(
        tester,
        _field(cell, seed: _makers[0]),
        locale: const Locale('fr'),
      );
      expect(button(tester).label, 'Remplacer');
      await _pump(
        tester,
        _field(cell, seed: _makers[0]),
        locale: const Locale('ar'),
      );
      expect(button(tester).label, 'استبدال');
    });

    testWidgets('says whether its picker is open', (tester) async {
      await _pump(tester, _field(cell, seed: _makers[0]));
      expect(button(tester).expanded, isFalse);
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      expect(button(tester).expanded, isTrue);
    });
  });

  group('a reference list', () {
    late ValueCell<List<String>> list;

    setUp(() => list = scope.list('makers'));

    Widget listField({int? maxItems, List<_Maker>? seed}) =>
        ReferenceField<_Maker, String>(
          list,
          label: 'Makers',
          addLabel: 'Add a maker',
          idOf: (m) => m.id,
          resolve: _resolve,
          search: _search,
          tile: _tile,
          maxItems: maxItems,
          seed: seed,
        );

    testWidgets('at its cap has no add button, until a row goes', (
      tester,
    ) async {
      list.set(['m-1', 'm-2']);
      await _pump(tester, listField(maxItems: 2));
      expect(find.text('Add a maker'), findsNothing);
      // A list's rows are removed, not replaced.
      expect(find.byIcon(_replace), findsNothing);

      await tester.tap(find.byIcon(_remove).first);
      await tester.pumpAndSettle();
      expect(list.value, ['m-2']);
      expect(find.text('Add a maker'), findsOneWidget);
    });

    testWidgets('with no cap keeps its add button', (tester) async {
      list.set(['m-1', 'm-2', 'm-3']);
      await _pump(tester, listField());
      expect(find.text('Add a maker'), findsOneWidget);
    });

    testWidgets('resolves only the records the host does not hold', (
      tester,
    ) async {
      list.set(['m-1', 'm-2']);
      await _pump(tester, listField(seed: [_makers[0]]));
      expect(find.text('Northwind'), findsOneWidget);
      expect(find.text('Harbour & Pine'), findsOneWidget);
      expect(_asked, [
        ['m-2'],
      ]);
    });

    testWidgets('capped at one, a replaced record is still a list of one', (
      tester,
    ) async {
      list.set(['m-1']);
      await _pump(tester, listField(maxItems: 1));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Atelier Vento')));
      await tester.pumpAndSettle();
      expect(list.value, ['m-3']);
    });

    testWidgets('capped at one, picking the same record changes nothing', (
      tester,
    ) async {
      list.set(['m-1']);
      var changes = 0;
      list.addListener(() => changes++);
      await _pump(tester, listField(maxItems: 1));
      await tester.tap(find.byIcon(_replace));
      await tester.pumpAndSettle();
      await tester.tap(_inPicker(find.text('Northwind')));
      await tester.pumpAndSettle();
      expect(changes, 0);
      expect(find.byType(PopoverMenuSurface), findsNothing);
    });
  });
}
