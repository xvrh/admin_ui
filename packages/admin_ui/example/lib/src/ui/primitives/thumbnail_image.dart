import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

const _photo = AssetImage('assets/sample.jpg');
const _missing = AssetImage('assets/missing.jpg');

/// [ThumbnailImage] at table, list and tile sizes — a landscape photo cropped
/// to cover each square — and the same boxes when the image fails to load:
/// the default broken-image glyph, and a fallback of the caller's own.
class ThumbnailImageDemo extends StatelessWidget {
  @Preview(name: 'Thumbnail image', wrapper: adminUiPreview)
  const ThumbnailImageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.radii.radiusSmall);
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Loaded — 32, 48, 96 and a 160 × 96 tile'),
        _Row(
          children: [
            for (final size in const [32.0, 48.0, 96.0])
              ThumbnailImage(image: _photo, size: size, borderRadius: radius),
            ThumbnailImage(
              image: _photo,
              width: 160,
              height: 96,
              borderRadius: radius,
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Failed to load — the default fallback'),
        _Row(
          children: [
            for (final size in const [32.0, 48.0, 96.0])
              ThumbnailImage(image: _missing, size: size, borderRadius: radius),
            ThumbnailImage(
              image: _missing,
              width: 160,
              height: 96,
              borderRadius: radius,
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Failed to load — a fallback of your own'),
        ThumbnailImage(
          image: _missing,
          width: 160,
          height: 96,
          borderRadius: radius,
          fallback: ColoredBox(
            color: context.colors.surfaceMuted,
            child: Center(
              child: Text('No preview', style: context.type.bodyMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> children;

  const _Row({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.lg,
      runSpacing: AdminSpacing.lg,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
