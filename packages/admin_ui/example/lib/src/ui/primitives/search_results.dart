import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The content-search experience: body snippets with the matched term
/// highlighted, a provenance chip (why it matched), and a preview pane beside
/// the list. Rendered inline so every result variant is visible at once; the
/// trailing button opens the same palette as a live ⌘K overlay.
class SearchResultsDemo extends StatefulWidget {
  @Preview(name: 'Search results (snippets)', wrapper: adminUiPreview)
  const SearchResultsDemo({super.key});

  @override
  State<SearchResultsDemo> createState() => _SearchResultsDemoState();
}

class _SearchResultsDemoState extends State<SearchResultsDemo> {
  late final CommandPaletteController _controller = CommandPaletteController(
    sources: [_AllResults(_catalogHits(_noop))],
  );

  static void _noop(String _) {}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalAnchor(
      child: DemoPage(
        maxWidth: 880,
        children: [
          const DemoSection('Content search'),
          Text(
            'A query of “linen”. Title matches carry a Name chip and no excerpt; '
            'body/description matches show a highlighted snippet the server '
            'located, plus a Content chip. Arrow or hover to drive the preview '
            'pane. The fuzzy (typo) hit has no exact span, so it shows no mark. '
            'The query field holds focus as it does when ⌘K opens the palette: '
            'bare text in the header, with no box or ring around it.',
            style: context.type.bodyMuted,
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SizedBox(
                height: 460,
                child: CommandPalette.controller(_controller, preview: true),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const DemoSection('Live overlay'),
          _OverlayTrigger(),
        ],
      ),
    );
  }
}

/// Catalog content hits as the server would return them: a title (name) match
/// with no snippet, body/description matches with highlighted excerpts, a
/// multi-occurrence snippet, an accented locale match, and a fuzzy hit.
List<PaletteItem> _catalogHits(void Function(String) onSelect) {
  PaletteItem hit(
    String id,
    String title,
    String group,
    IconData icon, {
    String? subtitle,
    String? snippet,
    List<int> highlights = const [],
    String? reason,
    IconData? reasonIcon,
  }) => PaletteItem(
    id: id,
    title: title,
    group: group,
    icon: icon,
    subtitle: subtitle,
    snippet: snippet,
    snippetHighlights: highlights,
    reason: reason,
    reasonIcon: reasonIcon,
    onSelect: () => onSelect(title),
  );

  const tag = Icons.title_rounded;
  const notes = Icons.notes_rounded;
  const product = Icons.inventory_2_outlined;
  const article = Icons.article_outlined;

  return [
    // Name match — chip only, no excerpt.
    hit(
      'p-blazer',
      'Linen Blazer',
      'Products',
      product,
      reason: 'Name',
      reasonIcon: tag,
    ),
    // Body match — excerpt centred on the term, both ends elided.
    hit(
      'p-throw',
      'Coastal Throw',
      'Products',
      product,
      snippet:
          '…woven from pure linen with a hand-knotted fringe and a '
          'soft, washed finish for…',
      highlights: _span('…woven from pure ', 'linen'),
      reason: 'Body',
      reasonIcon: notes,
    ),
    // Description match with two occurrences highlighted.
    hit(
      'p-runner',
      'Table Runner',
      'Products',
      product,
      snippet:
          '…a linen blend that softens with every wash; the same linen '
          'we use across the…',
      highlights: [
        ..._span('…a ', 'linen'),
        ..._span(
          '…a linen blend that softens with every wash; the same ',
          'linen',
        ),
      ],
      reason: 'Description',
      reasonIcon: notes,
    ),
    // Accented locale match.
    hit(
      'a-fabrics',
      'Sourcing our fabrics',
      'Articles',
      article,
      subtitle: 'Matched in fr',
      snippet:
          '…nous tissons le linen en Normandie depuis trois '
          'générations, fil après…',
      highlights: _span('…nous tissons le ', 'linen'),
      reason: 'Body',
      reasonIcon: notes,
    ),
    // Fuzzy/typo hit — the closest body word is located and highlighted.
    hit(
      'p-cushion',
      'Linnen Cushion',
      'Products',
      product,
      snippet: '…a soft linen cushion cover with a hidden zip…',
      highlights: _span('…a soft ', 'linen'),
      reason: 'Body',
      reasonIcon: notes,
    ),
  ];
}

/// Flat `[start,end]` range of [term] right after [before] in
/// `before + term + …`, so the demo fixtures don't hand-count indexes.
List<int> _span(String before, String term) => [
  before.length,
  before.length + term.length,
];

/// A demo source that returns every hit for any query (so all variants stay on
/// screen), fuzzy-highlighting the title when the query is non-empty.
class _AllResults implements SearchSource {
  final List<PaletteItem> items;
  const _AllResults(this.items);

  @override
  List<PaletteSection> search(String query) {
    final byGroup = <String, List<ScoredItem>>{};
    for (final it in items) {
      final m = fuzzyMatch(query.trim(), it.title);
      (byGroup[it.group] ??= []).add(
        ScoredItem(it, m?.matched ?? const [], m?.score ?? 0),
      );
    }
    return [for (final e in byGroup.entries) PaletteSection(e.key, e.value)];
  }
}

class _OverlayTrigger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CommandTrigger(
      hint: 'Search content…',
      onTap: () {
        void go(String what) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('→ $what (demo)')));
        showCommandPalette(
          context,
          preview: true,
          groupOrder: const ['Products', 'Articles'],
          sources: [_AllResults(_catalogHits(go))],
        );
      },
    );
  }
}
