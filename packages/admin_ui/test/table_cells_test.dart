import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// [theme]'s palette, radii, sizes and table metrics, without its font.
AdminTokens _tokens(AdminTheme theme, {bool dark = false}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
  );
}

Future<void> _pump(WidgetTester tester, Widget child, {AdminTokens? tokens}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens ?? defaultTokens),
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

/// A solid [size] × [size] PNG.
Future<Uint8List> _png(int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// A provider whose load fails, as a dead URL would.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback _) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('no such image')),
      );
}

/// The text colour [finder]'s paragraph paints.
Color _textColor(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style!.color!;

void main() {
  group('TableThumb', () {
    testWidgets('draws its image at its size, rounded by the theme', (
      tester,
    ) async {
      final png = (await tester.runAsync(() => _png(64)))!;
      for (final theme in [irisTheme, carbonTheme, fluentTheme]) {
        final tokens = _tokens(theme);
        await _pump(
          tester,
          TableThumb(image: MemoryImage(png)),
          tokens: tokens,
        );
        final thumb = find.byType(TableThumb);
        expect(tester.getSize(thumb), const Size(32, 32));
        final image = tester.widget<ThumbnailImage>(
          find.byType(ThumbnailImage),
        );
        final radius = BorderRadius.circular(tokens.radii.radiusSmall);
        expect(image.borderRadius, radius, reason: theme.name);
        final box = tester.widget<Container>(
          find.descendant(of: thumb, matching: find.byType(Container)).first,
        );
        expect(
          (box.foregroundDecoration! as BoxDecoration).borderRadius,
          radius,
          reason: '${theme.name}: the edge follows the corner',
        );
      }
    });

    testWidgets('a picture that fails to load shows the broken-image glyph', (
      tester,
    ) async {
      await _pump(tester, const TableThumb(image: _BrokenImage()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(tester.getSize(find.byType(TableThumb)), const Size(32, 32));
    });

    testWidgets('without an image, a swatch or a placeholder glyph', (
      tester,
    ) async {
      await _pump(tester, const TableThumb(color: Color(0xFFCC3366)));
      expect(find.byType(Icon), findsNothing);
      await _pump(tester, const TableThumb(icon: Icons.description_outlined));
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });
  });

  group('TableIdentity', () {
    Widget identity() => const TableIdentity(
      leading: TableThumb(color: Color(0xFF5B5BD6)),
      title: 'Aurora Wool Coat',
      subtitle: 'SKU-6Y0',
    );

    testWidgets('fits a compact Fluent row on one line', (tester) async {
      final tokens = _tokens(fluentTheme);
      final row = tokens.table.rowHeight(TableDensity.compact);
      expect(row, 32);
      await _pump(
        tester,
        SizedBox(
          width: 600,
          height: 240,
          child: CollectionTable<int>(
            rows: const [1, 2],
            density: TableDensity.compact,
            columns: [TableColumn(label: 'Product', cell: (_) => identity())],
          ),
        ),
        tokens: tokens,
      );
      expect(tester.takeException(), isNull, reason: 'no overflow');
      // One line: the title and the SKU share a paragraph.
      expect(find.text('Aurora Wool Coat'), findsNothing);
      expect(find.text('Aurora Wool Coat  SKU-6Y0'), findsNWidgets(2));
      final cell = tester.getRect(find.byType(TableIdentity).first);
      final thumb = tester.getRect(find.byType(TableThumb).first);
      expect(thumb.height, lessThanOrEqualTo(row - 8));
      expect(thumb.top, greaterThanOrEqualTo(cell.top));
      expect(thumb.bottom, lessThanOrEqualTo(cell.bottom));
    });

    testWidgets('takes two lines where the row has room', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 600,
          height: 240,
          child: CollectionTable<int>(
            rows: const [1],
            columns: [TableColumn(label: 'Product', cell: (_) => identity())],
          ),
        ),
      );
      expect(find.text('Aurora Wool Coat'), findsOneWidget);
      expect(find.text('SKU-6Y0'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('SKU-6Y0')).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.text('Aurora Wool Coat')).dy,
        ),
      );
    });
  });

  group('text on every row fill', () {
    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      testWidgets(name, (tester) async {
        await _pump(
          tester,
          const Column(
            children: [
              RelationChip(label: 'Outerwear'),
              RelationChip(label: 'Linked', onTap: _noop),
              LocaleRollup(
                locales: {
                  'en': LocaleStatus.source,
                  'fr': LocaleStatus.translated,
                  'de': LocaleStatus.review,
                  'es': LocaleStatus.outdated,
                  'it': null,
                },
              ),
            ],
          ),
          tokens: AdminTokens.from(palette: palette),
        );
        // A chip carries its own fill.
        for (final label in ['Outerwear', 'Linked']) {
          expect(
            contrastRatio(
              _textColor(tester, find.text(label)),
              palette.background,
            ),
            greaterThanOrEqualTo(4.5),
            reason: label,
          );
        }
        // A locale pill is only an outline: its code reads on the row.
        final fills = {
          'page': palette.surface,
          'stripe': palette.tableRowStripe,
          'hovered stripe': Color.alphaBlend(
            palette.tableRowHover,
            palette.tableRowStripe,
          ),
          'selected': palette.tableRowSelected,
          'selected, hovered': palette.tableRowSelectedHover,
        };
        for (final code in ['EN', 'FR', 'DE', 'ES', 'IT']) {
          final color = _textColor(tester, find.text(code));
          for (final MapEntry(key: fill, value: surface) in fills.entries) {
            expect(
              contrastRatio(color, surface),
              greaterThanOrEqualTo(4.5),
              reason: '$code on the $fill fill',
            );
          }
        }
      });
    }
  });

  group('MatchCell', () {
    testWidgets('highlights the matched term in a snippet', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: MatchCell(
            matchField: 'Body',
            snippet: '…a warm wool coat for winter…',
            highlights: [8, 12],
          ),
        ),
      );
      final text = tester.widget<HighlightedText>(find.byType(HighlightedText));
      expect(text.ranges, [8, 12]);
      final spans = <TextSpan>[];
      tester
          .renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(HighlightedText),
              matching: find.byType(RichText),
            ),
          )
          .text
          .visitChildren((span) {
            if (span is TextSpan && span.text != null) spans.add(span);
            return true;
          });
      final marked = spans.where((s) => s.style?.fontWeight == FontWeight.w700);
      expect(marked.map((s) => s.text), ['wool']);
      expect(marked.single.style!.color, defaultTokens.palette.primaryText);
    });

    testWidgets('names the field of a title match, or shows nothing', (
      tester,
    ) async {
      await _pump(tester, const MatchCell(matchField: 'Name'));
      // The label as given: lowercasing it would break German nouns.
      expect(find.text('Matched: Name'), findsOneWidget);
      await _pump(tester, const MatchCell());
      expect(find.byType(Text), findsNothing);
    });
  });
}

void _noop() {}
