import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

/// Every shipped palette, in both modes and under every catalog brand.
final _palettes = <String, AdminPalette>{
  for (final theme in adminThemes)
    for (final (mode, palette) in [
      ('Light', theme.palette),
      ('Dark', theme.darkPalette!),
    ])
      for (final MapEntry(key: brand, value: seed) in _brands.entries)
        '${theme.name} $mode $brand': seed == null
            ? palette
            : palette.branded(seed),
};

Widget _themed(
  AdminPalette palette,
  Widget child, {
  AdminSegmentedStyle? segmented,
}) => MaterialApp(
  theme: buildAppTheme(
    AdminTokens.from(palette: palette, segmented: segmented),
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

BoxDecoration _decoration(WidgetTester tester, Finder container) =>
    tester.widget<Container>(container).decoration! as BoxDecoration;

Color _borderOf(BoxDecoration d) => (d.border! as Border).top.color;

/// The 18px box inside the Check keyed [key].
Finder _box(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.constraints?.maxWidth == 18,
  ),
);

/// Every radio ring, in the order the options are laid out.
final _rings = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      (w.decoration! as BoxDecoration).border != null,
);

String _ratio(double r) => '${r.toStringAsFixed(2)}:1';

/// Whether [color] is a grey, with no hue to tell it from another grey.
bool _isGrey(Color color) => HSLColor.fromColor(color).saturation < 0.1;

/// A segmented control's three looks: a track, joined segments with a soft
/// selection, and joined segments with an inverse one.
const _segmentStyles = {
  'track': AdminSegmentedStyle(),
  'joined': AdminSegmentedStyle(variant: SegmentedVariant.joined),
  'inverse': AdminSegmentedStyle(
    variant: SegmentedVariant.joined,
    inverse: true,
  ),
};

/// The fill of the segment labelled [label]: its own box, clear on a track.
Color _segmentFill(WidgetTester tester, String label) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

/// The knob a track draws behind its selected segment: the one box in the
/// Segmented that holds no label.
BoxDecoration _knob(WidgetTester tester) {
  final boxes = find.descendant(
    of: find.byWidgetPredicate((w) => w is Segmented),
    matching: find.byType(DecoratedBox),
  );
  final knob = boxes.evaluate().firstWhere(
    (box) => find
        .descendant(
          of: find.byElementPredicate((e) => e == box),
          matching: find.byType(Text),
        )
        .evaluate()
        .isEmpty,
  );
  return (knob.widget as DecoratedBox).decoration as BoxDecoration;
}

/// The render object that lays out the segments and paints the dividers.
RenderObject _strip(WidgetTester tester, String label) => tester.renderObject(
  find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_SegmentStrip',
        ),
      )
      .first,
);

