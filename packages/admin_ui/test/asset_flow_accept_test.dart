import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:file_picker/file_picker.dart';
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

/// Records what the picker asked the platform dialog for and hands back
/// [files].
class _FakeFilePicker extends FilePickerPlatform {
  final List<PlatformFile> files;
  FileType? type;
  List<String>? extensions;
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
  }) async {
    this.type = type;
    extensions = allowedExtensions;
    return files;
  }
}

/// A picked file of [size] bytes, which counts its reads. Without
/// [reportsSize] the platform did not say how large it is.
final class _MemoryFile extends PlatformFile {
  _MemoryFile(this.name, int size, {this.reportsSize = true})
    : bytes = Uint8List.fromList(List.filled(size, 1));

  @override
  final String name;
  final Uint8List bytes;
  final bool reportsSize;
  int reads = 0;

  @override
  Uri get uri => Uri.dataFromBytes(bytes);

  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => reportsSize ? bytes.length : null;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async {
    reads++;
    return bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _Source implements AssetSource {
  final uploaded = <String?>[];

  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult.empty;

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async {
    uploaded.add(filename);
    return null;
  }

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

_MemoryFile _file(String name, {int size = 3, bool reportsSize = true}) =>
    _MemoryFile(name, size, reportsSize: reportsSize);

Widget _app(Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
  builder: (context, navigator) => ToastScope(child: navigator!),
  home: Scaffold(body: ModalAnchor(child: child)),
);

void main() {
  group('AssetAccept', () {
    test('any takes a document; images turn it away', () {
      expect(AssetAccept.any.refusalFor('report.docx'), isNull);
      expect(
        AssetAccept.images.refusalFor('report.docx'),
        AssetRefusalReason.type,
      );
      expect(AssetAccept.images.refusalFor('photo.JPG'), isNull);
      expect(AssetAccept.images.refusalFor('scan.heic'), isNull);
    });

    test('a type or an extension qualifies a file', () {
      const pdfOrSheets = AssetAccept(
        mimeTypes: {'application/pdf'},
        extensions: {'CSV', 'xlsx'},
      );
      expect(pdfOrSheets.refusalFor('a.pdf'), isNull);
      expect(pdfOrSheets.refusalFor('a.csv'), isNull);
      expect(pdfOrSheets.refusalFor('a.XLSX'), isNull);
      expect(pdfOrSheets.refusalFor('a.png'), AssetRefusalReason.type);
      expect(pdfOrSheets.refusalFor('noextension'), AssetRefusalReason.type);
    });

    test('a file over maxBytes is refused for its size', () {
      const small = AssetAccept(maxBytes: 1024);
      expect(small.refusalFor('a.png', bytes: 1024), isNull);
      expect(small.refusalFor('a.png', bytes: 1025), AssetRefusalReason.size);
    });

    testWidgets('the hint names what is taken', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(AssetAccept.any.hintOf(context), isNull);
      expect(AssetAccept.images.hintOf(context), 'Images only');
      expect(
        const AssetAccept(
          mimeTypes: {'image/*'},
          maxBytes: 10 * 1024 * 1024,
        ).hintOf(context),
        'Images only · up to 10 MB',
      );
      expect(
        const AssetAccept(
          mimeTypes: {'application/pdf'},
          extensions: {'docx'},
        ).hintOf(context),
        'PDF, DOCX',
      );
    });

    test('refusals read as one sentence, or as the host words them', () {
      expect(
        AssetAccept.images.describeRefusals(const [
          AssetRefusal('a.docx', AssetRefusalReason.type),
        ]),
        'Couldn’t add a.docx: it’s not an image.',
      );
      expect(
        AssetAccept.images.describeRefusals(const [
          AssetRefusal('a.docx', AssetRefusalReason.type),
          AssetRefusal('b.zip', AssetRefusalReason.type),
        ]),
        'Couldn’t add a.docx, b.zip: they’re not images.',
      );
      final french = AssetAccept(
        mimeTypes: const {'image/*'},
        refusalText: (refused) => '${refused.length} fichier refusé',
      );
      expect(
        french.describeRefusals(const [
          AssetRefusal('a.docx', AssetRefusalReason.type),
        ]),
        '1 fichier refusé',
      );
    });
  });

  group('drop', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('asset_accept'));
    tearDown(() => dir.deleteSync(recursive: true));

    String file(String name) =>
        (File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3])).path;

