import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A listbox builds its rows as they scroll into view, so it takes the width
// it is given and cannot say how wide it would like to be. Asked, it says so
// in its own words, with what to pass instead.

const _labels = ['Apple', 'Banana', 'Cherry'];

Widget _listbox(ListboxController controller) => Listbox(
  controller: controller,
  itemCount: _labels.length,
  itemBuilder: (context, i) => ListboxOption(
    controller: controller,
    index: i,
    label: _labels[i],
    onTap: () {},
  ),
);

ListboxController _controller() {
  final controller = ListboxController()
    ..reset(_labels.length, labelOf: (i) => _labels[i]);
  addTearDown(controller.dispose);
  return controller;
}

/// Pumps [child] and returns every error the frames raised, in order.
Future<List<FlutterErrorDetails>> _pump(
  WidgetTester tester,
  Widget child,
) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );
    // The frame after: where the list scrolls its highlight into view.
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  group('a listbox on something sized to its content', () {
    for (final (name, wrap) in <(String, Widget Function(Widget))>[
      (
        'a menu surface with no width',
        (list) => PopoverMenuSurface(child: list),
      ),
      (
        'a menu surface between two widths',
        (list) => PopoverMenuSurface(minWidth: 160, maxWidth: 320, child: list),
      ),
      (
        'an IntrinsicWidth of the app\'s',
        (list) => IntrinsicWidth(child: list),
      ),
    ]) {
      testWidgets('$name: says it cannot be measured, and what to pass', (
        tester,
      ) async {
        final errors = await _pump(tester, wrap(_listbox(_controller())));
        expect(errors, isNotEmpty);
        final first = errors.first.exception;
        expect(first, isA<FlutterError>());
        final text = first.toString();
        expect(text, contains('A Listbox cannot say how wide'));
        expect(text, contains('PopoverMenuSurface with no width'));
        expect(text, contains('PopoverController.anchorWidth'));
        expect(text, contains('ListboxOption.widthOf'));
        expect(text, contains('ListboxMenu'));
        // Not the viewport's words, which name neither widget.
        expect(text, isNot(contains('RenderShrinkWrappingViewport')));
      });
    }

    testWidgets('raises nothing of its own after that', (tester) async {
      final errors = await _pump(
        tester,
        PopoverMenuSurface(child: _listbox(_controller())),
      );
      expect(errors, isNotEmpty);
      // The list that was never laid out does not try to scroll.
      expect(
        errors.where((e) => '${e.stack}'.contains('_ListboxState')),
        isEmpty,
      );
      expect(
        errors.where((e) => '${e.exception}'.contains('Null check')),
        isEmpty,
      );
    });
  });

  group('a listbox given a width', () {
    testWidgets('on a menu surface with one is that wide, its rows across '
        'it', (tester) async {
      final errors = await _pump(
        tester,
        PopoverMenuSurface(width: 240, child: _listbox(_controller())),
      );
      expect(errors, isEmpty);
      expect(tester.getSize(find.byType(Listbox)).width, 240);
      for (final row in tester.widgetList(find.byType(ListboxOption))) {
        expect(
          tester.getSize(find.byWidget(row)).width,
          240 - 2 * AdminSpacing.xs,
        );
      }
      expect(find.byType(ListboxOption), findsNWidgets(_labels.length));
    });

    testWidgets('as wide as its widest row, measured, shows every label on '
        'one line', (tester) async {
      final controller = _controller();
      final errors = await _pump(
        tester,
        Builder(
          builder: (context) => PopoverMenuSurface(
            width:
                [
                  for (final label in _labels)
                    ListboxOption.widthOf(context, label: label),
                ].reduce((a, b) => a > b ? a : b) +
                2 * AdminSpacing.xs,
            child: _listbox(controller),
          ),
        ),
      );
      expect(errors, isEmpty);
      final line = tester.getSize(find.text('Apple')).height;
      for (final label in _labels) {
        expect(tester.getSize(find.text(label)).height, line, reason: label);
      }
    });

    testWidgets('asked directly for its least or its most width, says the '
        'same', (tester) async {
      final errors = await _pump(
        tester,
        SizedBox(width: 240, child: _listbox(_controller())),
      );
      expect(errors, isEmpty);
      final box = tester.renderObject<RenderBox>(find.byType(Listbox));
      final refuses = throwsA(
        isA<FlutterError>().having(
          (e) => e.toString(),
          'message',
          contains('A Listbox cannot say how wide'),
        ),
      );
      expect(() => box.getMinIntrinsicWidth(double.infinity), refuses);
      expect(() => box.getMaxIntrinsicWidth(double.infinity), refuses);
    });

    testWidgets('passes a check of intrinsic sizes', (tester) async {
      debugCheckIntrinsicSizes = true;
      try {
        final errors = await _pump(
          tester,
          PopoverMenuSurface(width: 240, child: _listbox(_controller())),
        );
        expect(errors, isEmpty);
        expect(tester.getSize(find.byType(Listbox)).width, 240);
      } finally {
        // Here and not in a tear-down: the oldest Flutter the kit builds on
        // checks the debug variables as the body ends, before any runs.
        debugCheckIntrinsicSizes = false;
      }
    });
  });

  testWidgets('a menu surface sized to rows it can measure is as wide as the '
      'widest', (tester) async {
    final errors = await _pump(
      tester,
      const PopoverMenuSurface(
        minWidth: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, height: 20),
            SizedBox(width: 130, height: 20),
          ],
        ),
      ),
    );
    expect(errors, isEmpty);
    expect(tester.getSize(find.byType(Column)).width, 130);
  });
}
