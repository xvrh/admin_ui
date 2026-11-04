import 'dart:io';

import 'package:admin_ui/src/assets/ui/asset_drop_target.dart';
import 'package:admin_ui/src/common/ui/toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// What the platform side of `desktop_drop` sends while something is dragged
/// over the window and dropped at [at].
Future<void> _drop(WidgetTester tester, Offset at, List<String> paths) async {
  Future<void> send(String method, [Object? arguments]) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'desktop_drop',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );
  await send('entered', [at.dx, at.dy]);
  await send('updated', [at.dx, at.dy]);
  await send('performOperation', paths);
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('asset_drop'));
  tearDown(() => dir.deleteSync(recursive: true));

  String file(String name, List<int> bytes) =>
      (File('${dir.path}/$name')..writeAsBytesSync(bytes)).path;

  Widget target(
    String label,
    List<List<DroppedAsset>> drops, {
    AssetAccept accept = AssetAccept.images,
  }) => SizedBox(
    width: 200,
    height: 200,
    child: AssetDropTarget(
      accept: accept,
      onFiles: drops.add,
      builder: (context, dragOver) => Text(label),
    ),
  );

  Widget app(Widget child) => MaterialApp(
    builder: (context, navigator) => ToastScope(child: navigator!),
    home: Scaffold(body: child),
  );

  testWidgets('a dropped image reaches onFiles, typed by its name', (
    tester,
  ) async {
    var drops = <List<DroppedAsset>>[];
    await tester.pumpWidget(app(Center(child: target('A', drops))));

    var path = file('photo.PNG', [1, 2, 3]);
    await tester.runAsync(() async {
      await _drop(tester, tester.getCenter(find.text('A')), [path]);
      while (drops.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    expect(drops, hasLength(1));
    expect(drops.single.single.name, 'photo.PNG');
    expect(drops.single.single.mime, 'image/png');
    expect(drops.single.single.bytes, [1, 2, 3]);
  });

  testWidgets('a file of the wrong kind is refused with a toast', (
    tester,
  ) async {
    var drops = <List<DroppedAsset>>[];
    await tester.pumpWidget(app(Center(child: target('A', drops))));

    await _drop(tester, tester.getCenter(find.text('A')), [
      file('notes.docx', [0]),
    ]);
    await tester.pump();

    expect(drops, isEmpty);
    expect(
      find.text('Couldn’t add notes.docx: it’s not an image.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('two targets side by side each catch only their own drop', (
    tester,
  ) async {
    var left = <List<DroppedAsset>>[];
    var right = <List<DroppedAsset>>[];
    await tester.pumpWidget(
      app(Row(children: [target('L', left), target('R', right)])),
    );

    var path = file('a.jpg', [9]);
    await tester.runAsync(() async {
      await _drop(tester, tester.getCenter(find.text('R')), [path]);
      while (right.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    expect(left, isEmpty);
    expect(right, hasLength(1));
  });

  testWidgets('a target under an open dialog catches nothing', (tester) async {
    var drops = <List<DroppedAsset>>[];
    await tester.pumpWidget(app(Center(child: target('A', drops))));
    var at = tester.getCenter(find.text('A'));

    showDialog<void>(
      context: tester.element(find.text('A')),
      builder: (_) => const SizedBox.shrink(),
    );
    await tester.pumpAndSettle();

    await _drop(tester, at, [
      file('notes.docx', [0]),
    ]);
    await tester.pump();

    // Refusing it would have shown a toast; not owning it shows nothing.
    expect(drops, isEmpty);
    expect(find.textContaining('Couldn’t add'), findsNothing);
  });
}
