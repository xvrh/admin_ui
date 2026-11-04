import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A run of text drawn in a box shorter than its lines: the paragraph clips
/// the ink below its box.
class ClippedText {
  /// Where the text is written: the first widget up from it created in
  /// `packages/admin_ui`, as `lib/src/…/file.dart:line` or
  /// `example/lib/src/…/file.dart:line`.
  final String site;
  final String text;

  /// How far the last line's glyphs reach past the box, in logical pixels.
  final double lost;

  const ClippedText(this.site, this.text, this.lost);

  @override
  String toString() {
    final short = text.length > 40 ? '${text.substring(0, 39)}…' : text;
    return '$site "$short" loses ${lost.toStringAsFixed(1)}px';
  }
}

/// Every paragraph on screen whose last line reaches more than a pixel past
/// the bottom of its box: text a fixed-height parent squeezed, which a
/// paragraph clips silently rather than reporting as an overflow.
///
/// The line is measured to the font's descent, so the leading a line height
/// adds below it may be cut without counting; a pixel of the descent itself
/// is let through, since descenders stop short of it.
List<ClippedText> clippedText(WidgetTester tester) {
  final clipped = <ClippedText>[];
  for (final object in tester.allRenderObjects) {
    // Inline widgets would need their own measures; the kit sets none in a
    // box of fixed height.
    if (object is! RenderParagraph || !object.hasSize) continue;
    if (object.firstChild != null) continue;
    final constraints = object.constraints;
    final painter = TextPainter(
      text: object.text,
      textAlign: object.textAlign,
      textDirection: object.textDirection,
      textScaler: object.textScaler,
      maxLines: object.maxLines,
      ellipsis: object.overflow == TextOverflow.ellipsis ? '…' : null,
      locale: object.locale,
      strutStyle: object.strutStyle,
      textWidthBasis: object.textWidthBasis,
      textHeightBehavior: object.textHeightBehavior,
    );
    final wraps = object.softWrap || object.overflow == TextOverflow.ellipsis;
    painter.layout(
      minWidth: constraints.minWidth,
      maxWidth: wraps ? constraints.maxWidth : double.infinity,
    );
    final lines = painter.computeLineMetrics();
    painter.dispose();
    if (lines.isEmpty) continue;
    final last = lines.last;
    final lost = last.baseline + last.descent - object.size.height;
    if (lost > 1) {
      clipped.add(
        ClippedText(_siteOf(object), object.text.toPlainText(), lost),
      );
    }
  }
  return clipped;
}

String _siteOf(RenderParagraph paragraph) {
  final creator = paragraph.debugCreator;
  if (creator is! DebugCreator) return '${paragraph.runtimeType}';
  var site = creator.element.debugGetCreatorChain(4);
  creator.element.visitAncestorElements((ancestor) {
    final location = CreationLocation.of(ancestor.widget);
    final file = location?.file;
    if (file == null || !file.contains('packages/admin_ui/')) return true;
    site = '${file.split('packages/admin_ui/').last}:${location!.line}';
    return false;
  });
  return site;
}
