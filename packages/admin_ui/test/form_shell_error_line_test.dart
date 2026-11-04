import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source]'s ramp, geometry and anatomy in the platform's font.
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
    field: source.field,
  );
}

const _next = Key('next field');

Widget _form({
  required AdminTokens tokens,
  required Widget field,
  bool reserve = true,
  Set<String> pending = const {},
  double textScale = 1,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: Scaffold(
      body: FieldFeedbackScope(
        reserveErrorLine: reserve,
        pending: pending,
        child: SizedBox(
          width: 320,
          // A form: the next field sits right below.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(key: _next, height: 10),
            ],
          ),
        ),
      ),
    ),
  ),
);

FieldShell _shell({
  String? errorText,
  String? warning,
  bool? reserveErrorLine,
}) => FieldShell(
  label: 'Title',
  fieldId: 'title',
  errorText: errorText,
  warning: warning,
  reserveErrorLine: reserveErrorLine,
  child: const InputField(value: 'Hello'),
);

void main() {
  for (final theme in adminThemes) {
    final tokens = _fontless(theme.tokens);
    for (final scale in [1.0, 1.5]) {
      testWidgets('${theme.name} at ${scale}x: a FieldShell message takes the '
          'reserved line, and so does a pending check', (tester) async {
        Future<double> nextTop(
          Widget field, {
          bool reserve = true,
          Set<String> pending = const {},
        }) async {
          await tester.pumpWidget(
            _form(
              tokens: tokens,
              field: field,
              reserve: reserve,
              pending: pending,
              textScale: scale,
            ),
          );
          return tester.getTopLeft(find.byKey(_next)).dy;
        }

        final reserved = await nextTop(_shell());
        expect(
          await nextTop(_shell(errorText: 'Enter a title')),
          reserved,
          reason: 'the next field does not move for an error',
        );
        expect(find.text('Enter a title'), findsOneWidget);
        expect(
          await nextTop(_shell(warning: 'Looks long')),
          reserved,
          reason: 'nor for a warning',
        );
        expect(
          await nextTop(_shell(), pending: {'title'}),
          reserved,
          reason: 'nor for a check under way',
        );
        expect(find.text('Checking…'), findsOneWidget);
        expect(
          await nextTop(_shell(), reserve: false),
          lessThan(reserved),
          reason: 'without the reserve, the message line is new room',
        );
        expect(
          await nextTop(_shell(reserveErrorLine: false)),
          lessThan(reserved),
          reason: "the field's own setting wins over the scope's",
        );
      });
    }
  }

  testWidgets('outside a feedback scope neither field reserves', (
    tester,
  ) async {
    Future<double> nextTop(Widget field) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(key: _next, height: 10),
                ],
              ),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(_next)).dy;
    }

    final bare = await nextTop(_shell());
    expect(await nextTop(_shell(reserveErrorLine: true)), greaterThan(bare));

    const labeled = LabeledField(
      label: 'Title',
      child: InputField(value: ''),
    );
    final labeledBare = await nextTop(labeled);
    await tester.pumpWidget(_form(tokens: defaultTokens, field: labeled));
    expect(
      tester.getTopLeft(find.byKey(_next)).dy,
      greaterThan(labeledBare),
      reason: 'a LabeledField follows the scope too',
    );
  });

  testWidgets('an error wins over a pending check', (tester) async {
    await tester.pumpWidget(
      _form(
        tokens: defaultTokens,
        field: _shell(errorText: 'Taken'),
        pending: {'title'},
      ),
    );
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Checking…'), findsNothing);
    expect(find.byType(Spinner), findsNothing);
  });

  testWidgets('a pending check is only its own field’s', (tester) async {
    await tester.pumpWidget(
      _form(tokens: defaultTokens, field: _shell(), pending: {'slug'}),
    );
    expect(find.text('Checking…'), findsNothing);
  });

  testWidgets('the pending line is announced, the reserve is not', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _form(tokens: defaultTokens, field: _shell(), pending: {'title'}),
    );
    final line = tester.getSemantics(find.text('Checking…'));
    expect(line, isSemantics(isLiveRegion: true));
    expect(
      find.bySemanticsLabel('Loading'),
      findsNothing,
      reason: 'the spinner does not announce itself over the line',
    );

    await tester.pumpWidget(_form(tokens: defaultTokens, field: _shell()));
    final body = tester.getSemantics(find.byType(EditableText));
    expect(body.hint, isEmpty);
    semantics.dispose();
  });

  test('the pending line reads at 4.5:1 on the page and a boxed group', () {
    for (final theme in adminThemes) {
      for (final tokens in [theme.tokens, theme.dark!]) {
        final c = tokens.palette;
        for (final ground in [c.background, c.surface]) {
          expect(
            contrastRatio(c.foregroundMuted, ground),
            greaterThanOrEqualTo(4.5),
            reason: theme.name,
          );
        }
      }
    }
  });

  testWidgets('with animations off the pending spinner holds still', (
    tester,
  ) async {
    await tester.pumpWidget(
      _form(
        tokens: defaultTokens,
        field: _shell(),
        pending: {'title'},
        disableAnimations: true,
      ),
    );
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, isNotNull);
  });
}
