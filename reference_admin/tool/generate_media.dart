// Draws the flat illustrations under assets/media/ that the fake media
// library uses as thumbnails: twelve subjects, three takes of each (01-12 as
// drawn, 13-24 mirrored on another backdrop, 25-36 a close-up). Original
// shapes from a seeded script, so no licence is needed and a rerun rewrites
// the same bytes.
//
//   fvm dart run tool/generate_media.dart

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _width = 480;
const _height = 360;

img.ColorRgb8 _rgb(int hex) =>
    img.ColorRgb8((hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF);

final _backgrounds = [
  0xE8F3EC, 0xF6EFE4, 0xE6EEF6, 0xF3E8EE, 0xEFF1E2, 0xF5EDE0, //
  0xE4F0F0, 0xF1ECF6, 0xEAF4E6, 0xF7EFE9, 0xE9EDF3, 0xF2F2E6,
];

typedef _Painter = void Function(img.Image canvas, Random random);

final _subjects = <String, _Painter>{
  'leaf': _leaf,
  'pot': _pot,
  'watering can': _wateringCan,
  'fern': _fern,
  'cactus': _cactus,
  'trowel': _trowel,
  'seed packet': _seedPacket,
  'sun': _sun,
  'flower': _flower,
  'soil sack': _soilSack,
  'gloves': _gloves,
  'seedling tray': _seedlingTray,
};

void main() {
  final out = Directory('assets/media')..createSync(recursive: true);
  final random = Random(20260101);
  final painters = _subjects.values.toList();
  var written = 0;
  for (var take = 0; take < 3; take++) {
    for (final (index, paint) in painters.indexed) {
      var canvas = img.Image(width: _width, height: _height);
      final backdrop = _backgrounds[(index + take * 5) % _backgrounds.length];
      img.fill(canvas, color: _rgb(backdrop));
      _ground(canvas, random);
      paint(canvas, random);
      if (take == 1) canvas = img.flipHorizontal(canvas);
      if (take == 2) {
        canvas = img.copyResize(
          img.copyCrop(canvas, x: 90, y: 60, width: 300, height: 225),
          width: _width,
          height: _height,
          interpolation: img.Interpolation.average,
        );
      }
      final name = (take * painters.length + index + 1).toString().padLeft(
        2,
        '0',
      );
      File('${out.path}/$name.png')
          .writeAsBytesSync(img.encodePng(canvas, level: 9));
      written++;
    }
  }
  stdout.writeln('Wrote $written images to ${out.path}');
}

void _ground(img.Image c, Random r) {
  final shade = 0xDDE6D5 - r.nextInt(0x0A) * 0x010101;
  img.fillRect(c, x1: 0, y1: 290, x2: _width, y2: _height, color: _rgb(shade));
}

void _poly(img.Image c, List<(num, num)> points, int color) => img.fillPolygon(
  c,
  vertices: [for (final (x, y) in points) img.Point(x, y)],
  color: _rgb(color),
);

void _circle(img.Image c, int x, int y, int radius, int color) =>
    img.fillCircle(c, x: x, y: y, radius: radius, color: _rgb(color));

void _rect(
  img.Image c,
  int x1,
  int y1,
  int x2,
  int y2,
  int color, [
  num r = 0,
]) => img.fillRect(
  c,
  x1: x1,
  y1: y1,
  x2: x2,
  y2: y2,
  color: _rgb(color),
  radius: r,
);

void _line(img.Image c, int x1, int y1, int x2, int y2, int color, num t) =>
    img.drawLine(
      c,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      color: _rgb(color),
      thickness: t,
      antialias: true,
    );

void _potShape(img.Image c, int cx, int top, int width, int color) {
  final half = width ~/ 2;
  _rect(c, cx - half - 10, top, cx + half + 10, top + 24, color, 4);
  _poly(c, [
    (cx - half, top + 24),
    (cx + half, top + 24),
    (cx + half - 22, 300),
    (cx - half + 22, 300),
  ], color);
}

void _leafShape(
  img.Image c,
  int x,
  int y,
  int length,
  double angle,
  int color,
) {
  final dx = cos(angle), dy = sin(angle);
  final nx = -dy, ny = dx;
  final w = length * 0.28;
  _poly(c, [
    (x, y),
    (x + dx * length * 0.5 + nx * w, y + dy * length * 0.5 + ny * w),
    (x + dx * length, y + dy * length),
    (x + dx * length * 0.5 - nx * w, y + dy * length * 0.5 - ny * w),
  ], color);
  _line(
    c,
    x,
    y,
    (x + dx * length * 0.9).round(),
    (y + dy * length * 0.9).round(),
    0x1F5E3A,
    2,
  );
}

void _leaf(img.Image c, Random r) {
  _leafShape(c, 150, 260, 230, -0.55, 0x3F8F5C);
  _leafShape(c, 170, 280, 150, -1.2, 0x5AA874);
}

void _pot(img.Image c, Random r) {
  _potShape(c, 240, 170, 170, 0xC46A3C);
  _rect(c, 170, 200, 310, 206, 0xA9552D);
}

void _wateringCan(img.Image c, Random r) {
  _rect(c, 150, 150, 310, 280, 0x4A7FB5, 18);
  _poly(c, [(310, 190), (330, 190), (410, 120), (398, 110)], 0x4A7FB5);
  _rect(c, 392, 96, 430, 116, 0x3A6A99, 6);
  img.drawCircle(c, x: 200, y: 150, radius: 46, color: _rgb(0x3A6A99));
}

void _fern(img.Image c, Random r) {
  _potShape(c, 240, 230, 110, 0xD9C7A6);
  for (var i = 0; i < 7; i++) {
    final angle = -pi / 2 + (i - 3) * 0.32;
    _leafShape(c, 240, 232, 120 + r.nextInt(40), angle, 0x2F7D4F);
  }
}

void _cactus(img.Image c, Random r) {
  _potShape(c, 240, 240, 120, 0xE2A96B);
  _rect(c, 215, 90, 265, 244, 0x4E9A63, 25);
  _rect(c, 170, 140, 200, 200, 0x4E9A63, 15);
  _rect(c, 170, 185, 220, 205, 0x4E9A63, 10);
  _rect(c, 282, 120, 310, 180, 0x4E9A63, 14);
  _rect(c, 262, 165, 310, 185, 0x4E9A63, 10);
  _circle(c, 240, 86, 12, 0xE36F8F);
}

void _trowel(img.Image c, Random r) {
  _rect(c, 90, 170, 220, 196, 0x8A5A3B, 12);
  _rect(c, 214, 176, 250, 190, 0x9AA3AD);
  _poly(c, [
    (250, 150),
    (380, 170),
    (400, 183),
    (380, 196),
    (250, 216),
  ], 0xB7C0C9);
}

void _seedPacket(img.Image c, Random r) {
  _rect(c, 160, 70, 320, 290, 0xF2D27A, 6);
  _rect(c, 160, 70, 320, 100, 0xE0B94F, 6);
  _circle(c, 240, 180, 50, 0xE36F8F);
  _circle(c, 240, 180, 18, 0xF6E3A1);
  for (var i = 0; i < 6; i++) {
    _circle(c, 190 + r.nextInt(100), 250 + r.nextInt(20), 4, 0x7A5230);
  }
}

void _sun(img.Image c, Random r) {
  for (var i = 0; i < 12; i++) {
    final a = i * pi / 6;
    _line(
      c,
      (240 + cos(a) * 70).round(),
      (150 + sin(a) * 70).round(),
      (240 + cos(a) * 110).round(),
      (150 + sin(a) * 110).round(),
      0xF0B43C,
      8,
    );
  }
  _circle(c, 240, 150, 58, 0xF6C744);
}

void _flower(img.Image c, Random r) {
  _line(c, 240, 290, 240, 150, 0x3F8F5C, 8);
  _leafShape(c, 240, 240, 80, -0.5, 0x5AA874);
  _leafShape(c, 240, 260, 80, pi + 0.5, 0x5AA874);
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3;
    _circle(
      c,
      (240 + cos(a) * 34).round(),
      (130 + sin(a) * 34).round(),
      26,
      0xD9577B,
    );
  }
  _circle(c, 240, 130, 22, 0xF6C744);
}

