import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The [ZoomView] primitive: a large picture fitted to its pane, to zoom and
/// pan. A floor plan with pins laid over it in the plan's own pixels, and a
/// tall page driven by buttons of the page's own through a [ZoomController].
class ZoomViewDemo extends StatelessWidget {
  final bool _zoomedIn;

  @Preview(name: 'Zoom view', wrapper: adminUiPreview)
  const ZoomViewDemo({super.key}) : _zoomedIn = false;

  /// The plan two steps in, at 50%, about the pin at its middle: the bar
  /// with every button live, and the pins' labels legible.
  @Preview(name: 'Zoom view · zoomed in', wrapper: adminUiPreview)
  const ZoomViewDemo.zoomedIn({super.key}) : _zoomedIn = true;

  @override
  Widget build(BuildContext context) {
    if (_zoomedIn) {
      return const DemoPage(
        maxWidth: 720,
        children: [
          DemoVariant(
            'The floor plan two steps in, at 50%, about its middle',
            _ZoomedPlan(),
          ),
        ],
      );
    }
    return DemoPage(
      maxWidth: 720,
      children: [
        Text(
          'A large picture, a photo, a scan or a plan, fitted to its pane. '
          'Scroll or pinch to zoom about the pointer, drag to pan, '
          'double-click for actual pixels and again to fit. With the view '
          'focused, + and − zoom, 0 fits and the arrow keys pan. What is '
          'drawn over the picture is laid out in its own pixels, and zooming '
          'never builds it again.',
          style: TextStyle(color: context.colors.foregroundMuted, height: 1.5),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoVariant(
          'A floor plan of 2400 × 1600 px with its pins, opened fitted',
          SizedBox(
            height: 360,
            child: ZoomView(
              contentSize: _planSize,
              semanticLabel: 'Floor plan',
              child: _Plan(),
            ),
          ),
        ),
        const DemoVariant(
          'A tall page with buttons of its own and showControls: false',
          _PageWithButtons(),
        ),
      ],
    );
  }
}

const _planSize = Size(2400, 1600);

/// A room of the plan, in the plan's pixels.
typedef _Room = ({String name, Rect rect});

const _rooms = <_Room>[
  (name: 'Lobby', rect: Rect.fromLTRB(100, 100, 900, 700)),
  (name: 'Meeting room', rect: Rect.fromLTRB(900, 100, 1600, 700)),
  (name: 'Kitchen', rect: Rect.fromLTRB(1600, 100, 2300, 700)),
  (name: 'Corridor', rect: Rect.fromLTRB(100, 700, 2300, 900)),
  (name: 'Office A', rect: Rect.fromLTRB(100, 900, 800, 1500)),
  (name: 'Office B', rect: Rect.fromLTRB(800, 900, 1500, 1500)),
  (name: 'Storage', rect: Rect.fromLTRB(1500, 900, 2300, 1500)),
];

/// A pin on the plan: where, what, and how urgent.
typedef _PinSpot = ({Offset at, String label, Severity severity});

const _pins = <_PinSpot>[
  (at: Offset(420, 1260), label: 'Desk 14', severity: Severity.info),
  (at: Offset(1180, 330), label: 'Projector', severity: Severity.info),
  (at: Offset(1960, 460), label: 'Leak reported', severity: Severity.warning),
  (at: Offset(1200, 800), label: 'Light out', severity: Severity.danger),
  (at: Offset(560, 800), label: 'Fire exit', severity: Severity.success),
];

/// The plan and its pins, at [_planSize]: a painted plan under pins laid out
/// as widgets, both in the plan's pixels.
class _Plan extends StatelessWidget {
  const _Plan();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PlanPainter(
              surface: colors.surface,
              room: colors.surfaceMuted,
              grid: colors.borderSubtle,
              wall: colors.foregroundSecondary,
              label: context.type.heading.copyWith(
                color: colors.foregroundMuted,
                fontSize: 56,
              ),
            ),
          ),
        ),
        for (final pin in _pins)
          Positioned(
            // The dot's centre on the spot.
            left: pin.at.dx - _PinView.dot / 2,
            top: pin.at.dy - _PinView.dot / 2,
            child: _PinView(pin),
          ),
      ],
    );
  }
}

class _PlanPainter extends CustomPainter {
  final Color surface;
  final Color room;
  final Color grid;
  final Color wall;
  final TextStyle label;

