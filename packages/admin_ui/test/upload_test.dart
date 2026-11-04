import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/common/ui/upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

/// The row action labelled [label].
Finder _action(String label) =>
    find.byWidgetPredicate((w) => w is IconAction && w.label == label);

void main() {
  testWidgets('empty zone shows the drop target, no queue', (tester) async {
    await tester.pumpWidget(
      _host(const UploadZone(accept: 'PNG, JPG · up to 10 MB')),
    );
    expect(find.textContaining('browse'), findsOneWidget);
    expect(find.text('PNG, JPG · up to 10 MB'), findsOneWidget);
  });

  testWidgets('onBrowse fires when the target is tapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(UploadZone(onBrowse: () => tapped++)));
    await tester.tap(find.byIcon(Icons.cloud_upload_outlined));
    expect(tapped, 1);
  });

  testWidgets('queue header summarises progress', (tester) async {
    await tester.pumpWidget(
      _host(
        const UploadZone(
          items: [
            UploadItem(id: 'a', name: 'a.jpg', status: UploadStatus.done),
            UploadItem(
              id: 'b',
              name: 'b.jpg',
              status: UploadStatus.uploading,
              progress: 0.5,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Uploaded 1 of 2'), findsOneWidget);
  });

  testWidgets('all-done header reads complete', (tester) async {
    await tester.pumpWidget(
      _host(
        const UploadZone(
          items: [
            UploadItem(id: 'a', name: 'a.jpg', status: UploadStatus.done),
            UploadItem(id: 'b', name: 'b.jpg', status: UploadStatus.done),
          ],
        ),
      ),
    );
    expect(find.text('All 2 uploaded'), findsOneWidget);
  });

  testWidgets('error row surfaces the message and retry/remove', (
    tester,
  ) async {
    String? retried, removed;
    await tester.pumpWidget(
      _host(
        UploadZone(
          items: const [
            UploadItem(
              id: 'x',
              name: 'big.psd',
              status: UploadStatus.error,
              errorText: 'Too large',
            ),
          ],
          onRetry: (id) => retried = id,
          onRemove: (id) => removed = id,
        ),
      ),
    );
    expect(find.text('Too large'), findsOneWidget);

    await tester.tap(_action('Retry upload'));
    expect(retried, 'x');
    await tester.tap(_action('Remove file'));
    expect(removed, 'x');
  });

  testWidgets('cancel fires for an in-flight upload', (tester) async {
    String? cancelled;
    await tester.pumpWidget(
      _host(
        UploadZone(
          items: const [
            UploadItem(
              id: 'u',
              name: 'u.jpg',
              status: UploadStatus.uploading,
              progress: 0.3,
            ),
          ],
          onCancel: (id) => cancelled = id,
        ),
      ),
    );
    await tester.tap(_action('Cancel upload'));
    expect(cancelled, 'u');
  });

  testWidgets('clear-completed shows only when rows are settled', (
    tester,
  ) async {
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        UploadZone(
          items: const [
            UploadItem(id: 'a', name: 'a.jpg', status: UploadStatus.done),
          ],
          onClearCompleted: () => cleared++,
        ),
      ),
    );
    await tester.tap(find.text('Clear completed'));
    expect(cleared, 1);
  });
}
