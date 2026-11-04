import 'dart:io';
import 'dart:typed_data';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source] with its theme's ramp, weights and geometry, in the platform's
/// font: a Google font would be fetched on every `weighted` call.
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
  );
}

/// Every shipped theme's light and dark token sets, by "Theme Mode".
final _tokens = {
  for (final theme in adminThemes) ...{
    '${theme.name} Light': _fontless(theme.tokens),
    if (theme.dark case final dark?) '${theme.name} Dark': _fontless(dark),
  },
};

AdminTokens _theme(String name) => _tokens['$name Light']!;

Widget _host(Widget child, AdminTokens tokens, {bool reduced = false}) =>
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

const _ref = VersionRef(
  id: 'v1',
  label: 'Published',
  author: 'Ada Park',
  initials: 'AP',
  timestamp: 'yesterday',
  status: VersionStatus.published,
);

const _diff = VersionDiff(
  base: _ref,
  compare: _ref,
  locales: ['en', 'fr'],
  fields: [
    FieldDiff(
      label: 'Title',
      fieldKey: 'title',
      kind: DiffFieldKind.text,
      translatable: true,
      locales: [
        LocaleDiff(locale: 'en', op: DiffOp.changed, before: 'a', after: 'b'),
        LocaleDiff(locale: 'fr', op: DiffOp.changed, before: 'c', after: 'd'),
      ],
    ),
  ],
);

/// The corner radii of every box decoration under [of].
Iterable<double> _radii(WidgetTester tester, Finder of) sync* {
  for (final box in tester.widgetList<Container>(
    find.descendant(of: of, matching: find.byType(Container)),
  )) {
    if (box.decoration case BoxDecoration(:final BorderRadius borderRadius)) {
      yield borderRadius.topLeft.x;
    }
  }
}

