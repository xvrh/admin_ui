import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/tokens.dart';

/// The modules of light margin a scanner needs around a code, as the QR
/// standard sets it.
const _quietZone = 4;

/// A phone's camera finds dark modules on a light ground, in any theme.
const _ink = Color(0xFF000000);
const _ground = Color(0xFFFFFFFF);

/// A QR code of [data]: a link, an authenticator's `otpauth://` URI, any
/// text a phone's camera should pick up.
///
/// It draws black modules on a white square in every theme and mode, since
/// a scanner reads dark on light and many cannot read the code inverted: in
/// a dark theme it shows as a white tile, its corners the theme's small
/// radius. The square is [size] on a side, the standard's four modules of
/// quiet zone included, and each module a whole number of device pixels, so
/// the code stays sharp; what that leaves over widens the quiet zone.
///
/// The code is encoded at error correction level M, which survives the loss
/// of 15% of it. [data] longer than a QR code holds at that level, some
/// 2,300 bytes, throws an [InputTooLongException] when it is built.
///
/// A screen reader hears an image named [semanticLabel], the localized "QR
/// code" when null. It cannot read the code out, so what the code holds
/// should also be on the page in words for anyone who cannot scan it: the
/// link itself, or an authenticator's setup key.
class QrCodeView extends StatefulWidget {
  /// The text the code holds.
  final String data;

  /// The side of the square, quiet zone included.
  final double size;

  /// What a screen reader hears; the localized "QR code" when null.
  final String? semanticLabel;

  const QrCodeView(this.data, {super.key, this.size = 176, this.semanticLabel});

  @override
  State<QrCodeView> createState() => _QrCodeViewState();
}

class _QrCodeViewState extends State<QrCodeView> {
  late QrImage _image = _encode(widget.data);

  static QrImage _encode(String data) => QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
  );

  @override
  void didUpdateWidget(QrCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) _image = _encode(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel ?? context.adminL10n.display.qrCode,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _QrPainter(
          image: _image,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
          radius: context.radii.radiusSmall,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final QrImage image;
  final double pixelRatio;
  final double radius;

  _QrPainter({
    required this.image,
    required this.pixelRatio,
    required this.radius,
  });

  /// [value] on the device's pixel grid, rounded down.
  double _floor(double value) =>
      (value * pixelRatio).floorToDouble() / pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size.square(side),
        Radius.circular(radius),
      ),
      Paint()..color = _ground,
    );

    final count = image.moduleCount;
    final cells = count + 2 * _quietZone;
    var module = _floor(side / cells);
    if (module <= 0) module = side / cells;
    final origin = _floor((side - module * count) / 2);

    // One path, each run of dark modules in a row one rectangle: a fill
    // of separate squares would leave hairline seams between neighbours.
    final path = Path();
    for (var row = 0; row < count; row++) {
      var col = 0;
      while (col < count) {
        if (!image.isDark(row, col)) {
          col++;
          continue;
        }
        final start = col;
        while (col < count && image.isDark(row, col)) {
          col++;
        }
        path.addRect(
          Rect.fromLTWH(
            origin + start * module,
            origin + row * module,
            (col - start) * module,
            module,
          ),
        );
      }
    }
    canvas.drawPath(path, Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.image != image ||
      old.pixelRatio != pixelRatio ||
      old.radius != radius;
}
