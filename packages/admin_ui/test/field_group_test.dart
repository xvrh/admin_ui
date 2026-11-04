import 'package:admin_ui/src/fields/ui/field_group.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders title, description and children', (tester) async {
    await tester.pumpWidget(
      _host(
        const FieldGroup(
          title: 'Content',
          description: 'The main body.',
          children: [Text('field-a'), Text('field-b')],
        ),
      ),
    );

    expect(find.text('Content'), findsOneWidget);
    expect(find.text('The main body.'), findsOneWidget);
    expect(find.text('field-a'), findsOneWidget);
    expect(find.text('field-b'), findsOneWidget);
  });

  testWidgets('non-collapsible has no toggle and shows the body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const FieldGroup(title: 'X', children: [Text('field')])),
    );

    expect(find.byType(InkWell), findsNothing);
    expect(find.text('field'), findsOneWidget);
  });

  testWidgets('collapsible starts collapsed and toggles open', (tester) async {
    await tester.pumpWidget(
      _host(
        const FieldGroup(
          title: 'Advanced',
          collapsible: true,
          initiallyExpanded: false,
          children: [Text('hidden-field')],
        ),
      ),
    );

    expect(find.text('hidden-field'), findsNothing);

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(find.text('hidden-field'), findsOneWidget);
  });

  testWidgets('boxed draws a Panel', (tester) async {
    await tester.pumpWidget(
      _host(
        const FieldGroup(
          title: 'Pricing',
          boxed: true,
          children: [Text('price')],
        ),
      ),
    );

    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('price'), findsOneWidget);
  });

  testWidgets('the collapse takes the theme\'s medium motion', (tester) async {
    await tester.pumpWidget(
      _host(
        const FieldGroup(
          title: 'Advanced',
          collapsible: true,
          children: [Text('field')],
        ),
      ),
    );

    final size = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
    expect(size.duration, defaultMotion.medium);
    expect(size.curve, defaultMotion.standard);
    final chevron = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(chevron.duration, defaultMotion.fast);
  });

  testWidgets('with reduced motion the body shows and hides at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: FieldGroup(
                title: 'Advanced',
                collapsible: true,
                children: [Text('field')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedSize), findsNothing);
    await tester.tap(find.text('Advanced'));
    await tester.pump();
    expect(find.text('field'), findsNothing);
    expect(
      tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
      Duration.zero,
    );
  });
}
