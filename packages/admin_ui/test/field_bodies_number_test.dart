import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _p = irisPalette;
final _tokens = AdminTokens.from(palette: _p);

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(40),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

/// A [NumberBody] whose host keeps the value, like a form field does, and
/// records what the body reported.
class _Host extends StatefulWidget {
  final num? initial;
  final num? min;
  final num? max;
  final num step;
  final int decimals;
  final NumberAppearance appearance;

  /// Ignores a null, as a field over a required number does.
  final bool required;

  final List<num?> reported;
  final List<String?> invalid;

  const _Host({
    super.key,
    this.initial,
    this.min,
    this.max,
    this.step = 1,
    this.decimals = 0,
    this.appearance = NumberAppearance.plain,
    this.required = false,
    required this.reported,
    required this.invalid,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late num? value = widget.initial;

  void set(num? v) => setState(() => value = v);

  @override
  Widget build(BuildContext context) {
    return NumberBody(
      value: value,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      decimals: widget.decimals,
      appearance: widget.appearance,
      onInvalid: widget.invalid.add,
      onChanged: (v) {
        widget.reported.add(v);
        if (v == null && widget.required) return;
        setState(() => value = v);
      },
    );
  }
}

String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// The outline the field draws at rest.
Color _border(WidgetTester tester) {
  final border =
      tester.widget<TextField>(find.byType(TextField)).decoration!.border!
          as WidgetStateInputBorder;
  return border.resolve(const {}).borderSide.color;
}

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('range', () {
    testWidgets('a typed value above max is flagged, not reported, and '
        'clamped on blur', (tester) async {
      final reported = <num?>[];
      final invalid = <String?>[];
      await tester.pumpWidget(
        _host(
          _Host(
            initial: 480,
            min: 0,
            max: 1200,
            reported: reported,
            invalid: invalid,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '1400');
      await tester.pump();
      expect(reported, isEmpty, reason: 'out of range is not reported');
      expect(invalid.last, 'Enter a number from 0 to 1,200');
      expect(_border(tester), _p.danger);
      expect(_text(tester), '1400', reason: 'the typed text stays');

      await _blur(tester);
      expect(reported, [1200]);
      expect(_text(tester), '1,200', reason: 'shown in the locale');
      expect(invalid.last, isNull);
      expect(_border(tester), isNot(_p.danger));
    });

    testWidgets('a typed value below min clamps up on Enter', (tester) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 20, min: 10, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(reported, [10]);
      expect(_text(tester), '10');
    });

    testWidgets('an out-of-range value from the host is flagged and left '
        'alone when the field is only tabbed through', (tester) async {
      final reported = <num?>[];
      final invalid = <String?>[];
      await tester.pumpWidget(
        _host(
          _Host(initial: 1400, max: 1200, reported: reported, invalid: invalid),
        ),
      );
      await tester.pump();
      expect(invalid, ['Enter 1,200 or less']);
      expect(_border(tester), _p.danger);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await _blur(tester);
      expect(reported, isEmpty);
      expect(_text(tester), '1,400');
    });
  });

  group('minus sign', () {
    testWidgets('is refused anywhere but the start', (tester) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 1, min: -10, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '1-2');
      await tester.pump();
      expect(_text(tester), '1', reason: 'the edit is refused');

      await tester.enterText(find.byType(TextField), '-2');
      await tester.pump();
      expect(_text(tester), '-2');
    });

    testWidgets('is refused when min allows no negatives', (tester) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 3, min: 0, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '-3');
      await tester.pump();
      expect(_text(tester), '3');
      expect(reported, isEmpty);
    });

