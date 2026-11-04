import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

typedef _Search = Future<List<ComboboxOption<String>>> Function(String query);

Widget _host(_Search search) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        // Wide enough that the failed-search message and its Retry button
        // share one line in the test font, whose glyphs are square.
        child: SizedBox(
          width: 480,
          child: Combobox<String>(
            value: null,
            onChanged: (_) {},
            onSearch: search,
          ),
        ),
      ),
    ),
  ),
);

/// The Combobox / open catalog page pins a search that is still running, one
/// that finds nothing and one that fails. Each dropdown is one message row,
/// not a panel stretched to the list's full height with the row centred in
/// it.
void main() {
  final cases = <String, (_Search, String)>{
    'still running': (
      (_) => Completer<List<ComboboxOption<String>>>().future,
      'Searching…',
    ),
    'finding nothing': ((_) async => const [], 'No results'),
    'failing': (
      (_) async => throw StateError('offline'),
      'Couldn’t load results',
    ),
  };
  for (final MapEntry(key: name, value: (search, text)) in cases.entries) {
    testWidgets('a search $name opens a one-row dropdown', (tester) async {
      await tester.pumpWidget(_host(search));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(text), findsOneWidget);

      final surface = tester.getSize(find.byType(PopoverMenuSurface));
      final row = tester.getSize(
        find
            .ancestor(of: find.text(text), matching: find.byType(Container))
            .first,
      );
      final context = tester.element(find.text(text));
      expect(row.height, context.sizes.medium + 2 * AdminSpacing.xs);
      // The row, the surface's padding and its hairline, nothing more.
      expect(surface.height, lessThan(row.height + 2 * AdminSpacing.md));
    });
  }
}
