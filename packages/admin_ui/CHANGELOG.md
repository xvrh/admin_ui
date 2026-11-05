# Changelog

## 0.1.1

- A tap target leaves its text out of any `SelectionArea` above it: `Tappable`,
  `CursorRegion`, `Button`, a `CollectionTable` row that opens, a cell edited
  on a double tap and a column header (both under the arrow), a field's label
  (which focuses the field, under the arrow cursor a browser gives a label),
  a tags field's box, a collapsible field group's header, a reference field's
  result rows and load-more, and the image cropper's aspect chips. Before, a
  drag across their labels selected them and only the cursor changed, or the
  I-beam showed. `MentionText` under a tap target stays
  plain rather than opening a selection area of its own, which also put a
  second Tab stop inside the target. The example's selection sweep pumps every
  demo under a `SelectionArea` and fails on selectable text under a target.
- Every control shows the hand off the web too, so a development build on the
  desktop looks like the shipped web app. `Button`, the tree's caret, a
  collapsible field group's header, a reference field's rows and load-more and
  the image cropper's aspect chips took Material's platform-adaptive default,
  the arrow off the web, while `Tappable` showed the hand. A selected option,
  a selected swatch and the current page number show the hand like a selected
  tab (they showed the arrow), and a kanban card that opens shows the hand
  even when it can also be moved (it showed the open hand).

## 0.1.0

The first release. [README.md](README.md) describes the kit: the app frame,
collections and data tables, forms and field bodies, overlays, media and
asset pickers, comments and mentions, version history, charts and sign-in
screens, themed from one set of design tokens in six themes with a light and
a dark mode each. [`api.txt`](api.txt) lists its public surface and
[`looks.txt`](looks.txt) every theme's resolved tokens.
