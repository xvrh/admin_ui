// AssetDetailView's actions: the app's header controls before the close
// button, and its footer actions at the footer's end with Delete kept at the
// start, danger-styled. showAssetDetail passes both through, and an action
// can open a modal over the sheet.

import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:admin_ui/src/common/ui/side_sheet.dart';
import 'package:admin_ui/src/forms/asset_detail.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _asset = Asset(id: '42', name: 'harbour.jpg', width: 2400, height: 1600);

Widget _download() => IconAction(
  Icons.download_rounded,
  key: const ValueKey('download'),
  label: 'Download',
  size: IconActionSize.small,
  onPressed: () {},
);

Widget _crop(VoidCallback onPressed) => Button(
  'Crop',
  key: const ValueKey('crop'),
  icon: Icons.crop_rounded,
  variant: ButtonVariant.secondary,
  onPressed: onPressed,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double width = 420,
}) async {
  tester.view.physicalSize = const Size(900, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: width, height: 700, child: child),
          ),
        ),
      ),
    ),
  );
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

Rect _delete(WidgetTester tester) =>
    tester.getRect(find.widgetWithText(Button, 'Delete'));

/// The header's close button: its last icon action.
Rect _close(WidgetTester tester) =>
    tester.getRect(find.byType(IconAction).last);

void main() {
  testWidgets('header actions sit before the close button', (tester) async {
    for (final direction in TextDirection.values) {
      await _pump(
        tester,
        AssetDetailView(
          asset: _asset,
          onDismiss: () {},
          actions: [_download()],
        ),
        direction: direction,
      );
      final download = _rect(tester, 'download');
      final close = _close(tester);
      expect(download.center.dy, moreOrLessEquals(close.center.dy));
      if (direction == TextDirection.ltr) {
        expect(download.right, lessThan(close.left));
      } else {
        expect(download.left, greaterThan(close.right));
      }
    }
  });

  testWidgets('footer actions sit at the end, Delete at the start', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await _pump(
        tester,
        AssetDetailView(
          asset: _asset,
          onDelete: () {},
          footerActions: [_crop(() {})],
        ),
        direction: direction,
      );
      final sheet = tester.getRect(find.byType(SideSheet));
      final crop = _rect(tester, 'crop');
      final delete = _delete(tester);
      expect(crop.center.dy, delete.center.dy);
      // The footer's 12px inset from the sheet's edges.
      if (direction == TextDirection.ltr) {
        expect(delete.left - sheet.left, 12);
        expect(sheet.right - crop.right, 12);
      } else {
        expect(sheet.right - delete.right, 12);
        expect(crop.left - sheet.left, 12);
      }
    }
    final button = tester.widget<Button>(find.widgetWithText(Button, 'Delete'));
    expect(button.danger, isTrue);
  });

  testWidgets('the footer shows for footer actions alone', (tester) async {
    await _pump(tester, const AssetDetailView(asset: _asset));
    expect(tester.widget<SideSheet>(find.byType(SideSheet)).footer, isNull);

    await _pump(
      tester,
      AssetDetailView(asset: _asset, footerActions: [_crop(() {})]),
    );
    expect(tester.widget<SideSheet>(find.byType(SideSheet)).footer, isNotNull);
    expect(find.widgetWithText(Button, 'Delete'), findsNothing);
    expect(_rect(tester, 'crop').right, 420 - 12);
  });

  testWidgets('footer actions wrap in a narrow sheet', (tester) async {
    await _pump(
      tester,
      AssetDetailView(
        asset: _asset,
        onDelete: () {},
        footerActions: [
          _crop(() {}),
          Button('Replace', key: const ValueKey('replace'), onPressed: () {}),
          Button('Copy link', key: const ValueKey('copy'), onPressed: () {}),
        ],
      ),
      width: 320,
    );
    expect(tester.takeException(), isNull);
    final crop = _rect(tester, 'crop');
    final copy = _rect(tester, 'copy');
    expect(copy.top, greaterThan(crop.bottom));
    expect(copy.right, 320 - 12);
  });

  testWidgets('showAssetDetail passes the actions through, and one can open '
      'a modal over the sheet', (tester) async {
    final modals = ModalAnchorController();
    var cropped = 0;
    late BuildContext cropContext;
    await _pump(
      tester,
      ModalAnchor(controller: modals, child: const SizedBox.expand()),
      width: 900,
    );
    showAssetDetail(
      modals,
      asset: _asset,
      actions: [_download()],
      footerActions: [
        Builder(
          builder: (context) {
            cropContext = context;
            return _crop(() => cropped++);
          },
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('crop')));
    expect(cropped, 1);

    // The sheet's own anchor takes a modal of the action's.
    ModalAnchor.of(cropContext)
        .show<void>(builder: (_) => const Text('Crop and focal point'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Crop and focal point'), findsOneWidget);
    expect(find.byType(AssetDetailView), findsOneWidget);
  });

  testWidgets('Delete closes the sheet, then reports', (tester) async {
    final modals = ModalAnchorController();
    var deleted = 0;
    await _pump(
      tester,
      ModalAnchor(controller: modals, child: const SizedBox.expand()),
      width: 900,
    );
    showAssetDetail(
      modals,
      asset: _asset,
      onDelete: () => deleted++,
      footerActions: [_crop(() {})],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Button, 'Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(find.byType(AssetDetailView), findsNothing);
  });
}
