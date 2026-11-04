import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/load_state_area.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] at [scale] times the platform's text size, overlays included.
Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

/// Whether every line of [text] fits the box it was given: a box too short
/// for them clips the rest.
bool _fits(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final lines = paragraph.getMaxIntrinsicHeight(paragraph.size.width + 1);
  return paragraph.size.height >= lines - 0.5;
}

double _heightOf(WidgetTester tester, String text, Type ancestor) => tester
    .getSize(
      find.ancestor(of: find.text(text), matching: find.byType(ancestor)).first,
    )
    .height;

void main() {
  testWidgets('textGrowthOf is nothing at the normal size, and how much a '
      'line grows at a larger one', (tester) async {
    final growth = <double, double>{};
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          scale: scale,
          Builder(
            builder: (context) {
              growth[scale] = textGrowthOf(context, context.type.body);
              return const SizedBox();
            },
          ),
        ),
      );
    }
    expect(growth[1], 0);
    expect(growth[2], greaterThan(0));
  });

  testWidgets(
    'calendar week rows grow with the day numbers',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      final pitch = <double, double>{};
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          _host(
            scale: scale,
            SizedBox(
              // Wide enough for two of the test font's square digits.
              width: 480,
              child: Calendar(today: DateTime(2026, 6, 12), onChanged: (_) {}),
            ),
          ),
        );
        // A week apart, and each once in the grid (May 31 to July 11).
        pitch[scale] =
            tester.getCenter(find.text('22')).dy -
            tester.getCenter(find.text('15')).dy;
        expect(_fits(tester, '15'), isTrue, reason: 'at x$scale');
      }
      expect(pitch[1], 36);
      expect(pitch[2], greaterThan(36));
    },
  );

  testWidgets('sidebar items grow with their labels', (tester) async {
    final height = <double, double>{};
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          scale: scale,
          Row(
            children: [
              Sidebar(
                entries: [
                  NavItem(
                    'Pages',
                    icon: Icons.description_outlined,
                    selected: true,
                    badge: '3',
                    onTap: () {},
                  ),
                ],
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      height[scale] = _heightOf(tester, 'Pages', Tappable);
      expect(_fits(tester, 'Pages'), isTrue, reason: 'at x$scale');
      expect(_fits(tester, '3'), isTrue, reason: 'at x$scale');
    }
    expect(height[1], 36);
    expect(height[2], greaterThan(36));
  });

  testWidgets('a labelled button grows with its label, and a split button '
      'keeps its caret as tall as its action', (tester) async {
    final height = <double, double>{};
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          scale: scale,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button('Save', onPressed: () {}),
              SplitButton(
                label: 'Publish',
                onPressed: () {},
                menuSemanticLabel: 'More',
                entries: [MenuItem('Schedule', onSelect: () {})],
              ),
            ],
          ),
        ),
      );
      height[scale] = _heightOf(tester, 'Save', InkWell);
      expect(_fits(tester, 'Save'), isTrue, reason: 'at x$scale');
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.byIcon(Icons.keyboard_arrow_down_rounded),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        _heightOf(tester, 'Publish', InkWell),
        reason: 'at x$scale',
      );
    }
    expect(height[1], defaultTokens.sizes.medium);
    expect(height[2], greaterThan(defaultTokens.sizes.medium));
  });

  testWidgets('an open date range picker scrolls rather than overflows at '
      'twice the size', (tester) async {
    await tester.pumpWidget(
      _host(
        scale: 2,
        SizedBox(
          width: 320,
          child: DateRangePicker(
            today: DateTime(2026, 6, 12),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DateRangePicker));
    await tester.pumpAndSettle();
    expect(find.byType(Calendar), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(
        of: find.byType(Calendar),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an asset library error scrolls in a short pane at twice the '
      'size, and stays centred in a tall one', (tester) async {
    Widget library(double height) => SizedBox(
      width: 480,
      height: height,
      child: AssetLibrary(assets: const [], error: 'boom', onRetry: () {}),
    );
    await tester.pumpWidget(_host(scale: 2, library(260)));
    expect(tester.takeException(), isNull);
    expect(find.text('Retry'), findsOneWidget);

    await tester.pumpWidget(_host(library(700)));
    final body = tester.getRect(find.byType(LoadStateArea));
    final state = tester.getRect(find.byType(ErrorState));
    expect(state.center.dy, moreOrLessEquals(body.center.dy, epsilon: 0.5));
  });

  testWidgets('table rows and the header grow with the text, and a cell too '
      'long for its column ellipsizes on one line', (tester) async {
    final pitch = <double, double>{};
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _host(
          scale: scale,
          SizedBox(
            width: 400,
            height: 600,
            child: CollectionTable<String>(
              rows: const ['Alpha', 'Bravo'],
              columns: [
                TableColumn(label: 'Name', cell: (r) => Text(r)),
                TableColumn(
                  label: 'Note',
                  fixed: 90,
                  cell: (r) => Text('$r has a note far wider than its column'),
                ),
              ],
            ),
          ),
        ),
      );
      pitch[scale] =
          tester.getCenter(find.text('Bravo')).dy -
          tester.getCenter(find.text('Alpha')).dy;
      final note = tester.renderObject<RenderParagraph>(
        find.text('Alpha has a note far wider than its column'),
      );
      expect(note.maxLines, 1);
      expect(note.overflow, TextOverflow.ellipsis);
      expect(_fits(tester, 'Alpha'), isTrue, reason: 'at x$scale');
      expect(_fits(tester, 'Name'), isTrue, reason: 'at x$scale');
    }
    expect(pitch[2], greaterThan(pitch[1]!));
  });

  testWidgets('a missing asset tile names it in the lines it has room for', (
    tester,
  ) async {
    const name = 'quarterly-report-final-draft.pdf';
    for (final scale in [1.0, 2.0, 3.0]) {
      await tester.pumpWidget(
        _host(
          scale: scale,
          const SizedBox(
            width: 400,
            child: MediaBody(
              items: [
                MediaItem(
                  id: 'a',
                  name: name,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'at x$scale');
    }
  });

  testWidgets('initials and glyphs on marks of fixed size keep their size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        scale: 2,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: 'Jane Doe'),
            HelpButton(text: 'What this field is for'),
          ],
        ),
      ),
    );
    for (final text in ['JD', '?']) {
      expect(
        tester.renderObject<RenderParagraph>(find.text(text)).textScaler,
        TextScaler.noScaling,
      );
    }
  });
}
