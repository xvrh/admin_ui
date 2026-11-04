// shadcn marks a focused field with a 3px halo of its ring at half strength
// outside the 1px border (`ring-[3px] ring-ring/50`), Ant with a 2px one of
// its primary (`activeShadow`); a theme with no halo draws none.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s tokens in the test font, so nothing is fetched.
AdminTokens _fontless(AdminTheme theme) {
  final tokens = theme.tokens;
  return tokens.copyWith(
    typography: AdminTypography.from(
      tokens.palette,
      AdminTypeSpec(ramp: tokens.typography.spec.ramp),
    ),
  );
}

AdminTokens _shadcn() => _fontless(shadcnTheme);

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: SizedBox(width: 300, child: child),
    ),
  ),
);

void main() {
  test('the halo follows focus, error and the theme', () {
    final tokens = _shadcn();
    final p = tokens.palette;
    final stroke = tokens.stroke;
    expect(
      fieldFocusHalo(p, {WidgetState.focused}, stroke: stroke),
      BorderSide(
        color: p.focusRing.withValues(alpha: 0.5),
        width: 3,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
    );
    expect(
      fieldFocusHalo(p, {
        WidgetState.focused,
        WidgetState.error,
      }, stroke: stroke).color,
      p.danger.withValues(alpha: 0.2),
    );
    expect(fieldFocusHalo(p, {}, stroke: stroke), BorderSide.none);
    expect(
      fieldFocusHalo(p, {WidgetState.focused}, stroke: const AdminStroke()),
      BorderSide.none,
    );
  });

  testWidgets('a focused shadcn input draws the halo outside its border', (
    tester,
  ) async {
    final tokens = _shadcn();
    final halo = tokens.palette.focusRing.withValues(alpha: 0.5);
    await tester.pumpWidget(
      _host(tokens, const InputField(value: '', hint: 'Title')),
    );
    final decorator = find.byType(InputDecorator);
    expect(decorator, isNot(paints..rrect(color: halo)));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      decorator,
      // The fill, then the halo under the border.
      paints
        ..rrect()
        ..rrect(color: halo, strokeWidth: 3, style: PaintingStyle.stroke),
    );
    // Outside the box: the halo's centre line is 1.5px beyond its edge.
    final box = tester.getRect(decorator);
    expect(
      decorator,
      paints
        ..rrect()
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            (Offset.zero & box.size).inflate(1.5),
            Radius.circular(tokens.radii.radiusField + 1.5),
          ),
          color: halo,
        ),
    );
  });

  testWidgets('an active FieldChrome draws it too, taking no room', (
    tester,
  ) async {
    final tokens = _shadcn();
    Future<Rect> pump({required bool active}) async {
      await tester.pumpWidget(
        _host(tokens, FieldChrome(active: active, child: const Text('Value'))),
      );
      return tester.getRect(find.byType(FieldChrome));
    }

    final rest = await pump(active: false);
    Container box() => tester.widget<Container>(
      find.descendant(
        of: find.byType(FieldChrome),
        matching: find.byType(Container),
      ),
    );
    expect(box().foregroundDecoration, isNull);

    final active = await pump(active: true);
    expect(active, rest);
    final border =
        (box().foregroundDecoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 3);
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
    expect(border.top.color, tokens.palette.focusRing.withValues(alpha: 0.5));
  });

  testWidgets('Ant draws its halo in the accent, at a fifth', (tester) async {
    final tokens = _fontless(antTheme);
    final p = tokens.palette;
    final halo = p.controlAccent.withValues(alpha: 0.2);
    expect(
      fieldFocusHalo(
        p,
        {WidgetState.focused},
        stroke: tokens.stroke,
        style: tokens.field,
      ),
      BorderSide(
        color: halo,
        width: 2,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
    );

    await tester.pumpWidget(
      _host(tokens, const InputField(value: '', hint: 'Title')),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      find.byType(InputDecorator),
      paints
        ..rrect()
        ..rrect(color: halo, strokeWidth: 2, style: PaintingStyle.stroke),
    );

    await tester.pumpWidget(
      _host(tokens, const FieldChrome(active: true, child: Text('Value'))),
    );
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(FieldChrome),
        matching: find.byType(Container),
      ),
    );
    final border =
        (box.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(
      border.top,
      BorderSide(
        color: halo,
        width: 2,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
    );
  });
}
