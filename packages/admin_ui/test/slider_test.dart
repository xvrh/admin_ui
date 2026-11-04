import 'package:admin_ui/src/common/ui/slider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  testWidgets('dragging the thumb reports a new value', (tester) async {
    double value = 0.5;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => ValueSlider(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pump();
    expect(value, lessThan(0.5));
  });

  testWidgets('format drives the readout', (tester) async {
    await tester.pumpWidget(
      _host(
        ValueSlider(
          value: 0.4,
          onChanged: (_) {},
          format: (x) => '${(x * 100).round()}%',
        ),
      ),
    );

    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('read-only slider has no onChanged', (tester) async {
    await tester.pumpWidget(
      _host(const ValueSlider(value: 0.6, onChanged: null)),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('screen readers hear the readout text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        ValueSlider(value: 3, min: 1, max: 10, divisions: 9, onChanged: (_) {}),
      ),
    );
    expect(find.semantics.byValue('3'), findsOne);
    expect(find.semantics.byValue(RegExp('%')), findsNothing);
    handle.dispose();
  });

  testWidgets('the default format follows the locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: const [Locale('de'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: ValueSlider(value: 0.25, onChanged: (_) {}),
          ),
        ),
      ),
    );
    expect(find.text('0,25'), findsOneWidget);
  });

  testWidgets('the drag bubble shows for a continuous slider', (tester) async {
    await tester.pumpWidget(_host(ValueSlider(value: 0.5, onChanged: (_) {})));
    final theme = SliderTheme.of(tester.element(find.byType(Slider)));
    expect(theme.showValueIndicator, ShowValueIndicator.onDrag);
  });
}