    testWidgets('a lone minus reverts to the value on blur', (tester) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 4, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '-');
      await tester.pump();
      await _blur(tester);
      expect(_text(tester), '4');
      expect(reported, isEmpty);
    });
  });

  group('empty', () {
    testWidgets('clearing reports null and keeps the field empty to retype', (
      tester,
    ) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 24, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(_text(tester), '', reason: 'no "0" reseeded');
      expect(reported, [null]);

      await tester.enterText(find.byType(TextField), '3');
      await tester.pump();
      expect(reported, [null, 3]);
      expect(_text(tester), '3');
    });

    testWidgets('an empty commit leaves an optional field empty', (
      tester,
    ) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(_Host(initial: 24, reported: reported, invalid: [])),
      );
      await tester.enterText(find.byType(TextField), '');
      await _blur(tester);
      expect(reported, [null]);
      expect(_text(tester), '');
    });

    testWidgets('a host that keeps its value shows it again after an empty '
        'commit, and the field stays empty while it is edited', (tester) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(
          _Host(initial: 24, required: true, reported: reported, invalid: []),
        ),
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(_text(tester), '');
      await _blur(tester);
      expect(reported, [null]);
      expect(_text(tester), '24');
    });
  });

  group('decimals', () {
    testWidgets('typing is not reformatted mid-keystroke; blur rounds', (
      tester,
    ) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(
          _Host(initial: 1.5, decimals: 2, reported: reported, invalid: []),
        ),
      );
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      expect(_text(tester), '2');
      expect(reported, [2]);

      await tester.enterText(find.byType(TextField), '2.456');
      await tester.pump();
      await _blur(tester);
      expect(_text(tester), '2.46');
      expect(reported.last, 2.46);
    });
  });

  group('keys', () {
    Future<List<num?>> pumpFocused(
      WidgetTester tester, {
      num initial = 5,
      num? min,
      num? max,
      num step = 1,
    }) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(
          _Host(
            initial: initial,
            min: min,
            max: max,
            step: step,
            reported: reported,
            invalid: [],
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      return reported;
    }

    testWidgets('ArrowUp and ArrowDown step by step', (tester) async {
      final reported = await pumpFocused(tester, step: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_text(tester), '7');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_text(tester), '3');
      expect(reported, [7, 5, 3]);
    });

    testWidgets('Shift+arrows and PageUp/PageDown step by ten steps', (
      tester,
    ) async {
      final reported = await pumpFocused(tester, initial: 50);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_text(tester), '60');
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(_text(tester), '40');
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(reported, [60, 50, 40, 50]);
    });

    testWidgets('steps clamp to the range', (tester) async {
      final reported = await pumpFocused(tester, initial: 11, max: 12);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(_text(tester), '12');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(reported, [12], reason: 'at the cap nothing more is reported');
    });

    testWidgets('a read-only field does not step', (tester) async {
      await tester.pumpWidget(_host(const NumberBody(value: 5)));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_text(tester), '5');
    });
  });

  group('stepper', () {
    testWidgets('the segments sit inside the field at the control height', (
      tester,
    ) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        _host(
          _Host(
            initial: 8,
            min: 0,
            max: 12,
            appearance: NumberAppearance.stepper,
            reported: reported,
            invalid: [],
          ),
        ),
      );
      final field = tester.getRect(find.byType(TextField));
      expect(field.height, _tokens.sizes.medium);
      final plus = tester.getRect(find.byIcon(Icons.add_rounded));
      final minus = tester.getRect(find.byIcon(Icons.remove_rounded));
      expect(field.contains(plus.center), isTrue);
      expect(field.contains(minus.center), isTrue);
      expect(plus.center.dy, field.center.dy);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(reported, [9]);
    });

    testWidgets('a read-only stepper shows no segments', (tester) async {
      await tester.pumpWidget(
        _host(const NumberBody(value: 8, appearance: NumberAppearance.stepper)),
      );
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });
  });

  testWidgets('the value reseeds when the host changes it', (tester) async {
    final key = GlobalKey<_HostState>();
    await tester.pumpWidget(
      _host(_Host(key: key, initial: 5, reported: [], invalid: [])),
    );
    key.currentState!.set(9);
    await tester.pump();
    expect(_text(tester), '9');
  });

  testWidgets('the prefix and unit are set in the value type', (tester) async {
    await tester.pumpWidget(
      _host(NumberBody(value: 5, prefix: r'$', unit: 'px', onChanged: (_) {})),
    );
    final prefix = tester.widget<Text>(find.text(r'$'));
    final unit = tester.widget<Text>(find.text('px'));
    expect(prefix.style!.fontSize, _tokens.typography.fieldText.fontSize);
    expect(unit.style!.fontSize, prefix.style!.fontSize);
    // The text starts after the prefix, which sits at the field's inset.
    final field = tester.getRect(find.byType(TextField));
    expect(
      tester.getTopLeft(find.text(r'$')).dx - field.left,
      _tokens.sizes.fieldPaddingX,
    );
  });
}
