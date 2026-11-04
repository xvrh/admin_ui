import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source] with its theme's ramp, weights, geometry and anatomy, in the
/// platform's font: a Google font would be fetched on every `weighted` call.
AdminTokens _fontless(AdminTokens source) {
  final spec = source.typography.spec;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    type: AdminTypeSpec(
      ramp: spec.ramp,
      scale: spec.scale,
      heading: spec.heading,
      strong: spec.strong,
      body: spec.body,
      tracking: spec.tracking,
      uppercaseLabels: spec.uppercaseLabels,
    ),
    elevation: source.elevation,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    field: source.field,
    button: source.button,
    shell: source.shell,
  );
}

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 400, child: child),
    ),
  ),
);

const _options = [
  SelectOption(value: 'launch', label: 'launch'),
  SelectOption(value: 'summer', label: 'summer'),
  SelectOption(value: 'archive', label: 'archive'),
];

Finder _tagsIn(Type body) =>
    find.descendant(of: find.byType(body), matching: find.byType(Tag));

/// The pill a [Tag] paints: its outermost [Container].
BoxDecoration _pill(WidgetTester tester, Finder tag) =>
    tester
            .widget<Container>(
              find.descendant(of: tag, matching: find.byType(Container)).first,
            )
            .decoration!
        as BoxDecoration;

double _glyph(WidgetTester tester, Type body) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byType(body),
        matching: find.byIcon(Icons.close_rounded),
      ),
    )
    .size!;

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final name = '${theme.name} ${dark ? 'Dark' : 'Light'}';
      final tokens = _fontless(dark ? theme.dark! : theme.tokens);

      testWidgets('$name: a free tag and a multi-select token are one chip', (
        tester,
      ) async {
        for (final editable in [true, false]) {
          await tester.pumpWidget(
            _host(
              tokens,
              Column(
                children: [
                  TagsBody(
                    value: const ['launch'],
                    onChanged: editable ? (_) {} : null,
                  ),
                  MultiSelectBody(
                    options: _options,
                    value: const {'launch'},
                    creatable: true,
                    onChanged: editable ? (_) {} : null,
                  ),
                ],
              ),
            ),
          );
          final free = _tagsIn(TagsBody);
          final chosen = _tagsIn(MultiSelectBody);
          expect(free, findsOneWidget);
          expect(chosen, findsOneWidget);

          final state = editable ? 'editable' : 'read-only';
          expect(
            tester.getSize(free),
            tester.getSize(chosen),
            reason: '$state: same label, same chip',
          );
          final pill = BorderRadius.circular(tokens.radii.radiusPill);
          expect(_pill(tester, free).borderRadius, pill, reason: state);
          expect(_pill(tester, chosen).borderRadius, pill, reason: state);
          expect(
            _pill(tester, free).color,
            _pill(tester, chosen).color,
            reason: '$state: one tone',
          );
          if (editable) {
            expect(_glyph(tester, TagsBody), _glyph(tester, MultiSelectBody));
          }
        }
      });
    }
  }

  testWidgets('the multi-select checklist draws the kit Check', (tester) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        MultiSelectBody(
          options: _options,
          value: const {'launch'},
          maxItems: 1,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(MultiSelectBody));
    await tester.pumpAndSettle();

    final checks = tester.widgetList<Check>(find.byType(Check)).toList();
    expect(checks, hasLength(_options.length));
    expect(
      find.byWidgetPredicate((w) => '${w.runtimeType}' == 'CheckGlyph'),
      findsNothing,
    );
    // The checked option; the others are closed by the cap of one, and take
    // Check's disabled box.
    expect([for (final c in checks) c.value], [true, false, false]);
    expect([for (final c in checks) c.readOnly], [true, false, false]);
    expect(checks.every((c) => c.onChanged == null), isTrue);
  });

  testWidgets('the checklist appearance draws the kit Check', (tester) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        MultiSelectBody(
          options: _options,
          value: const {'summer'},
          appearance: MultiSelectAppearance.checklist,
          onChanged: (_) {},
        ),
      ),
    );
    final checks = tester.widgetList<Check>(find.byType(Check)).toList();
    expect([for (final c in checks) c.value], [false, true, false]);
    // Drawn only: the row is the one Tab stop and the one checkbox announced.
    expect(
      find.ancestor(
        of: find.byType(Check),
        matching: find.byType(ExcludeFocus),
      ),
      findsNWidgets(_options.length),
    );
  });

  testWidgets('the reference picker checks rows with the kit Check', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        ReferenceBody<String, String>(
          value: const ['alpha'],
          onChanged: (_) {},
          idOf: (id) => id,
          resolve: (ids) async => [...ids],
          search: (query, {cursor}) async =>
              const ReferencePage(['alpha', 'beta']),
          tile: (context, id) => ReferenceTileCard(title: id),
          seed: const ['alpha'],
        ),
      ),
    );
    await tester.tap(find.text('Link…'));
    await tester.pumpAndSettle();

    final checks = tester.widgetList<Check>(find.byType(Check)).toList();
    expect([for (final c in checks) c.value], [true, false]);
  });
}
