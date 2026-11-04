import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source]'s ramp and geometry in the platform's font.
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
    sizes: source.sizes,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
  );
}

const _next = Key('next field');

Widget _field({
  required AdminTokens tokens,
  String? errorText,
  bool reserve = true,
  double textScale = 1,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SizedBox(
        width: 320,
        // A form: the next field sits right below.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Title',
              errorText: errorText,
              reserveErrorLine: reserve,
              child: const InputField(value: 'Hello'),
            ),
            const SizedBox(key: _next, height: 10),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  for (final theme in adminThemes) {
    final tokens = _fontless(theme.tokens);
    for (final scale in [1.0, 1.5]) {
      testWidgets('${theme.name} at ${scale}x: an error takes the reserved '
          'line', (tester) async {
        Future<double> height({String? errorText, bool reserve = true}) async {
          await tester.pumpWidget(
            _field(
              tokens: tokens,
              errorText: errorText,
              reserve: reserve,
              textScale: scale,
            ),
          );
          return tester.getTopLeft(find.byKey(_next)).dy;
        }

        final reserved = await height();
        final withError = await height(errorText: 'Enter a title');
        expect(withError, reserved, reason: 'the next field does not move');
        expect(
          find.text('Enter a title'),
          findsOneWidget,
          reason: 'the message shows in the reserved room',
        );
        expect(
          await height(reserve: false),
          lessThan(reserved),
          reason: 'without the reserve, the error line is new room',
        );
      });
    }
  }

  testWidgets('the reserve is not read out', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_field(tokens: defaultTokens));
    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.hint, isEmpty);
    semantics.dispose();
  });
}