  const _PlanPainter({
    required this.surface,
    required this.room,
    required this.grid,
    required this.wall,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 2;
    for (var x = 0.0; x <= size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final fill = Paint()..color = room;
    final walls = Paint()
      ..color = wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    for (final (i, r) in _rooms.indexed) {
      if (i.isEven) canvas.drawRect(r.rect, fill);
      canvas.drawRect(r.rect, walls);
      final text = TextPainter(
        text: TextSpan(text: r.name, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, r.rect.topLeft + const Offset(40, 32));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.surface != surface ||
      old.room != room ||
      old.grid != grid ||
      old.wall != wall ||
      old.label != label;
}

/// A pin: a dot in its severity's colour, and its label in a chip.
class _PinView extends StatelessWidget {
  /// The dot's diameter, in the plan's pixels.
  static const dot = 40.0;

  final _PinSpot pin;

  const _PinView(this.pin);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = switch (pin.severity) {
      Severity.info => colors.primary,
      Severity.success => colors.success,
      Severity.warning => colors.warning,
      Severity.danger => colors.danger,
    };
    return Row(
      // The plan is a picture: the dot stays on its spot and the label to its
      // right, right to left too.
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 6),
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tone, width: 4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              pin.label,
              style: context.type.body.copyWith(
                color: colors.foreground,
                fontSize: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The plan, zoomed in two steps once it has laid out.
class _ZoomedPlan extends StatefulWidget {
  const _ZoomedPlan();

  @override
  State<_ZoomedPlan> createState() => _ZoomedPlanState();
}

class _ZoomedPlanState extends State<_ZoomedPlan> {
  final _zoom = ZoomController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoom
        ..zoomIn()
        ..zoomIn();
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: ZoomView(
        contentSize: _planSize,
        controller: _zoom,
        semanticLabel: 'Floor plan',
        child: const _Plan(),
      ),
    );
  }
}

const _pageSize = Size(1200, 2400);

/// A tall page, zoomed from the page's own buttons, its scale read from the
/// controller.
class _PageWithButtons extends StatefulWidget {
  const _PageWithButtons();

  @override
  State<_PageWithButtons> createState() => _PageWithButtonsState();
}

class _PageWithButtonsState extends State<_PageWithButtons> {
  final _zoom = ZoomController();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _zoom,
          builder: (context, _) => Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Button(
                'Zoom out',
                icon: Icons.zoom_out_rounded,
                onPressed: _zoom.isFitted ? null : _zoom.zoomOut,
              ),
              Button(
                'Zoom in',
                icon: Icons.zoom_in_rounded,
                onPressed: _zoom.canZoomIn ? _zoom.zoomIn : null,
              ),
              Button('Fit', onPressed: _zoom.isFitted ? null : _zoom.fit),
              Button('Actual pixels', onPressed: _zoom.actualSize),
              Text(
                '${(_zoom.scale * 100).round()}%',
                style: TextStyle(color: context.colors.foregroundMuted),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        SizedBox(
          height: 360,
          child: ZoomView(
            contentSize: _pageSize,
            controller: _zoom,
            showControls: false,
            semanticLabel: 'Scanned page',
            child: const CustomPaint(painter: _PagePainter()),
          ),
        ),
      ],
    );
  }
}

/// A page of a printed report: a title, paragraphs as grey bars, a table,
/// and a stamp in the margin.
class _PagePainter extends CustomPainter {
  const _PagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // A sheet of paper looks the same in a dark theme.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFAF8F3),
    );
    final ink = Paint()..color = const Color(0xFF9A968C);
    final title = Paint()..color = const Color(0xFF4A4740);
    canvas.drawRRect(
      RRect.fromLTRBR(120, 140, 820, 200, const Radius.circular(8)),
      title,
    );
    var y = 300.0;
    for (var paragraph = 0; paragraph < 4; paragraph++) {
      for (var line = 0; line < 6; line++) {
        final end = line == 5 ? 640.0 : 1080.0 - (line * 37 % 90);
        canvas.drawRRect(
          RRect.fromLTRBR(120, y, end, y + 22, const Radius.circular(4)),
          ink,
        );
        y += 44;
      }
      y += 60;
    }
    final rule = Paint()
      ..color = const Color(0xFF9A968C)
      ..strokeWidth = 3;
    for (var row = 0; row <= 8; row++) {
      final top = y + row * 70;
      canvas.drawLine(Offset(120, top), Offset(1080, top), rule);
    }
    for (final x in [120.0, 480.0, 780.0, 1080.0]) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 560), rule);
    }
    final stamp = Paint()
      ..color = const Color(0xFFB3261E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.save();
    canvas.translate(900, 2150);
    canvas.rotate(-0.2);
    canvas.drawRRect(
      RRect.fromLTRBR(-160, -70, 160, 70, const Radius.circular(18)),
      stamp,
    );
    canvas.drawLine(const Offset(-110, 0), const Offset(110, 0), stamp);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PagePainter old) => false;
}
