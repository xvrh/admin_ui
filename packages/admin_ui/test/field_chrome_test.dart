import 'package:admin_ui/src/common/ui/field_chrome.dart';
import 'package:admin_ui/src/theme/field_style.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(FieldChrome),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('active draws the 1.5px focus-ring border', (tester) async {
    late Color ring;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            ring = context.colors.focusRing;
            return const FieldChrome(
              active: true,
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 40, height: 20),
            );
          },
        ),
      ),
    );
    final border = _decoration(tester).border! as Border;
    expect(border.top.width, 1.5);
    expect(border.top.color, ring);
  });

  testWidgets('resting border is the 1px control border', (tester) async {
    late Color outline;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            outline = context.colors.controlBorder;
            return const FieldChrome(
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 40, height: 20),
            );
          },
        ),
      ),
    );
    final border = _decoration(tester).border! as Border;
    expect(border.top.width, 1.0);
    expect(border.top.color, outline);
  });

  testWidgets('error border overrides active', (tester) async {
    late Color red;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            red = context.colors.danger;
            return const FieldChrome(
              active: true,
              invalid: true,
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 40, height: 20),
            );
          },
        ),
      ),
    );
    final border = _decoration(tester).border! as Border;
    expect(border.top.color, red);
    expect(border.top.width, 1.5);
  });

  testWidgets('every state matches the theme input outline', (tester) async {
    late AdminTokens tokens;
    final states = <(bool, bool, bool), Set<WidgetState>>{
      (true, false, false): {},
      (true, true, false): {WidgetState.focused},
      (true, false, true): {WidgetState.error},
      (false, false, false): {WidgetState.disabled},
    };
    for (final MapEntry(key: (enabled, active, error), value: set)
        in states.entries) {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              tokens = context.adminTokens;
              return FieldChrome(
                enabled: enabled,
                active: active,
                invalid: error,
                padding: const EdgeInsets.all(10),
                child: const SizedBox(width: 40, height: 20),
              );
            },
          ),
        ),
      );
      final input = WidgetStateProperty.resolveAs(
        buildInputDecorationTheme(tokens).border,
        set,
      )!;
      final side = (_decoration(tester).border! as Border).top;
      expect(side.color, input.borderSide.color, reason: '$set');
      expect(side.width, input.borderSide.width, reason: '$set');
    }
  });

  testWidgets('every anatomy draws its resolved chrome, at radiusField', (
    tester,
  ) async {
    for (final variant in FieldVariant.values) {
      final tokens = defaultTokens.copyWith(
        radii: defaultTokens.radii.copyWith(radiusField: 5),
        field: AdminFieldStyle(variant: variant),
      );
      for (final (active, hovered, invalid) in [
        (false, false, false),
        (false, true, false),
        (true, false, false),
        (false, false, true),
        (true, false, true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(tokens),
            home: Scaffold(
              body: Center(
                child: FieldChrome(
                  active: active,
                  hovered: hovered,
                  invalid: invalid,
                  padding: const EdgeInsets.all(10),
                  child: const SizedBox(width: 40, height: 20),
                ),
              ),
            ),
          ),
        );
        // Past the theme's change of anatomy.
        await tester.pumpAndSettle();
        final states = FieldState(invalid: invalid)
            .states(hovered: hovered, focused: active);
        final corners = BorderRadius.circular(5);
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FieldChrome),
            matching: find.byType(Container),
          ),
        );
        final reason = '${variant.name} $states';
        expect(
          container.decoration,
          fieldDecoration(tokens, states, corners),
          reason: reason,
        );
        // An outlined box keeps the plain BoxDecoration it always drew.
        if (variant == FieldVariant.outlined) {
          expect(container.decoration, isA<BoxDecoration>(), reason: reason);
        }
      }
    }
  });

  testWidgets('padding compensation keeps the box size constant', (
    tester,
  ) async {
    Size sizeFor(bool active) {
      return tester.getSize(find.byType(FieldChrome));
    }

    await tester.pumpWidget(
      _host(
        const FieldChrome(
          padding: EdgeInsets.all(10),
          child: SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final resting = sizeFor(false);

    await tester.pumpWidget(
      _host(
        const FieldChrome(
          active: true,
          padding: EdgeInsets.all(10),
          child: SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final active = sizeFor(true);

    expect(active, resting); // border thickened but content didn't shift
  });
}