void main() {
  group('an on control is marked at 3:1 on the surface', () {
    for (final name in [
      'Fluent Dark Default',
      'Iris Dark Violet',
      'Material Dark Violet',
      'Carbon Dark Violet',
    ]) {
      testWidgets(name, (tester) async {
        final palette = _palettes[name]!;
        const check = Key('check');
        await tester.pumpWidget(
          _themed(
            palette,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Check(key: check, value: true, onChanged: (_) {}),
                Choice<String>(
                  value: 'a',
                  onChanged: (_) {},
                  options: const [ChoiceOption('a', 'Alpha')],
                ),
                Toggle(value: true, onChanged: (_) {}),
                ValueSlider(value: 0.5, onChanged: (_) {}),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fill = _decoration(tester, _box(check)).color!;
        final ring = _borderOf(_decoration(tester, _rings.first));
        final track =
            (tester
                        .widget<AnimatedContainer>(
                          find.byType(AnimatedContainer),
                        )
                        .decoration!
                    as BoxDecoration)
                .color!;
        final slider = tester
            .widget<SliderTheme>(
              find.descendant(
                of: find.byType(ValueSlider),
                matching: find.byType(SliderTheme),
              ),
            )
            .data;
        for (final (what, color) in [
          ('check fill', fill),
          ('radio ring', ring),
          ('toggle track', track),
          ('slider track', slider.activeTrackColor!),
          ('slider thumb', slider.thumbColor!),
        ]) {
          final ratio = contrastRatio(color, palette.surface);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason: '$what on the surface: ${_ratio(ratio)}',
          );
          expect(color, palette.controlAccent, reason: what);
        }
        final tick = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
        expect(
          contrastRatio(tick.color!, fill),
          greaterThanOrEqualTo(3),
          reason: 'the tick on its fill',
        );
      });
    }
  });

  group('a picked day and a picked media tile take the control accent', () {
    for (final name in ['Fluent Dark Default', 'Iris Dark Violet']) {
      testWidgets(name, (tester) async {
        final palette = _palettes[name]!;
        Future<(Color fill, Color ink)> mark(Widget child, Finder ink) async {
          await tester.pumpWidget(_themed(palette, child));
          final fill = _decoration(
            tester,
            find.ancestor(of: ink, matching: find.byType(Container)).first,
          ).color!;
          final widget = tester.widget(ink);
          return (
            fill,
            widget is Icon ? widget.color! : (widget as Text).style!.color!,
          );
        }

        final day = await mark(
          Calendar(
            today: DateTime(2026, 6, 12),
            value: DateTime(2026, 6, 18),
            onChanged: (_) {},
          ),
          find.text('18'),
        );
        final disc = await mark(
          const SizedBox(
            width: 120,
            child: MediaTile(
              thumbnail: SizedBox(),
              title: 'harbour.jpg',
              selected: true,
              check: MediaTileCheck.always,
            ),
          ),
          find.byIcon(Icons.check),
        );
        for (final (what, (fill, ink), min) in [
          ('day', day, 4.5),
          ('check disc', disc, 3.0),
        ]) {
          expect(fill, palette.controlAccent, reason: what);
          expect(ink, palette.onControlAccent, reason: what);
          final onSurface = contrastRatio(fill, palette.surface);
          expect(
            onSurface,
            greaterThanOrEqualTo(3),
            reason: '$what on the surface: ${_ratio(onSurface)}',
          );
          final inked = contrastRatio(ink, fill);
          expect(
            inked,
            greaterThanOrEqualTo(min),
            reason: '$what mark on its fill: ${_ratio(inked)}',
          );
        }
      });
    }
  });

  group('an on knob and a selected radio centre are drawn like the tick', () {
    for (final MapEntry(key: name, value: palette) in _palettes.entries) {
      testWidgets(name, (tester) async {
        final hovered = WidgetStatesController({WidgetState.hovered});
        addTearDown(hovered.dispose);
        await tester.pumpWidget(
          _themed(
            palette,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Toggle(value: true, onChanged: (_) {}),
                Toggle(
                  value: true,
                  onChanged: (_) {},
                  statesController: hovered,
                ),
                Choice<String>(
                  value: 'a',
                  onChanged: (_) {},
                  options: const [ChoiceOption('a', 'Alpha')],
                ),
              ],
            ),
          ),
        );

        final tracks = [
          for (final track in tester.widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          ))
            (track.decoration! as BoxDecoration).color!,
        ];
        final knobs = [
          for (final knob in tester.widgetList<Container>(
            find.descendant(
              of: find.byType(AnimatedAlign),
              matching: find.byType(Container),
            ),
          ))
            (knob.decoration! as BoxDecoration).color!,
        ];
        expect(tracks, [palette.controlAccent, palette.controlAccentHover]);
        final radio = _decoration(tester, _rings.first);
        for (final (what, color, on) in [
          ('knob at rest', knobs[0], tracks[0]),
          ('hovered knob', knobs[1], tracks[1]),
          ('radio centre', radio.color!, _borderOf(radio)),
        ]) {
          expect(color, palette.onControlAccent, reason: what);
          final ratio = contrastRatio(color, on);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason: '$what on the accent: ${_ratio(ratio)}',
          );
        }
      });
    }

    // Accents lifted just to 3:1 off a dark page, where the page colour on
    // them would read as a hole in the track.
    for (final name in ['Iris Dark Violet', 'Carbon Dark Violet']) {
      testWidgets('$name: a light knob on the violet track', (tester) async {
        final palette = _palettes[name]!;
        await tester.pumpWidget(
          _themed(palette, Toggle(value: true, onChanged: (_) {})),
        );
        final knob = _decoration(
          tester,
          find.descendant(
            of: find.byType(AnimatedAlign),
            matching: find.byType(Container),
          ),
        ).color!;
        expect(
          knob.computeLuminance(),
          greaterThan(palette.controlAccent.computeLuminance()),
        );
        expect(knob, isNot(palette.surface));
      });
    }
  });

  group('hover never makes an unchecked control fainter', () {
    for (final MapEntry(key: name, value: palette) in _palettes.entries) {
      testWidgets(name, (tester) async {
        final hovered = WidgetStatesController({WidgetState.hovered});
        final hoveredRadio = WidgetStatesController({WidgetState.hovered});
        addTearDown(hovered.dispose);
        addTearDown(hoveredRadio.dispose);
        const rest = Key('rest'), hover = Key('hover');
        await tester.pumpWidget(
          _themed(
            palette,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Check(key: rest, value: false, onChanged: (_) {}),
                Check(
                  key: hover,
                  value: false,
                  onChanged: (_) {},
                  statesController: hovered,
                ),
                Choice<String>(
                  value: null,
                  onChanged: (_) {},
                  options: [
                    const ChoiceOption('a', 'Alpha'),
                    ChoiceOption('b', 'Beta', statesController: hoveredRadio),
                  ],
                ),
              ],
            ),
          ),
        );

        double onSurface(Color c) => contrastRatio(c, palette.surface);
        final boxRest = _borderOf(_decoration(tester, _box(rest)));
        final boxHover = _borderOf(_decoration(tester, _box(hover)));
        expect(boxRest, palette.controlBorder);
        expect(
          onSurface(boxHover),
          greaterThanOrEqualTo(onSurface(boxRest)),
          reason:
              'Check: ${_ratio(onSurface(boxHover))} hovered, '
              '${_ratio(onSurface(boxRest))} at rest',
        );

        final ringRest = _borderOf(_decoration(tester, _rings.at(0)));
        final ringHover = _borderOf(_decoration(tester, _rings.at(1)));
        expect(ringRest, palette.controlBorder);
        expect(ringHover, boxHover);
        expect(onSurface(ringHover), greaterThanOrEqualTo(onSurface(ringRest)));
      });
    }
  });

  testWidgets('a Toggle without a label is named by its semanticLabel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _themed(
        _palettes['Iris Light Default']!,
        Toggle(
          value: true,
          onChanged: (_) {},
          semanticLabel: 'Email notifications',
        ),
      ),
    );
    expect(
      tester.getSemantics(
        find
            .descendant(
              of: find.byType(Toggle),
              matching: find.byType(GestureDetector),
            )
            .first,
      ),
      isSemantics(
        label: 'Email notifications',
        isButton: false,
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  group('Combobox keeps the keyboard highlight through a parent rebuild', () {
    const letters = [
      ('a', 'Alpha'),
      ('b', 'Bravo'),
      ('c', 'Charlie'),
      ('d', 'Delta'),
      ('e', 'Echo'),
    ];

    /// A combobox on [initial] whose options are a fresh list on every
    /// build, as an inline literal is; [rebuild] rebuilds it, first adding
    /// [prepend] when given.
    Future<({List<String?> picks, void Function({String? prepend}) rebuild})>
    pump(WidgetTester tester, {String initial = 'b'}) async {
      final picks = <String?>[];
      String? value = initial;
      String? extra;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _themed(
          _palettes['Iris Light Default']!,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Combobox<String>(
                value: value,
                options: [
                  if (extra != null) ComboboxOption(extra!, extra!),
                  for (final (v, label) in letters) ComboboxOption(v, label),
                ],
                onChanged: (v) {
                  picks.add(v);
                  setState(() => value = v);
                },
              );
            },
          ),
        ),
      );
      return (
        picks: picks,
        rebuild: ({String? prepend}) => setOuter(() => extra = prepend),
      );
    }

    Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    testWidgets('an equal list written inline', (tester) async {
      final combo = await pump(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      combo.rebuild();
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.enter);
      expect(combo.picks, ['d']);
    });

    testWidgets('a changed list that still offers the highlighted option', (
      tester,
    ) async {
      final combo = await pump(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      combo.rebuild(prepend: 'Zulu');
      await tester.pumpAndSettle();
      expect(find.text('Zulu'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.enter);
      expect(combo.picks, ['d']);
    });
  });

  group('a hovered or pressed segment keeps its label at 4.5:1, and the '
      'hovered one reads apart from the selection', () {
    for (final MapEntry(key: look, value: style) in _segmentStyles.entries) {
      for (final MapEntry(key: name, value: palette) in _palettes.entries) {
        testWidgets('$look, $name', (tester) async {
          final hovered = WidgetStatesController({WidgetState.hovered});
          final pressed = WidgetStatesController({WidgetState.pressed});
          addTearDown(hovered.dispose);
          addTearDown(pressed.dispose);
          await tester.pumpWidget(
            _themed(
              palette,
              segmented: style,
              Segmented<String>(
                value: 'a',
                onChanged: (_) {},
                segments: [
                  const SegmentOption('a', 'List'),
                  SegmentOption('b', 'Grid', statesController: hovered),
                  SegmentOption('c', 'Map', statesController: pressed),
                ],
              ),
            ),
          );
          final track = style.variant == SegmentedVariant.track;
          Color text(String label) =>
              tester.widget<Text>(find.text(label)).style!.color!;
          // What a label sits on: its segment's fill, over the track's wash
          // on a track.
          Color ground(String label) => track
              ? Color.alphaBlend(
                  _segmentFill(tester, label),
                  Color.alphaBlend(palette.hoverOverlay, palette.surface),
                )
              : _segmentFill(tester, label);
          for (final label in ['Grid', 'Map']) {
            expect(
              _segmentFill(tester, label),
              isNot(track ? const Color(0x00000000) : palette.surface),
              reason: '$label: the tint shows',
            );
            final ratio = contrastRatio(text(label), ground(label));
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '$label: ${_ratio(ratio)}',
            );
          }
          if (track) {
            // The selection is the raised knob, which a hovered segment's
            // wash can't pass for.
            final knob = _knob(tester);
            expect(knob.color, isNot(ground('Grid')));
            expect(knob.boxShadow ?? knob.border, isNotNull, reason: 'raised');
            final ratio = contrastRatio(text('List'), knob.color!);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: 'the selected label on its knob: ${_ratio(ratio)}',
            );
            return;
          }
          expect(text('Grid'), isNot(text('List')));
          if (!style.inverse && _isGrey(palette.onSoft)) {
            // A neutral selection's fill is a grey much like the hover's,
            // and no hue sets its label apart: lightness has to.
            final apart = contrastRatio(text('Grid'), text('List'));
            expect(
              apart,
              greaterThanOrEqualTo(1.5),
              reason: 'hovered against selected label: ${_ratio(apart)}',
            );
          }
        });
      }
    }
  });

  testWidgets('joined segments are outlined like a field, dividers included', (
    tester,
  ) async {
    final palette = _palettes['shadcn Light Default']!;
    Future<void> expectOutline({required bool enabled}) async {
      await tester.pumpWidget(
        _themed(
          palette,
          segmented: _segmentStyles['joined'],
          Segmented<String>(
            value: 'a',
            onChanged: enabled ? (_) {} : null,
            segments: const [
              SegmentOption('a', 'List'),
              SegmentOption('b', 'Grid'),
            ],
          ),
        ),
      );
      final outline = fieldBorderSide(palette, {
        if (!enabled) WidgetState.disabled,
      }, stroke: const AdminStroke()).color;
      final group = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Segmented<String>),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.foregroundDecoration != null,
              ),
            )
            .first,
      );
      expect(_borderOf(group.foregroundDecoration! as BoxDecoration), outline);
      expect(_strip(tester, 'List'), paints..rect(color: outline));
    }

    await expectOutline(enabled: true);
    expect(
      fieldBorderSide(palette, const {}, stroke: const AdminStroke()).color,
      palette.controlBorder,
      reason: 'an enabled field is outlined in controlBorder',
    );
    await expectOutline(enabled: false);
  });

  testWidgets('an inverse switcher is ringed in the foreground, and its '
      'selection swallows the dividers beside it', (tester) async {
    final palette = _palettes['Carbon Light Default']!;
    Future<void> pump(String value) => tester.pumpWidget(
      _themed(
        palette,
        segmented: _segmentStyles['inverse'],
        Segmented<String>(
          value: value,
          onChanged: (_) {},
          segments: const [
            SegmentOption('a', 'Day'),
            SegmentOption('b', 'Week'),
            SegmentOption('c', 'Month'),
          ],
        ),
      ),
    );
    await pump('a');
    final group = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Segmented<String>),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.foregroundDecoration != null,
            ),
          )
          .first,
    );
    expect(
      _borderOf(group.foregroundDecoration! as BoxDecoration),
      palette.foreground,
    );
    expect(_segmentFill(tester, 'Day'), palette.foreground);
    expect(
      tester.widget<Text>(find.text('Day')).style!.color,
      palette.foregroundOn(palette.foreground),
    );
    expect(
      _strip(tester, 'Day'),
      paints
        ..rect(color: palette.foreground)
        ..rect(color: palette.border),
    );
    await pump('b');
    expect(
      _strip(tester, 'Day'),
      paints
        ..rect(color: palette.foreground)
        ..rect(color: palette.foreground),
    );
  });

  group('calendar day rows', () {
    final today = DateTime(2026, 6, 12);

    /// The tap target of the day labelled [day].
    Finder cell(String day) => find
        .ancestor(of: find.text(day), matching: find.byType(GestureDetector))
        .first;

    /// The fill of the day labelled [day].
    Finder fill(String day) => find
        .ancestor(of: find.text(day), matching: find.byType(Container))
        .first;

    Future<List<DateTime>> pump(WidgetTester tester) async {
      final picks = <DateTime>[];
      await tester.pumpWidget(
        _themed(
          _palettes['Iris Light Default']!,
          Calendar(today: today, value: today, onChanged: picks.add),
        ),
      );
      return picks;
    }

    testWidgets(
      'reach a 44px touch target, the whole cell taking the tap',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final picks = await pump(tester);
        final target = tester.getRect(cell('16'));
        expect(target.height, greaterThanOrEqualTo(44));
        expect(tester.getSize(fill('16')), const Size(36, 36));
        expect(
          tester.getTopLeft(cell('23')).dy - target.top,
          target.height,
          reason: 'the rows leave no gap between their targets',
        );

        // Just inside the top edge, above the day's fill.
        await tester.tapAt(target.topCenter + const Offset(0, 1));
        expect(picks, [DateTime(2026, 6, 16)]);
      },
    );

    testWidgets(
      'stay 36px under a mouse',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        await pump(tester);
        expect(tester.getSize(cell('16')).height, 36);
        expect(tester.getSize(fill('16')), const Size(32, 32));
      },
    );

    testWidgets(
      'a range band keeps the height of the day fill under touch',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        await tester.pumpWidget(
          _themed(
            _palettes['Iris Light Default']!,
            Calendar(
              mode: CalendarMode.range,
              today: today,
              range: DateTimeRange(
                start: DateTime(2026, 6, 10),
                end: DateTime(2026, 6, 21),
              ),
              onRangeChanged: (_) {},
            ),
          ),
        );
        final soft = _palettes['Iris Light Default']!.primarySubtle;
        final bands = find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == soft,
        );
        expect(bands, findsWidgets);
        expect(tester.getSize(bands.first).height, 36);
      },
    );
  });
}