/// A toggle button of a [DiffView]'s controls strip, found by label: the
/// lanes' own locale tags are not tappable.
Finder _toggle(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Tappable));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiffView controls', () {
    for (final MapEntry(key: name, value: tokens) in _tokens.entries) {
      testWidgets('$name: each toggle is a medium control, level with the '
          'layout control', (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 1000,
              height: 600,
              child: DiffView(diff: _diff),
            ),
            tokens,
          ),
        );
        final segmented = tester.getSize(find.byType(Segmented<DiffLayout>));
        expect(segmented.height, tokens.sizes.medium);
        for (final label in ['EN', 'FR', 'Unchanged']) {
          final toggle = _toggle(label);
          expect(toggle, findsOneWidget, reason: label);
          expect(
            tester.getSize(toggle).height,
            tokens.sizes.medium,
            reason: '$label beside a ${segmented.height}px Segmented',
          );
          expect(
            tester.getCenter(toggle).dy,
            moreOrLessEquals(
              tester.getCenter(find.byType(Segmented<DiffLayout>)).dy,
            ),
            reason: label,
          );
          final box =
              tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: toggle,
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration;
          expect(
            (box.borderRadius! as BorderRadius).topLeft.x,
            tokens.radii.button(ControlSize.medium),
            reason: '$label takes the corner of the Segmented beside it',
          );
        }
      });
    }
  });

  group('radii follow the theme', () {
    // The highlighted Hero has no preview while Text has one: two panes,
    // the preview pane showing Hero's inline-insert tile.
    final entries = [
      const InsertPickerEntry(
        id: 'hero',
        label: 'Hero',
        icon: Icons.web_asset,
        category: 'Layout',
      ),
      InsertPickerEntry(
        id: 'text',
        label: 'Text',
        icon: Icons.notes,
        category: 'Content',
        description: 'Paragraphs',
        preview: (_) => const SizedBox(),
      ),
    ];

    for (final name in ['Carbon', 'Material', 'Iris']) {
      testWidgets('$name: block picker and diff op tags', (tester) async {
        final tokens = _theme(name);
        final scale = {
          tokens.radii.radiusSmall,
          tokens.radii.radius,
          tokens.radii.radiusLarge,
        };
        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 480,
                  child: InsertPicker(entries: entries, onSelect: (_) {}),
                ),
                for (final op in DiffOp.values) DiffOpTag(op),
              ],
            ),
            tokens,
          ),
        );
        expect(find.text('Hero'), findsNWidgets(2));
        final picker = _radii(tester, find.byType(InsertPicker)).toList();
        expect(picker, hasLength(greaterThanOrEqualTo(4)));
        for (final r in picker) {
          expect(scale, contains(r), reason: 'block picker radius $r');
        }
        for (final op in DiffOp.values) {
          final radii = _radii(tester, find.byType(DiffOpTag).at(op.index));
          expect(radii.single, tokens.radii.radiusSmall, reason: '$op');
        }
        if (name == 'Carbon') {
          for (final r in [
            ...picker,
            ..._radii(tester, find.byType(DiffOpTag)),
          ]) {
            expect(r, lessThanOrEqualTo(4));
          }
        }
      });
    }
  });

  group('QuickDiffSurface', () {
    for (final MapEntry(key: name, value: tokens) in _tokens.entries) {
      testWidgets('$name: the kit popover surface, edged', (tester) async {
        await tester.pumpWidget(
          _host(
            const QuickDiffSurface(
              title: 'Title',
              child: DiffOpTag(DiffOp.changed),
            ),
            tokens,
          ),
        );
        final surface = find.descendant(
          of: find.byType(QuickDiffSurface),
          matching: find.byType(PopoverMenuSurface),
        );
        expect(surface, findsOneWidget);
        final material = tester.widget<Material>(
          find.descendant(of: surface, matching: find.byType(Material)).first,
        );
        expect(material.elevation, 0);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.side.style, BorderStyle.solid);
        expect(shape.side.width, greaterThan(0));
        expect(shape.side.color, tokens.palette.border);
        expect(
          (shape.borderRadius as BorderRadius).topLeft.x,
          tokens.radii.radiusMenu,
        );
      });
    }
  });

  group('menu editor', () {
    const entries = [
      TreeEditorEntry(id: 'home', title: 'Home'),
      TreeEditorEntry(id: 'about', title: 'About'),
    ];
    Widget editor() => SizedBox(
      width: 520,
      child: TreeEditor(
        maxDepth: 2,
        entries: entries,
        selectedId: 'about',
        onSelect: (_) {},
        onMove: (_, _, _) {},
        onToggleVisible: (_) {},
        onAddChild: (_) {},
        onDelete: (_) {},
      ),
    );

    testWidgets('row actions fade in the theme\'s fast duration, or at once '
        'when animations are disabled', (tester) async {
      final tokens = _theme('Fluent');
      await tester.pumpWidget(_host(editor(), tokens));
      final fades = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(fades, hasLength(entries.length));
      for (final fade in fades) {
        expect(fade.duration, tokens.motion.fast);
      }
      await tester.pumpWidget(_host(editor(), tokens, reduced: true));
      for (final fade in tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      )) {
        expect(fade.duration, Duration.zero);
      }
    });

    testWidgets('the selected row takes the palette\'s selected wash', (
      tester,
    ) async {
      for (final name in ['Iris', 'Material']) {
        final tokens = _theme(name);
        await tester.pumpWidget(_host(editor(), tokens));
        // Past the app's theme change animation.
        await tester.pumpAndSettle();
        final palette = tokens.palette;
        final wash = palette.primary.withValues(
          alpha: palette.stateLayer.selected,
        );
        final fills = [
          for (final box in tester.widgetList<Container>(
            find.ancestor(
              of: find.text('About'),
              matching: find.byType(Container),
            ),
          ))
            if (box.decoration case BoxDecoration(:final color?)) color,
        ];
        expect(fills, contains(wash), reason: name);
      }
    });
  });

  group('cropper tools', () {
    for (final name in ['Iris', 'Carbon', 'Ant']) {
      testWidgets('$name: small kit buttons, named, and the vertical flip '
          'flips', (tester) async {
        final tokens = _theme(name);
        final handle = tester.ensureSemantics();
        CropValue? changed;
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 600,
              height: 420,
              child: ImageCropper(
                image: MemoryImage(Uint8List(0)),
                imageAspect: 1.5,
                onChanged: (v) => changed = v,
                allowRotate: true,
                allowFlip: true,
                allowReset: true,
              ),
            ),
            tokens,
          ),
        );
        final buttons = find.byType(Button);
        expect(buttons, findsNWidgets(5));
        for (final button in tester.widgetList<Button>(buttons)) {
          expect(button.size, ControlSize.small);
        }
        for (final size in buttons.evaluate().map(
          (e) => tester.getSize(find.byWidget(e.widget)),
        )) {
          expect(size, Size.square(tokens.sizes.small));
        }
        for (final label in [
          'Rotate left',
          'Rotate right',
          'Flip horizontal',
          'Flip vertical',
          'Reset',
        ]) {
          expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        }
        await tester.tap(find.bySemanticsLabel('Flip vertical'));
        await tester.pump();
        expect(changed?.flipV, isTrue);
        expect(changed?.flipH, isFalse);
        handle.dispose();
      });
    }
  });

  test('history, assets, forms, comments and the tree editor use the kit '
      'tooltip and spinner', () {
    final roots = [
      'lib/src/history',
      'lib/src/assets',
      'lib/src/forms',
      'lib/src/comments',
      'lib/src/common/ui/swatch_row.dart',
      'lib/src/common/ui/tree_editor.dart',
    ];
    final files = [
      for (final root in roots)
        ...FileSystemEntity.isDirectorySync(root)
            ? Directory(root)
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.dart'))
            : [File(root)],
    ];
    expect(files.length, greaterThan(roots.length));
    final raw = RegExp(r'\b(Tooltip|CircularProgressIndicator)\(');
    final offenders = [
      for (final file in files)
        for (final (i, line) in file.readAsLinesSync().indexed)
          if (!line.trimLeft().startsWith('//') && raw.hasMatch(line))
            '${file.path}:${i + 1}: ${line.trim()}',
    ];
    expect(offenders, isEmpty, reason: 'use Tip and Spinner');
  });
}
