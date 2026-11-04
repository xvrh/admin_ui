import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  ),
);

const _locales = [
  LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'de', native: 'Deutsch', status: LocaleStatus.outdated),
];

/// [child] under a [LangScope] of [locales], English → German by default,
/// and [binder]'s scope when there is one.
Widget _form(
  Widget child, {
  FieldBinder? binder,
  List<LocaleInfo> locales = _locales,
}) {
  final form = LangScope(
    locales: locales,
    visibleLocales: {for (final l in locales) l.code},
    sourceLocale: 'en',
    activeLocale: 'de',
    onVisibleLocalesChanged: (_) {},
    child: child,
  );
  return binder == null ? form : FieldBinderScope(binder: binder, child: form);
}

/// A binder whose every answer the test chooses, recording what [bind] is
/// handed.
class _Binder extends FieldBinder {
  final Widget? Function(Cell<Object?> cell)? takeOver;
  final LocaleStatus? status;
  final VoidCallback? action;

  /// The lanes [action] is offered for; null offers it for every lane.
  final Set<String>? actionLanes;

  final bindings = <Object>[];
  final retranslated = <String>[];

  _Binder({this.takeOver, this.status, this.action, this.actionLanes});

  @override
  Widget? bind<V>(BuildContext context, Cell<V> cell, FieldBinding<V> binding) {
    bindings.add(binding);
    return takeOver?.call(cell);
  }

  @override
  LocaleStatus? laneStatus<V>(
    BuildContext context,
    TranslatedCell<V> cell,
    String lang,
  ) => lang == 'de' ? status : null;

  @override
  VoidCallback? retranslate<V>(
    BuildContext context,
    TranslatedCell<V> cell,
    String lang,
  ) {
    final a = action;
    if (a == null || !(actionLanes?.contains(lang) ?? true)) return null;
    return () {
      retranslated.add(lang);
      a();
    };
  }
}

const _sourceChanged = 'Source changed since this was translated';

/// The labels of the field shells on screen, in order.
List<String> _shellLabels(WidgetTester tester) => [
  for (final shell in tester.widgetList<FieldShell>(find.byType(FieldShell)))
    shell.label,
];

void main() {
  late LocalScope scope;
  setUp(() => scope = LocalScope());
  tearDown(() => scope.dispose());

  group('without a binder', () {
    testWidgets('a scalar renders in its field shell', (tester) async {
      scope.text('name').set('Ada');
      await tester.pumpWidget(
        _host(_form(Field(scope.text('name'), label: 'Name'))),
      );
      expect(_shellLabels(tester), ['Name']);
      expect(find.widgetWithText(TextField, 'Ada'), findsOneWidget);
    });

    testWidgets('the lanes keep their declared status, and an outdated one '
        'only says its source changed', (tester) async {
      final title = scope.translated('title');
      title.lane('en').set('Summer');
      title.lane('de').set('Sommer');
      await tester.pumpWidget(_host(_form(Field(title, label: 'Title'))));
      expect(find.byType(LaneStack), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Summer'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Sommer'), findsOneWidget);
      expect(find.byTooltip('Outdated'), findsOneWidget);
      expect(find.text(_sourceChanged), findsOneWidget);
      expect(find.text('Re-translate'), findsNothing);
    });
  });

  group('a binder', () {
    testWidgets('that takes a cell over renders instead of the field', (
      tester,
    ) async {
      final binder = _Binder(
        takeOver: (cell) => cell.id == 'name' ? const Text('taken over') : null,
      );
      await tester.pumpWidget(
        _host(
          _form(
            FieldErrorsScope(
              errors: const {'name': 'Required'},
              child: Column(
                children: [
                  Field(
                    scope.text('name'),
                    label: 'Name',
                    help: const Text('?'),
                  ),
                  Field(scope.translated('title'), label: 'Title'),
                ],
              ),
            ),
            binder: binder,
          ),
        ),
      );
      expect(find.text('taken over'), findsOneWidget);
      // Declined, the translated cell renders the kit's lanes.
      expect(_shellLabels(tester), ['Title']);
      expect(find.byType(LaneStack), findsOneWidget);

      // The binding carries the preset's arguments, the error resolved from
      // the ambient scope, and the body that edits a lane.
      final name = binder.bindings.first as FieldBinding<String>;
      expect(name.label, 'Name');
      expect(name.help, isA<Text>());
      expect(name.errorText, 'Required');
      expect(name.readOnly, isFalse);
      expect(name.body(scope.text('name')), isA<TextCellBody>());
    });

    testWidgets('a lane status overrides the declared one', (tester) async {
      await tester.pumpWidget(
        _host(
          _form(
            Field(scope.translated('title'), label: 'Title'),
            binder: _Binder(status: LocaleStatus.review),
          ),
        ),
      );
      expect(find.byTooltip('Needs review'), findsOneWidget);
      expect(find.byTooltip('Outdated'), findsNothing);
      expect(find.text(_sourceChanged), findsNothing);
    });

    testWidgets('a null re-translate leaves the banner a plain warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _form(
            Field(scope.translated('title'), label: 'Title'),
            binder: _Binder(),
          ),
        ),
      );
      expect(find.text(_sourceChanged), findsOneWidget);
      expect(find.text('Re-translate'), findsNothing);
    });

    testWidgets('a re-translate action lands under the outdated lane', (
      tester,
    ) async {
      var calls = 0;
      final binder = _Binder(action: () => calls++);
      await tester.pumpWidget(
        _host(
          _form(
            Field(scope.translated('title'), label: 'Title'),
            binder: binder,
          ),
        ),
      );
      await tester.tap(find.text('Re-translate'));
      expect(calls, 1);
      expect(binder.retranslated, ['de']);
    });

    testWidgets('a lane the binder offers no re-translate for only says its '
        'source changed', (tester) async {
      final binder = _Binder(action: () {}, actionLanes: {'de'});
      await tester.pumpWidget(
        _host(
          _form(
            Field(scope.translated('title'), label: 'Title'),
            binder: binder,
            locales: const [
              ..._locales,
              LocaleInfo(
                code: 'fr',
                native: 'Français',
                status: LocaleStatus.outdated,
              ),
            ],
          ),
        ),
      );
      expect(find.text(_sourceChanged), findsNWidgets(2));
      expect(find.text('Re-translate'), findsOneWidget);
      await tester.tap(find.text('Re-translate'));
      expect(binder.retranslated, ['de']);
    });

    testWidgets('a read-only field offers no re-translate', (tester) async {
      await tester.pumpWidget(
        _host(
          _form(
            Field(scope.translated('title'), label: 'Title', readOnly: true),
            binder: _Binder(action: () {}),
          ),
        ),
      );
      expect(find.text(_sourceChanged), findsOneWidget);
      expect(find.text('Re-translate'), findsNothing);
    });
  });

  testWidgets('FieldBinderScope.of names the missing scope', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(FieldBinderScope.maybeOf(context), isNull);
    expect(
      () => FieldBinderScope.of(context),
      throwsA(
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('FieldBinderScope'),
        ),
      ),
    );
  });
}
