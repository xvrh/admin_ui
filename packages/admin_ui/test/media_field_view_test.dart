import 'package:admin_ui/src/fields/ui/field_shell.dart';
import 'package:admin_ui/src/fields/ui/media_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MediaBody field', () {
    testWidgets('empty shows drop zone with browse affordance', (tester) async {
      await tester.pumpWidget(
        _wrap(const FieldShell(label: 'Gallery', child: MediaBody())),
      );
      expect(find.textContaining('Drag & drop'), findsOneWidget);
      expect(find.textContaining('browse'), findsOneWidget);
    });

    testWidgets('read-only empty shows no media, no drop zone', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(label: 'Gallery', child: MediaBody(readOnly: true)),
        ),
      );
      expect(find.text('No media'), findsOneWidget);
      expect(find.textContaining('Drag & drop'), findsNothing);
    });

    testWidgets('uploading image renders a progress bar with percent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Gallery',
            child: MediaBody(
              items: [
                MediaItem(
                  id: 'a',
                  name: 'a.jpg',
                  status: MediaStatus.uploading,
                  progress: 0.6,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('60%'), findsOneWidget);
      var bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.6);
    });

    testWidgets('a busy item offers to cancel its upload through onRemove', (
      tester,
    ) async {
      for (final kind in MediaKind.values) {
        String? removed;
        Widget body({ValueChanged<String>? onRemove}) => _wrap(
          FieldShell(
            label: 'Media',
            child: MediaBody(
              kind: kind,
              items: const [
                MediaItem(
                  id: 'a',
                  name: 'a.jpg',
                  status: MediaStatus.uploading,
                  progress: 0.3,
                ),
              ],
              onRemove: onRemove,
            ),
          ),
        );
        await tester.pumpWidget(body());
        expect(find.byIcon(Icons.close), findsNothing, reason: '$kind');

        await tester.pumpWidget(body(onRemove: (id) => removed = id));
        expect(
          find.bySemanticsLabel('Cancel upload of a.jpg'),
          findsOneWidget,
          reason: '$kind',
        );
        await tester.tap(find.byIcon(Icons.close));
        expect(removed, 'a', reason: '$kind');
      }
    });

    testWidgets('error item exposes retry', (tester) async {
      String? retried;
      await tester.pumpWidget(
        _wrap(
          FieldShell(
            label: 'Gallery',
            child: MediaBody(
              items: const [
                MediaItem(id: 'a', name: 'a.jpg', status: MediaStatus.error),
              ],
              onRetry: (id) => retried = id,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 'a');
    });

    testWidgets('remove fires for ready item', (tester) async {
      String? removed;
      await tester.pumpWidget(
        _wrap(
          FieldShell(
            label: 'Gallery',
            child: MediaBody(
              items: const [MediaItem(id: 'a', name: 'a.jpg')],
              onRemove: (id) => removed = id,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(removed, 'a');
    });

    testWidgets('remove works on a multi-item (draggable) grid', (
      tester,
    ) async {
      // 2+ items take the reorderable path where each tile is wrapped in a
      // Draggable — the close button must still receive taps.
      String? removed;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 600,
            child: FieldShell(
              label: 'Gallery',
              child: MediaBody(
                items: const [
                  MediaItem(id: 'a', name: 'a.jpg'),
                  MediaItem(id: 'b', name: 'b.jpg'),
                ],
                onRemove: (id) => removed = id,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.close).first);
      expect(removed, 'a');
    });

    testWidgets('file row shows name and size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Docs',
            child: MediaBody(
              kind: MediaKind.file,
              items: [MediaItem(id: 'a', name: 'press.pdf', bytes: 2_400_000)],
            ),
          ),
        ),
      );
      expect(find.text('press.pdf'), findsOneWidget);
      expect(find.text('2.4 MB'), findsOneWidget, reason: 'SI units');
    });

    testWidgets('add affordance hidden when single and filled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Cover',
            child: MediaBody(
              maxItems: 1,
              items: [MediaItem(id: 'a', name: 'a.jpg')],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('add affordance hidden at maxItems cap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Gallery',
            child: MediaBody(
              maxItems: 2,
              items: [
                MediaItem(id: 'a', name: 'a.jpg'),
                MediaItem(id: 'b', name: 'b.jpg'),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('field-level error renders under the body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Gallery',
            errorText: 'PNG only.',
            child: MediaBody(
              items: [MediaItem(id: 'a', name: 'a.jpg')],
            ),
          ),
        ),
      );
      expect(find.text('PNG only.'), findsOneWidget);
    });

    testWidgets('dragging a tile onto a later one reorders', (tester) async {
      int? from, to;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 600,
            child: FieldShell(
              label: 'Gallery',
              child: MediaBody(
                items: const [
                  MediaItem(id: 'a', name: 'a.jpg'),
                  MediaItem(id: 'b', name: 'b.jpg'),
                  MediaItem(id: 'c', name: 'c.jpg'),
                ],
                onReorder: (f, t) {
                  from = f;
                  to = t;
                },
              ),
            ),
          ),
        ),
      );

      var start = tester.getCenter(find.byKey(const ValueKey('a')));
      var target = tester.getCenter(find.byKey(const ValueKey('c')));
      var gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // 'a' dropped before 'c' → post-removal insert index 1.
      expect(from, 0);
      expect(to, 1);
    });

    testWidgets('a tile cannot be dropped into a different field', (
      tester,
    ) async {
      int? aTo, bTo;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              SizedBox(
                width: 600,
                child: FieldShell(
                  label: 'A',
                  child: MediaBody(
                    items: const [
                      MediaItem(id: 'a1', name: 'a1.jpg'),
                      MediaItem(id: 'a2', name: 'a2.jpg'),
                    ],
                    onReorder: (_, t) => aTo = t,
                  ),
                ),
              ),
              SizedBox(
                width: 600,
                child: FieldShell(
                  label: 'B',
                  child: MediaBody(
                    items: const [
                      MediaItem(id: 'b1', name: 'b1.jpg'),
                      MediaItem(id: 'b2', name: 'b2.jpg'),
                    ],
                    onReorder: (_, t) => bTo = t,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      var start = tester.getCenter(find.byKey(const ValueKey('a1')));
      var target = tester.getCenter(find.byKey(const ValueKey('b2')));
      var gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(aTo, isNull, reason: 'source field must not reorder');
      expect(bTo, isNull, reason: 'foreign field must reject the drop');
    });

    testWidgets('cover badge marks the first image', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FieldShell(
            label: 'Gallery',
            child: MediaBody(
              cover: true,
              items: [
                MediaItem(id: 'a', name: 'a.jpg'),
                MediaItem(id: 'b', name: 'b.jpg'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Cover'), findsOneWidget);
    });
  });
}
