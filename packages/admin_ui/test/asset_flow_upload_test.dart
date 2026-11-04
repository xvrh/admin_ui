import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Uploads that finish only when the test completes them, each remembering
/// the cancel signal its caller passed.
class _Source implements AssetSource {
  final pending = <Completer<Asset?>>[];
  final cancels = <Future<void>?>[];
  final names = <String?>[];
  int browses = 0;

  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async {
    browses++;
    return AssetBrowseResult.empty;
  }

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) {
    names.add(filename);
    cancels.add(cancelled);
    final done = Completer<Asset?>();
    pending.add(done);
    return done.future;
  }

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

class _FakeFilePicker extends FilePickerPlatform {
  final List<PlatformFile> files;
  _FakeFilePicker(this.files);

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;
}

final class _MemoryFile extends PlatformFile {
  _MemoryFile(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Uri get uri => Uri.dataFromBytes(bytes);

  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => bytes.length;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

PlatformFile _file(String name) =>
    _MemoryFile(name, Uint8List.fromList([1, 2, 3]));

DroppedAsset _dropped(String name) => DroppedAsset(
  name: name,
  mime: 'image/png',
  bytes: Uint8List.fromList([1, 2, 3]),
);

/// A button opening the picker over [source]; the returned getter reads what
/// it resolved with.
Future<(String?, bool) Function()> _openPicker(
  WidgetTester tester,
  AssetSource source,
) async {
  String? result;
  var closed = false;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => ToastScope(child: navigator!),
      home: Scaffold(
        body: ModalAnchor(
          child: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showAssetPicker(context, source: source);
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => (result, closed);
}

Future<void> _browseOneFile(WidgetTester tester, String name) async {
  FilePickerPlatform.instance = _FakeFilePicker([_file(name)]);
  await tester.tap(find.text('Upload'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DashedBorder));
  await tester.pumpAndSettle();
}

void main() {
  group('AssetUploadController', () {
    test(
      'an upload removed in flight never reports, even once it lands',
      () async {
        final source = _Source();
        final controller = AssetUploadController();
        final uploaded = <String>[];
        controller.enqueue(
          [_dropped('a.png')],
          source,
          onUploaded: uploaded.add,
        );
        expect(controller.length, 1);

        var cancelled = false;
        unawaited(source.cancels.single!.then((_) => cancelled = true));
        controller.remove('up0');
        await pumpEventQueue();
        expect(cancelled, isTrue, reason: 'the source is told to abort');
        expect(controller.isEmpty, isTrue);

        source.pending.single.complete(const Asset(id: '9', name: 'a.png'));
        await pumpEventQueue();
        expect(uploaded, isEmpty);
        expect(controller.isEmpty, isTrue);
      },
    );

    test('disposing cancels what is in flight, and it never reports', () async {
      final source = _Source();
      final controller = AssetUploadController();
      final uploaded = <String>[];
      controller.enqueue(
        [_dropped('a.png'), _dropped('b.png')],
        source,
        onUploaded: uploaded.add,
      );
      var cancelled = 0;
      for (final signal in source.cancels) {
        unawaited(signal!.then((_) => cancelled++));
      }

      controller.dispose();
      await pumpEventQueue();
      expect(cancelled, 2, reason: 'the source is told to abort both');

      for (final done in source.pending) {
        done.complete(const Asset(id: '9', name: 'a.png'));
      }
      await pumpEventQueue();
      expect(uploaded, isEmpty);
    });

    test('a failure is kept raw, then a retry lands and reports', () async {
      final source = _Source();
      final controller = AssetUploadController();
      final uploaded = <String>[];
      controller.enqueue([_dropped('a.png')], source, onUploaded: uploaded.add);
      source.pending.single.completeError(
        Exception('ClientException: Connection refused'),
      );
      await pumpEventQueue();
      expect(controller.length, 1, reason: 'the failure stays as a row');

      controller.retry('up0', source, uploaded.add);
      expect(source.pending, hasLength(2));
      source.pending.last.complete(const Asset(id: '12', name: 'a.png'));
      await pumpEventQueue();
      expect(uploaded, ['12']);
      expect(controller.isEmpty, isTrue);
    });

    test('an id that is no integer is an ordinary id', () async {
      final source = _Source();
      final controller = AssetUploadController();
      final uploaded = <String>[];
      controller.enqueue([_dropped('a.png')], source, onUploaded: uploaded.add);
      source.pending.single.complete(
        const Asset(id: '3f2a9c1e-uuid', name: 'a.png'),
      );
      await pumpEventQueue();
      expect(uploaded, ['3f2a9c1e-uuid']);
    });
  });

  group('upload rows', () {
    testWidgets('a failure reads as a sentence, never the raw exception', (
      tester,
    ) async {
      final source = _Source();
      final state = await _openPicker(tester, source);
      await _browseOneFile(tester, 'a.png');

      source.pending.single.completeError(
        Exception('ClientException: Failed to fetch'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Can’t reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('ClientException'), findsNothing);
      expect(state().$2, isFalse);
    });

    testWidgets('a source that answers null reports an incomplete upload', (
      tester,
    ) async {
      final source = _Source();
      await _openPicker(tester, source);
      await _browseOneFile(tester, 'a.png');

      source.pending.single.complete(null);
      await tester.pumpAndSettle();
      expect(
        find.text('The upload didn’t complete. Try again.'),
        findsOneWidget,
      );
    });
  });

  group('picker', () {
    testWidgets('cancelling the one upload keeps the picker open when the '
        'upload lands anyway', (tester) async {
      final source = _Source();
      final state = await _openPicker(tester, source);
      await _browseOneFile(tester, 'new.png');
      expect(source.names, ['new.png']);

      await tester.tap(find.bySemanticsLabel('Cancel upload'));
      await tester.pumpAndSettle();
      source.pending.single.complete(const Asset(id: '42', name: 'new.png'));
      await tester.pumpAndSettle();

      expect(state().$2, isFalse, reason: 'the picker did not close');
      expect(state().$1, isNull);
      expect(find.byType(UploadZone), findsOneWidget);
    });

    testWidgets('closing the picker mid-upload cancels the upload', (
      tester,
    ) async {
      final source = _Source();
      final state = await _openPicker(tester, source);
      await _browseOneFile(tester, 'new.png');
      var cancelled = false;
      unawaited(source.cancels.single!.then((_) => cancelled = true));

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state().$2, isTrue, reason: 'the picker closed');
      expect(cancelled, isTrue, reason: 'nothing lands as an orphan');
    });

    testWidgets('a retried single upload returns its id when it lands', (
      tester,
    ) async {
      final source = _Source();
      final state = await _openPicker(tester, source);
      await _browseOneFile(tester, 'new.png');

      source.pending.single.completeError(Exception('HTTP 500'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Retry upload'));
      await tester.pumpAndSettle();
      source.pending.last.complete(
        const Asset(id: 'asset_7f3c', name: 'new.png'),
      );
      await tester.pumpAndSettle();

      expect(state().$2, isTrue);
      expect(state().$1, 'asset_7f3c');
    });
  });
}