    Widget target(AssetAccept accept, List<List<DroppedAsset>> drops) => Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: AssetDropTarget(
          accept: accept,
          onFiles: drops.add,
          builder: (context, dragOver) => const Text('target'),
        ),
      ),
    );

    testWidgets('a .docx is taken under any', (tester) async {
      final drops = <List<DroppedAsset>>[];
      await tester.pumpWidget(_app(target(AssetAccept.any, drops)));
      final path = file('notes.docx');
      await tester.runAsync(() async {
        await _drop(tester, tester.getCenter(find.text('target')), [path]);
        while (drops.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(drops.single.single.name, 'notes.docx');
      expect(
        drops.single.single.mime,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    });

    testWidgets('a .docx is refused under images, with a toast', (
      tester,
    ) async {
      final drops = <List<DroppedAsset>>[];
      await tester.pumpWidget(_app(target(AssetAccept.images, drops)));
      await _drop(tester, tester.getCenter(find.text('target')), [
        file('notes.docx'),
      ]);
      await tester.pump();
      expect(drops, isEmpty);
      expect(
        find.text('Couldn’t add notes.docx: it’s not an image.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('browse', () {
    Future<void> browse(
      WidgetTester tester,
      AssetAccept accept,
      _Source source,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showAssetPicker(context, source: source, accept: accept),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DashedBorder));
      await tester.pumpAndSettle();
    }

    testWidgets('images: the dialog offers images and a stray .docx is '
        'refused with a toast', (tester) async {
      final picker = _FakeFilePicker([_file('notes.docx'), _file('a.png')]);
      FilePickerPlatform.instance = picker;
      final source = _Source();
      await browse(tester, AssetAccept.images, source);

      expect(picker.type, FileType.image);
      expect(source.uploaded, ['a.png']);
      expect(
        find.text('Couldn’t add notes.docx: it’s not an image.'),
        findsOneWidget,
      );
    });

    testWidgets('any: a .docx uploads, as a drop would', (tester) async {
      final picker = _FakeFilePicker([_file('notes.docx')]);
      FilePickerPlatform.instance = picker;
      final source = _Source();
      await browse(tester, AssetAccept.any, source);

      expect(picker.type, FileType.any);
      expect(source.uploaded, ['notes.docx']);
    });

    testWidgets('extensions only: the dialog lists them', (tester) async {
      final picker = _FakeFilePicker([_file('a.csv')]);
      FilePickerPlatform.instance = picker;
      await browse(
        tester,
        const AssetAccept(extensions: {'CSV', 'xlsx'}),
        _Source(),
      );
      expect(picker.type, FileType.custom);
      expect(picker.extensions, unorderedEquals(['csv', 'xlsx']));
    });

    testWidgets('a file over maxBytes is refused before it uploads', (
      tester,
    ) async {
      FilePickerPlatform.instance = _FakeFilePicker([
        _file('big.png', size: 2048),
      ]);
      final source = _Source();
      await browse(tester, const AssetAccept(maxBytes: 1024), source);
      expect(source.uploaded, isEmpty);
      expect(
        find.text('Couldn’t add big.png: it’s larger than 1 kB.'),
        findsOneWidget,
      );
    });

    testWidgets('a file refused by its type or reported size is never read', (
      tester,
    ) async {
      final docx = _file('notes.docx');
      final big = _file('big.png', size: 2048);
      final small = _file('a.png');
      FilePickerPlatform.instance = _FakeFilePicker([docx, big, small]);
      final source = _Source();
      await browse(
        tester,
        const AssetAccept(mimeTypes: {'image/*'}, maxBytes: 1024),
        source,
      );
      expect(source.uploaded, ['a.png']);
      expect([docx.reads, big.reads, small.reads], [0, 0, 1]);
    });

    testWidgets('a size the platform did not report is read and checked', (
      tester,
    ) async {
      final big = _file('big.png', size: 2048, reportsSize: false);
      FilePickerPlatform.instance = _FakeFilePicker([big]);
      final source = _Source();
      await browse(tester, const AssetAccept(maxBytes: 1024), source);
      expect(source.uploaded, isEmpty);
      expect(big.reads, 1);
      expect(
        find.text('Couldn’t add big.png: it’s larger than 1 kB.'),
        findsOneWidget,
      );
    });
  });
}
