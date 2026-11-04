import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'readme/appearance.dart';

const _teal = Color(0xFF0D9488);

/// A picker that takes each change it hands out, recorded in [changes].
class _Live extends StatefulWidget {
  final AdminAppearance initial;
  final List<AdminAppearance> changes;

  const _Live(this.initial, this.changes);

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late AdminAppearance _value = widget.initial;

  @override
  Widget build(BuildContext context) => AppearancePicker(
    value: _value,
    onChanged: (value) => setState(() {
      widget.changes.add(value);
      _value = value;
    }),
  );
}

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 480,
}) => MaterialApp(
  theme: buildAppTheme(irisTheme.tokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// The swatch named [name].
Finder _swatch(String name) =>
    find.byWidgetPredicate((w) => w is Tip && w.message == name);

final _iris = AdminAppearance(theme: irisTheme);

void main() {
  testWidgets('each control hands onChanged the copy it edits', (tester) async {
    final changes = <AdminAppearance>[];
    await tester.pumpWidget(_app(_Live(_iris, changes)));

    await tester.tap(find.text('Carbon'));
    await tester.pump();
    expect(changes.last, _iris.copyWith(theme: carbonTheme));

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(changes.last.mode, ThemeMode.dark);

    await tester.tap(_swatch('Teal'));
    await tester.pump();
    expect(changes.last.accent, _teal);

    await tester.tap(find.text('Compact'));
    await tester.pump();
    expect(
      changes.last,
      AdminAppearance(
        theme: carbonTheme,
        mode: ThemeMode.dark,
        accent: _teal,
        density: TableDensity.compact,
      ),
    );

    await tester.tap(_swatch('Theme colour'));
    await tester.pump();
    expect(changes.last.accent, isNull);

    await tester.tap(find.text('System'));
    await tester.pump();
    expect(changes.last.mode, ThemeMode.system);
    expect(changes, hasLength(6));

    // Picking what is already picked changes nothing.
    await tester.tap(find.text('Carbon'));
    await tester.tap(find.text('System'));
    await tester.tap(_swatch('Theme colour'));
    await tester.pump();
    expect(changes, hasLength(6));
  });

  testWidgets('offers the given themes and accents; density can go', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AppearancePicker(
          value: AdminAppearance(theme: antTheme),
          onChanged: (_) {},
          themes: [antTheme, fluentTheme],
          accents: const {'Brand blue': Color(0xFF2563EB)},
          showDensity: false,
        ),
      ),
    );
    expect(find.text('Iris'), findsNothing);
    expect(find.text('Ant'), findsOneWidget);
    expect(find.text('Fluent'), findsOneWidget);
    expect(
      [for (final tip in tester.widgetList<Tip>(find.byType(Tip))) tip.message],
      ['Theme colour', 'Brand blue'],
    );
    expect(find.byType(Segmented<TableDensity>), findsNothing);
    expect(find.byType(Choice<TableDensity>), findsNothing);
  });

  testWidgets("the theme's own swatch is its primary in the shown "
      'brightness', (tester) async {
    Color own() => tester
        .widget<SwatchRow<Color?>>(find.byType(SwatchRow<Color?>))
        .options
        .first
        .color;
    for (final (mode, palette) in [
      (ThemeMode.light, carbonTheme.palette),
      (ThemeMode.dark, carbonTheme.darkPalette!),
    ]) {
      await tester.pumpWidget(
        _app(
          AppearancePicker(
            value: AdminAppearance(theme: carbonTheme, mode: mode),
            onChanged: (_) {},
          ),
        ),
      );
      expect(own(), palette.primary);
    }
  });

  testWidgets("the picked accent's name follows the swatches", (tester) async {
    await tester.pumpWidget(
      _app(
        AppearancePicker(
          value: _iris.copyWith(accent: _teal),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Teal'), findsOneWidget);
    expect(find.text('Theme colour'), findsNothing);

    await tester.pumpWidget(
      _app(AppearancePicker(value: _iris, onChanged: (_) {})),
    );
    expect(find.text('Theme colour'), findsOneWidget);

    // An accent that is not offered shows no swatch picked, and no name.
    await tester.pumpWidget(
      _app(
        AppearancePicker(
          value: _iris.copyWith(accent: const Color(0xFF123456)),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Theme colour'), findsNothing);
    expect(
      tester.widget<SwatchRow<Color?>>(find.byType(SwatchRow<Color?>)).value,
      const Color(0xFF123456),
    );
  });

  group('localised', () {
    for (final (locale, labels, modes, densities, accents) in [
      (
        const Locale('en'),
        ['Theme', 'Mode', 'Accent colour', 'Table density'],
        ['Light', 'Dark', 'System'],
        ['Compact', 'Standard', 'Comfortable'],
        ['Theme colour', 'Crimson', 'Violet', 'Teal', 'Amber'],
      ),
      (
        const Locale('fr'),
        ['Thème', 'Mode', 'Couleur d’accent', 'Densité des tableaux'],
        ['Clair', 'Sombre', 'Système'],
        ['Compacte', 'Standard', 'Confortable'],
        ['Couleur du thème', 'Cramoisi', 'Violet', 'Sarcelle', 'Ambre'],
      ),
      (
        const Locale('ar'),
        ['السمة', 'الوضع', 'لون التمييز', 'كثافة الجداول'],
        ['فاتح', 'داكن', 'النظام'],
        ['مضغوطة', 'عادية', 'مريحة'],
        ['لون السمة', 'قرمزي', 'بنفسجي', 'أزرق مخضرّ', 'كهرماني'],
      ),
    ]) {
      testWidgets('in ${locale.languageCode}', (tester) async {
        await tester.pumpWidget(
          _app(
            AppearancePicker(value: _iris, onChanged: (_) {}),
            locale: locale,
            width: 640,
          ),
        );
        expect([
          for (final field in tester.widgetList<LabeledField>(
            find.byType(LabeledField),
          ))
            field.label,
        ], labels);
        expect([
          for (final s
              in tester
                  .widget<Segmented<ThemeMode>>(
                    find.byType(Segmented<ThemeMode>),
                  )
                  .segments)
            s.label,
        ], modes);
        expect([
          for (final s
              in tester
                  .widget<Segmented<TableDensity>>(
                    find.byType(Segmented<TableDensity>),
                  )
                  .segments)
            s.label,
        ], densities);
        expect([
          for (final tip in tester.widgetList<Tip>(find.byType(Tip)))
            tip.message,
        ], accents);
        // Theme names are names, in every language.
        for (final theme in adminThemes) {
          expect(find.text(theme.name), findsOneWidget);
        }
      });
    }
  });

  testWidgets('each group is named by its label, and says what is picked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        AppearancePicker(
          value: _iris.copyWith(mode: ThemeMode.dark, accent: _teal),
          onChanged: (_) {},
        ),
      ),
    );

    /// The label of the nearest named node above [node]: a field's label
    /// names the group of controls under it.
    String groupOf(SemanticsNode node) {
      var group = node.parent;
      while (group != null && group.label.isEmpty) {
        group = group.parent;
      }
      return group?.label ?? '';
    }

    /// Whether [node] sits in a radio group.
    bool inRadioGroup(SemanticsNode node) {
      for (var n = node.parent; n != null; n = n.parent) {
        if (n.getSemanticsData().role == SemanticsRole.radioGroup) return true;
      }
      return false;
    }

    for (final (option, label) in [
      ('Iris', 'Theme'),
      ('Dark', 'Mode'),
      ('Standard', 'Table density'),
    ]) {
      final node = tester.getSemantics(find.text(option));
      expect(inRadioGroup(node), isTrue, reason: option);
      expect(groupOf(node), label);
    }
    expect(
      groupOf(tester.getSemantics(find.bySemanticsLabel('Teal'))),
      'Accent colour',
    );
    expect(
      tester.getSemantics(find.text('Iris')),
      isSemantics(
        label: 'Iris',
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        isFocusable: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Dark')),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Teal')),
      isSemantics(
        label: 'Teal',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Crimson')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    // The name after the swatches is not read again.
    expect(find.bySemanticsLabel('Teal'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the keyboard reaches and changes every control', (tester) async {
    final changes = <AdminAppearance>[];
    await tester.pumpWidget(_app(_Live(_iris, changes)));

    // The theme radios: one Tab stop, the arrows pick.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(changes.last.theme, materialTheme);

    // The mode segments: the next Tab stop.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(changes.last.mode, ThemeMode.light);

    // Each swatch is a Tab stop, picked with Enter or Space.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(changes.last.accent, adminAccents['Crimson']);

    // Past the swatches, the density.
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changes.last.density, TableDensity.comfortable);
    expect(changes, hasLength(4));
  });

  testWidgets('mirrors right to left', (tester) async {
    await tester.pumpWidget(
      _app(
        AppearancePicker(value: _iris, onChanged: (_) {}),
        locale: const Locale('ar'),
      ),
    );
    final picker = tester.getRect(find.byType(AppearancePicker));
    final iris = tester.getRect(find.text('Iris'));
    final label = tester.getRect(find.text('السمة'));
    expect(label.right, moreOrLessEquals(picker.right, epsilon: 0.5));
    // The radio's dot, 18 wide and 8 off, sits right of its name.
    expect(iris.right, moreOrLessEquals(picker.right - 26, epsilon: 0.5));

    double x(Finder f) => tester.getCenter(f).dx;
    expect(x(_swatch('لون السمة')), greaterThan(x(_swatch('قرمزي'))));
    expect(x(_swatch('قرمزي')), greaterThan(x(_swatch('كهرماني'))));
    expect(x(find.text('فاتح')), greaterThan(x(find.text('داكن'))));
    expect(x(find.text('داكن')), greaterThan(x(find.text('النظام'))));
    final segments = tester.getRect(find.byType(Segmented<ThemeMode>));
    expect(segments.right, moreOrLessEquals(picker.right, epsilon: 0.5));
  });

  group('where the segments would cut a label', () {
    testWidgets('they are radios', (tester) async {
      final changes = <AdminAppearance>[];
      await tester.pumpWidget(_app(_Live(_iris, changes), width: 200));
      await tester.pump();

      // A finder sees the radios alone, as the screen does.
      expect(find.text('Comfortable'), findsOneWidget);
      expect(find.byType(Choice<TableDensity>), findsOneWidget);
      expect(find.byType(Segmented<TableDensity>), findsNothing);
      expect(
        find.text('Comfortable').hitTestable(),
        findsOneWidget,
        reason: 'the radio it finds is the one drawn',
      );
      final radios = tester.getRect(find.byType(Choice<TableDensity>));
      final field = tester.getRect(
        find.ancestor(
          of: find.byType(Choice<TableDensity>),
          matching: find.byType(LabeledField),
        ),
      );
      expect(field.bottom, greaterThanOrEqualTo(radios.bottom));

      await tester.tap(find.text('Comfortable'));
      await tester.pump();
      expect(changes.last.density, TableDensity.comfortable);
    });

    testWidgets('with room they are segments', (tester) async {
      await tester.pumpWidget(_app(_Live(_iris, []), width: 480));
      await tester.pump();
      expect(find.text('Comfortable'), findsOneWidget);
      expect(find.byType(Segmented<TableDensity>), findsOneWidget);
      expect(find.byType(Choice<TableDensity>), findsNothing);
    });

    testWidgets('only the one shown is read out and takes focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_Live(_iris, []), width: 200));
      await tester.pump();
      expect(find.bySemanticsLabel('Comfortable'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Comfortable')),
        isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true),
      );

      // Theme, mode, the five swatches: the next Tab stop is the radios,
      // not the segments laid out behind them.
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<Choice<TableDensity>>(),
        isNotNull,
      );
      handle.dispose();
    });

    testWidgets('growing back gives the segments the focus order again', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_Live(_iris, []), width: 200));
      await tester.pump();
      await tester.pumpWidget(_app(_Live(_iris, []), width: 480));
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<Segmented<TableDensity>>(),
        isNotNull,
      );
    });
  });

  testWidgets('disabled, nothing changes', (tester) async {
    var changed = 0;
    for (final picker in [
      AppearancePicker(
        value: _iris,
        enabled: false,
        onChanged: (_) => changed++,
      ),
      AppearancePicker(value: _iris),
    ]) {
      await tester.pumpWidget(_app(picker));
      await tester.tap(find.text('Carbon'));
      await tester.tap(find.text('Dark'));
      await tester.tap(_swatch('Teal'));
      await tester.tap(find.text('Compact'));
      await tester.pump();
    }
    expect(changed, 0);
  });

  testWidgets("the README's app draws with the look it picks", (tester) async {
    await tester.pumpWidget(const MyAdmin());
    AdminTokens tokens() =>
        tester.element(find.byType(AppearancePicker)).adminTokens;
    expect(tokens(), irisTheme.tokens);

    await tester.tap(find.text('shadcn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(tokens(), shadcnTheme.dark);

    await tester.tap(_swatch('Teal'));
    await tester.pumpAndSettle();
    expect(tokens(), shadcnTheme.dark!.branded(_teal));
    expect(
      Theme.of(tester.element(find.byType(AppearancePicker))).brightness,
      Brightness.dark,
    );
  });
}
