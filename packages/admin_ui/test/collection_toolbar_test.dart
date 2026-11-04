import 'package:admin_ui/src/collection/ui/collection_toolbar.dart';
import 'package:admin_ui/src/common/ui/search_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 900, child: child)),
);

void main() {
  testWidgets('renders search, leading and trailing', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionToolbar(
          leading: const Text('12 products'),
          onSearch: (_) {},
          trailing: const [Text('New')],
        ),
      ),
    );
    expect(find.text('12 products'), findsOneWidget);
    expect(find.byType(SearchField), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('search routes through onSearch', (tester) async {
    String? typed;
    await tester.pumpWidget(
      _host(CollectionToolbar(onSearch: (v) => typed = v)),
    );
    await tester.enterText(find.byType(TextField), 'boots');
    expect(typed, 'boots');
  });

  testWidgets('omits the search field when onSearch is null', (tester) async {
    await tester.pumpWidget(_host(const CollectionToolbar(leading: Text('x'))));
    expect(find.byType(SearchField), findsNothing);
  });
}
