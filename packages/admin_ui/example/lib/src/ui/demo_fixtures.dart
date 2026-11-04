import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Shared demo identities + sample data, so demo files stop re-typing the same
/// authors, palette, and "You" reply.

class DemoAuthor {
  final String name;
  final String initials;
  final Color color;

  const DemoAuthor(this.name, this.initials, this.color);
}

const demoYou = DemoAuthor('You', 'Yo', Color(0xFF5b5bd6));
const demoMarina = DemoAuthor('Marina Cole', 'MC', Color(0xFF9333a8));
const demoDiego = DemoAuthor('Diego Ruiz', 'DR', Color(0xFF0f9d8f));
const demoLena = DemoAuthor('Lena Fritz', 'LF', Color(0xFFd97706));

/// A "You" comment reply — the block every `_FullyLoaded` demo repeats.
CommentEntry youReply(String body) => CommentEntry(
  author: demoYou.name,
  initials: demoYou.initials,
  color: demoYou.color,
  time: 'now',
  body: body,
);

/// The shared 6-colour swatch palette (media + reference stand-in thumbnails).
const demoPalette = [
  Color(0xFF6366f1),
  Color(0xFF0ea5e9),
  Color(0xFF10b981),
  Color(0xFFf59e0b),
  Color(0xFFef4444),
  Color(0xFF8b5cf6),
];