void _soilSack(img.Image c, Random r) {
  _poly(c, [(160, 110), (320, 110), (340, 290), (140, 290)], 0x9C7A55);
  _rect(c, 170, 96, 310, 118, 0x86664A, 6);
  _rect(c, 185, 170, 295, 240, 0xE8DCC4, 8);
  _leafShape(c, 205, 225, 70, -0.8, 0x3F8F5C);
}

void _gloves(img.Image c, Random r) {
  for (final (x, color) in [(170, 0xE3A04B), (290, 0x6FA86B)]) {
    _rect(c, x - 45, 150, x + 45, 260, color, 20);
    for (var f = 0; f < 4; f++) {
      _rect(c, x - 42 + f * 22, 100, x - 26 + f * 22, 170, color, 8);
    }
    _rect(c, x - 50, 250, x + 50, 285, 0xF4EDE0, 6);
  }
}

void _seedlingTray(img.Image c, Random r) {
  _rect(c, 90, 220, 390, 290, 0x3B3B3B, 6);
  for (var i = 0; i < 5; i++) {
    final x = 120 + i * 60;
    _rect(c, x - 22, 228, x + 22, 282, 0x6B4A2E, 4);
    final h = 30 + r.nextInt(40);
    _line(c, x, 230, x, 230 - h, 0x3F8F5C, 4);
    _leafShape(c, x, 230 - h, 30, -0.6, 0x5AA874);
    _leafShape(c, x, 230 - h, 30, pi + 0.6, 0x5AA874);
  }
}
