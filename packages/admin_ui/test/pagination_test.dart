import 'package:admin_ui/src/common/ui/pagination.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('pagesFor collapses long ranges with ellipsis sentinels', () {
    expect(Pagination.pagesFor(1, 5), [1, 2, 3, 4, 5]);
    expect(Pagination.pagesFor(8, 42), [1, null, 7, 8, 9, null, 42]);
    expect(Pagination.pagesFor(1, 42), [1, 2, null, 42]);
    expect(Pagination.pagesFor(42, 42), [1, null, 41, 42]);
    expect(Pagination.pagesFor(1, 1), [1]);
  });

  testWidgets('tapping a page number reports it', (tester) async {
    int? picked;
    await tester.pumpWidget(
      _host(Pagination(page: 2, pageCount: 5, onChanged: (p) => picked = p)),
    );

    await tester.tap(find.text('4'));
    expect(picked, 4);
  });

  testWidgets('prev is disabled on the first page', (tester) async {
    int? picked;
    await tester.pumpWidget(
      _host(Pagination(page: 1, pageCount: 5, onChanged: (p) => picked = p)),
    );

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    expect(picked, isNull);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    expect(picked, 2);
  });
}
