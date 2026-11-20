import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A strip with manual activation: the arrow keys, Home and End move focus
// and select nothing, and Enter or Space selects the focused tab.

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                TextButton(onPressed: () {}, child: const Text('After')),
              ],
            ),
          ),
        ),
      ),
    );

/// A strip that keeps its own selection, reporting every change.
class _Strip extends StatefulWidget {
  final TabsActivation? activation;
  final int initial;
  final List<int> changes;

  const _Strip({
    super.key,
    required this.changes,
    this.activation,
    this.initial = 0,
  });

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  late int _selected = widget.initial;

  void _select(int i) {
    widget.changes.add(i);
    setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) => switch (widget.activation) {
    null => Tabs(tabs: _five, selected: _selected, onChanged: _select),
    final activation => Tabs(
      tabs: _five,
      selected: _selected,
      onChanged: _select,
      activation: activation,
    ),
  };
}

const _five = [
  TabItem('Details'),
  TabItem('Pricing'),
  TabItem('Hidden', enabled: false),
  TabItem('SEO'),
  TabItem('Audit'),
];

/// The tab whose label is [label], as the node it announces as.
SemanticsNode _tab(WidgetTester tester, String label) => tester.getSemantics(
  find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Tappable)),
    matching: find.byType(GestureDetector),
  ),
);

bool _selected(WidgetTester tester, String label) =>
    _tab(tester, label).flagsCollection.isSelected.toBoolOrNull() ?? false;

/// Whether the tab labelled [label] draws its focus ring.
bool _ringed(WidgetTester tester, String label) => tester
    .widget<FocusRing>(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(Tappable),
        ),
        matching: find.byType(FocusRing),
      ),
    )
    .focused;

/// Whether keyboard focus sits on the control labelled [label].
bool _focused(WidgetTester tester, String label) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  var found = false;
  tester.element(find.text(label)).visitAncestorElements((e) {
    found = e == focus;
    return !found;
  });
  return found;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a strip selects as focus moves unless told otherwise', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(_host(_Strip(changes: changes)));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(changes, [1]);

    changes.clear();
    await tester.pumpWidget(
      _host(
        _Strip(
          key: UniqueKey(),
          changes: changes,
          activation: TabsActivation.automatic,
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(changes, [1]);
  });

  group('with manual activation', () {
    late List<int> changes;

    Future<void> pump(
      WidgetTester tester, {
      int initial = 0,
      TextDirection direction = TextDirection.ltr,
    }) async {
      changes = <int>[];
      await tester.pumpWidget(
        _host(
          _Strip(
            changes: changes,
            activation: TabsActivation.manual,
            initial: initial,
          ),
          direction: direction,
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
    }

    testWidgets('the arrows move focus and select nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(_focused(tester, 'Details'), isTrue);

      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'Pricing'), isTrue);
      // Over the disabled tab.
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'SEO'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester, 'Pricing'), isTrue);

      expect(changes, isEmpty);
      expect(_selected(tester, 'Details'), isTrue);
      expect(_selected(tester, 'Pricing'), isFalse);
      // The ring is on the focused tab, the selected one keeps its look.
      expect(_ringed(tester, 'Pricing'), isTrue);
      expect(_ringed(tester, 'Details'), isFalse);
      handle.dispose();
    });

    testWidgets('they wrap, and Home and End jump, selecting nothing', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester, 'Audit'), isTrue, reason: 'wraps to the end');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'Details'), isTrue, reason: 'and back');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester, 'Audit'), isTrue);
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester, 'Details'), isTrue);
      expect(changes, isEmpty);
    });

    testWidgets('they follow the reading direction right to left', (
      tester,
    ) async {
      await pump(tester, direction: TextDirection.rtl);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester, 'Pricing'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'Details'), isTrue);
      expect(changes, isEmpty);
    });

    testWidgets('Enter selects the focused tab', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.enter);

      expect(changes, [1]);
      expect(_selected(tester, 'Pricing'), isTrue);
      expect(_selected(tester, 'Details'), isFalse);
      expect(_focused(tester, 'Pricing'), isTrue);
      handle.dispose();
    });

    testWidgets('Space selects the focused tab', (tester) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.end);
      await _key(tester, LogicalKeyboardKey.space);
      expect(changes, [4]);
    });

    testWidgets('focus that leaves the strip comes back to the selected tab', (
      tester,
    ) async {
      await pump(tester, initial: 1);
      expect(_focused(tester, 'Pricing'), isTrue);
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester, 'Audit'), isTrue);

      // The strip is one stop: Tab goes on past it from wherever focus is.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, 'After'), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await _key(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(_focused(tester, 'Pricing'), isTrue);
      expect(changes, isEmpty);
    });

    testWidgets('a pointer selects the tab it presses', (tester) async {
      await pump(tester);
      await tester.tap(find.text('SEO'));
      await tester.pumpAndSettle();
      expect(changes, [3]);
    });
  });

  testWidgets('a strip whose host refuses the selection lets focus leave, and '
      'takes it back on the selected tab', (tester) async {
    // Automatic activation, and a host that keeps the first tab selected:
    // an unsaved form that will not be left, say.
    final asked = <int>[];
    await tester.pumpWidget(
      _host(Tabs(tabs: _five, selected: 0, onChanged: asked.add)),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(asked, [1]);
    expect(_focused(tester, 'Pricing'), isTrue);

    await _key(tester, LogicalKeyboardKey.tab);
    expect(tester.takeException(), isNull);
    expect(_focused(tester, 'After'), isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(_focused(tester, 'Details'), isTrue);
  });

  testWidgets('a keyed strip leaves its selection alone until Enter', (
    tester,
  ) async {
    final selection = TabSelection('details');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(
        Tabs.keyed(
          tabs: const {
            'details': TabItem('Details'),
            'history': TabItem('History'),
            'audit': TabItem('Audit'),
          },
          selection: selection,
          activation: TabsActivation.manual,
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(tester, 'Audit'), isTrue);
    expect(selection.active, 'details');

    await _key(tester, LogicalKeyboardKey.enter);
    expect(selection.active, 'audit');
  });
}
