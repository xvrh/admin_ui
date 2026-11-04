import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_fixtures.dart';
import '../demo_kit.dart';

/// A synthetic image so the demo needs no network or asset bundle: a diagonal
/// gradient, a faint grid, and a bold "subject" disc to aim the crop / focal at.
class _PaintedImage extends ImageProvider<_PaintedImage> {
  final int width;
  final int height;
  final Color a;
  final Color b;
  final Offset subject;

  const _PaintedImage({
    required this.width,
    required this.height,
    required this.a,
    required this.b,
    required this.subject,
  });

  @override
  Future<_PaintedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PaintedImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_render());

  Future<ImageInfo> _render() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = width.toDouble();
    final h = height.toDouble();
    final rect = Rect.fromLTWH(0, 0, w, h);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, b],
        ).createShader(rect),
    );

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += w / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += h / 12) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final c = Offset(subject.dx * w, subject.dy * h);
    final r = (w < h ? w : h) * 0.16;
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(c, r * 0.6, Paint()..color = b.withValues(alpha: 0.85));

    final image = await recorder.endRecording().toImage(width, height);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      other is _PaintedImage &&
      other.width == width &&
      other.height == height &&
      other.a == a &&
      other.b == b &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(width, height, a, b, subject);
}

const _wide = _PaintedImage(
  width: 1600,
  height: 900,
  a: Color(0xFF6366F1),
  b: Color(0xFFEC4899),
  subject: Offset(0.72, 0.4),
);

const _tall = _PaintedImage(
  width: 900,
  height: 1400,
  a: Color(0xFF0EA5E9),
  b: Color(0xFF22C55E),
  subject: Offset(0.5, 0.3),
);

/// Always fails to decode — exercises the cropper's broken-image state.
class _FailingImage extends ImageProvider<_FailingImage> {
  const _FailingImage();

  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error('demo: no bytes'));

  @override
  bool operator ==(Object other) => other is _FailingImage;

  @override
  int get hashCode => 0;
}

const double _wideAspect = 1600 / 900;
const double _tallAspect = 900 / 1400;

Widget _canvas(Widget child) => SizedBox(height: 300, child: child);

class ImageCropperDemo extends StatelessWidget {
  @Preview(name: 'Image cropper / focal', wrapper: adminUiPreview)
  const ImageCropperDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Freeform crop'),
        DemoVariant(
          'Drag any edge or corner; drag the interior to reposition. '
          'Rule-of-thirds guides while framing.',
          LiveValue<CropValue>(
            initial: const CropValue(rect: Rect.fromLTRB(0.1, 0.12, 0.78, 0.9)),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),

        const DemoSection('Two paradigms — region vs frame'),
        DemoVariant(
          'Region — drag a crop rectangle over a fixed image (the default).',
          LiveValue<CropValue>(
            initial: const CropValue(
              rect: Rect.fromLTRB(0.15, 0.15, 0.6, 0.85),
            ),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        DemoVariant(
          'Frame — a fixed square window; drag to pan, scroll or use the slider '
          'to zoom the image beneath. Same CropValue underneath.',
          LiveValue<CropValue>(
            initial: CropValue(rect: maxFramedRect(1 / _wideAspect)),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
                mode: CropMode.frame,
                lockedAspect: 1,
              ),
            ),
          ),
        ),

        const DemoSection('Locked to an aspect ratio'),
        DemoVariant(
          'Pick a ratio; only corner handles resize, keeping the shape exact.',
          const _AspectCropDemo(),
        ),

        const DemoSection('Focal point'),
        DemoVariant(
          'Mark the subject once; the previews show how any output shape stays '
          'framed on it.',
          const _FocalDemo(),
        ),

        const DemoSection('Crop + focal together'),
        DemoVariant(
          'Constrain the source region and pin the subject within it.',
          LiveValue<CropValue>(
            initial: const CropValue(
              rect: Rect.fromLTRB(0.08, 0.1, 0.7, 0.92),
              focal: Offset(0.5, 0.45),
            ),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _tall,
                imageAspect: _tallAspect,
                value: value,
                onChanged: onChanged,
                showFocalPoint: true,
              ),
            ),
          ),
        ),

        const DemoSection('Editing — rotate · flip · reset (feature-flagged)'),
        DemoVariant(
          'Each affordance is an opt-in flag; the crop + focal follow the '
          'content through every transform. Click to focus, then arrow-key to '
          'nudge (Shift = larger, Alt = focal).',
          LiveValue<CropValue>(
            initial: const CropValue(
              rect: Rect.fromLTRB(0.12, 0.14, 0.74, 0.86),
              focal: Offset(0.72, 0.4),
            ),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
                showFocalPoint: true,
                allowRotate: true,
                allowFlip: true,
                allowReset: true,
              ),
            ),
          ),
        ),

        const DemoSection('Straighten (fine angle)'),
        DemoVariant(
          'Drag the slider; the image auto-scales so the crop never shows an '
          'empty corner.',
          LiveValue<CropValue>(
            initial: const CropValue(
              rect: Rect.fromLTRB(0.14, 0.16, 0.86, 0.84),
            ),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
                allowStraighten: true,
                allowReset: true,
              ),
            ),
          ),
        ),

        const DemoSection('Minimum crop size'),
        DemoVariant(
          'Constrained to at least 900×600 px of a 1600×900 source — the crop '
          'cannot shrink below it.',
          LiveValue<CropValue>(
            initial: const CropValue(rect: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9)),
            builder: (value, onChanged) => _canvas(
              ImageCropper(
                image: _wide,
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
                imageSize: const Size(1600, 900),
                minSize: const Size(900, 600),
              ),
            ),
          ),
        ),

        const DemoSection('Broken image'),
        DemoVariant(
          'When the source fails to decode, the canvas shows a placeholder '
          'instead of a crash.',
          _canvas(
            LiveValue<CropValue>(
              initial: const CropValue(
                rect: Rect.fromLTRB(0.15, 0.15, 0.85, 0.85),
              ),
              builder: (value, onChanged) => ImageCropper(
                image: const _FailingImage(),
                imageAspect: _wideAspect,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),

        const DemoSection('Read-only'),
        DemoVariant(
          'No handles — renders a stored crop + focal for review.',
          _canvas(
            const ImageCropper(
              image: _wide,
              imageAspect: _wideAspect,
              value: CropValue(
                rect: Rect.fromLTRB(0.2, 0.15, 0.85, 0.85),
                focal: Offset(0.72, 0.4),
              ),
              showFocalPoint: true,
            ),
          ),
        ),

        const DemoSection('As a form field'),
        DemoVariant(
          'Dropped into FieldShell — a "Cover image" field with capabilities.',
          const _CropField(),
        ),
      ],
    );
  }
}

