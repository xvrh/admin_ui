import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The QR code: black on white in every theme and mode, at a few sizes and
/// over a few lengths of data, the code growing denser as the data does.
class QrCodeDemo extends StatelessWidget {
  @Preview(name: 'QR code', wrapper: adminUiPreview)
  const QrCodeDemo({super.key});

  static const _link = 'https://admin.example.com/orders/48213';
  static const _otpauth =
      'otpauth://totp/Acme%20Admin:admin%40example.com'
      '?secret=JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP&issuer=Acme%20Admin'
      '&algorithm=SHA1&digits=6&period=30';

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoVariant(
          'A short link, at the default 176px',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QrCodeView(_link),
          ),
        ),
        const DemoVariant(
          'An authenticator’s otpauth:// URI, named for a screen reader',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QrCodeView(
              _otpauth,
              semanticLabel: 'QR code for your authenticator app',
            ),
          ),
        ),
        DemoVariant(
          'Sizes — 96, 128 and 224px, on the muted surface',
          Panel(
            color: context.colors.surfaceMuted,
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: const Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                QrCodeView(_link, size: 96),
                QrCodeView(_link, size: 128),
                QrCodeView(_otpauth, size: 224),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