const _comments = [
  CommentEntry(
    author: 'Priya Nair',
    initials: 'PN',
    color: Color(0xFF9333a8),
    time: '12m',
    body: 'Crop a little tighter on the product, drop the background.',
  ),
];

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: 'Published',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '4d ago',
  ),
];

class _CropField extends StatefulWidget {
  const _CropField();

  @override
  State<_CropField> createState() => _CropFieldState();
}

class _CropFieldState extends State<_CropField> {
  static const _published = CropValue(
    rect: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    focal: Offset(0.72, 0.4),
  );
  CropValue _value = _published;
  final List<CommentEntry> _messages = [..._comments];

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: 'Cover image',
      active: true,
      modified: _value != _published,
      help: const HelpButton(
        text:
            'Frames the entry across listings and social cards. The focal point '
            'keeps the subject in shot when auto-cropped to other ratios.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: 'cropped',
        baseline: 'original',
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: SizedBox(
        height: 300,
        child: ImageCropper(
          image: _wide,
          imageAspect: _wideAspect,
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          showFocalPoint: true,
          allowRotate: true,
          allowFlip: true,
          allowReset: true,
          allowStraighten: true,
        ),
      ),
    );
  }
}

class _AspectCropDemo extends StatefulWidget {
  const _AspectCropDemo();

  @override
  State<_AspectCropDemo> createState() => _AspectCropDemoState();
}

class _AspectCropDemoState extends State<_AspectCropDemo> {
  AspectPreset _preset = const AspectPreset('16:9', 16 / 9);
  CropValue _value = const CropValue(rect: Rect.fromLTRB(0.1, 0.2, 0.9, 0.65));

  @override
  Widget build(BuildContext context) {
    return _canvas(
      ImageCropper(
        image: _wide,
        imageAspect: _wideAspect,
        value: _value,
        onChanged: (v) => setState(() => _value = v),
        lockedAspect: _preset.ratio,
        aspectPresets: AspectPreset.defaults,
        onAspectChanged: (p) => setState(() => _preset = p),
      ),
    );
  }
}

class _FocalDemo extends StatefulWidget {
  const _FocalDemo();

  @override
  State<_FocalDemo> createState() => _FocalDemoState();
}

class _FocalDemoState extends State<_FocalDemo> {
  CropValue _value = const CropValue(focal: Offset(0.72, 0.4));

  static const _previews = [
    ('Square', 1.0),
    ('Wide 16:9', 16 / 9),
    ('Portrait 3:4', 3 / 4),
  ];

  @override
  Widget build(BuildContext context) {
    final focal = _value.focal ?? _value.center;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: ImageCropper(
            image: _wide,
            imageAspect: _wideAspect,
            value: _value,
            onChanged: (v) => setState(() => _value = v),
            showFocalPoint: true,
            showThirds: false,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Auto-cropped outputs',
          style: context.type.bodySmall.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (label, ratio) in _previews) ...[
              Expanded(
                child: _Preview(
                  label: label,
                  ratio: ratio,
                  crop: focalCrop(
                    focal: focal,
                    imageAspect: _wideAspect,
                    targetAspect: ratio,
                  ),
                ),
              ),
              if (label != _previews.last.$1) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final String label;
  final double ratio;
  final Rect crop;

  const _Preview({
    required this.label,
    required this.ratio,
    required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
          child: AspectRatio(
            aspectRatio: ratio,
            child: _CropThumb(image: _wide, crop: crop),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.type.micro.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
      ],
    );
  }
}

/// Paints the normalized [crop] sub-rect of [image] to fill the tile, via
/// `drawImageRect` — the same source-rect render a real backend would do.
class _CropThumb extends StatefulWidget {
  final ImageProvider image;
  final Rect crop;

  const _CropThumb({required this.image, required this.crop});

  @override
  State<_CropThumb> createState() => _CropThumbState();
}

class _CropThumbState extends State<_CropThumb> {
  ImageStream? _stream;
  ui.Image? _image;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) => setState(() => _image = info.image),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return ColoredBox(color: context.colors.surfaceMuted);
    return CustomPaint(painter: _ThumbPainter(image, widget.crop));
  }
}

class _ThumbPainter extends CustomPainter {
  final ui.Image image;
  final Rect crop;

  _ThumbPainter(this.image, this.crop);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTRB(
      crop.left * image.width,
      crop.top * image.height,
      crop.right * image.width,
      crop.bottom * image.height,
    );
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.image != image || old.crop != crop;
}
