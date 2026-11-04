import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

// ── a mock domain type + fake data layer (the "Screen" half) ────────────────

class _Article {
  final int id; // a serial primary key — the field is keyed on int, not String
  final String title;
  final String author;
  final String section;
  final Color color;

  const _Article(this.id, this.title, this.author, this.section, this.color);
}

final List<_Article> _articles = _makeArticles();

List<_Article> _makeArticles() {
  const titles = [
    ['The quiet collapse of the open web', 'Maya Okonkwo', 'Opinion'],
    ['How tidal turbines finally scaled', 'Diego Ruiz', 'Science & tech'],
    ['A field guide to slow travel', 'Lena Fritz', 'Travel'],
    ['Inside the new espresso startups', 'Tomás Vidal', 'Food & drink'],
    ['Why interest rates surprised everyone', 'Priya Nair', 'Business'],
    ['The return of the city marathon', 'Sam Becker', 'Sport'],
    ['Reading light in winter', 'Maya Okonkwo', 'Culture'],
    ['Grid storage for beginners', 'Diego Ruiz', 'Science & tech'],
    ['The last analogue darkroom', 'Lena Fritz', 'Culture'],
    ['Markets brace for the harvest', 'Priya Nair', 'Markets'],
    ['Coaching the underdog league', 'Sam Becker', 'Sport'],
    ['Fermentation goes mainstream', 'Tomás Vidal', 'Food & drink'],
    ['A short history of the ferry', 'Lena Fritz', 'Travel'],
    ['When privacy became a feature', 'Maya Okonkwo', 'Opinion'],
    ['The economics of repair cafés', 'Priya Nair', 'Business'],
    ['Training for altitude at home', 'Sam Becker', 'Health'],
    ['Solar paint and other myths', 'Diego Ruiz', 'Environment'],
    ['The novelist who stopped writing', 'Maya Okonkwo', 'Books'],
    ['Street food after midnight', 'Tomás Vidal', 'Food & drink'],
    ['Rewilding the suburbs', 'Lena Fritz', 'Environment'],
    ['A new map for night trains', 'Priya Nair', 'Travel'],
    ['The comeback of the corner shop', 'Sam Becker', 'Business'],
    ['Listening to glaciers', 'Diego Ruiz', 'Science & tech'],
    ['The art of the long sentence', 'Maya Okonkwo', 'Books'],
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      _Article(
        i + 1,
        titles[i][0],
        titles[i][1],
        titles[i][2],
        demoPalette[i % demoPalette.length],
      ),
  ];
}

/// Resolve a batch of ids → entities, after a delay. [drop] ids resolve to
/// nothing (deleted/dangling); [fail] throws (a load error).
Future<List<_Article>> _resolve(
  Iterable<int> ids, {
  Duration delay = const Duration(milliseconds: 650),
  Set<int> drop = const {},
  bool fail = false,
}) async {
  await Future.delayed(delay);
  if (fail) throw Exception('network');
  var want = ids.toSet();
  return [
    for (var a in _articles)
      if (want.contains(a.id) && !drop.contains(a.id)) a,
  ];
}

const _searchDelay = Duration(milliseconds: 420);

/// Paginated remote search, after a delay. [empty] always returns nothing;
/// [fail] throws.
Future<ReferencePage<_Article>> _search(
  String query, {
  String? cursor,
  Duration delay = _searchDelay,
  bool empty = false,
  bool fail = false,
  bool blankIdle = false,
}) async {
  await Future.delayed(delay);
  if (fail) throw Exception('network');
  var q = query.trim().toLowerCase();
  var matches = (empty || (blankIdle && q.isEmpty))
      ? <_Article>[]
      : [
          for (var a in _articles)
            if (q.isEmpty ||
                a.title.toLowerCase().contains(q) ||
                a.section.toLowerCase().contains(q) ||
                a.author.toLowerCase().contains(q))
              a,
        ];
  const pageSize = 7;
  var start = int.tryParse(cursor ?? '0') ?? 0;
  var slice = matches.skip(start).take(pageSize).toList();
  var next = start + pageSize < matches.length ? '${start + pageSize}' : null;
  return ReferencePage(slice, nextCursor: next);
}

int _idOf(_Article a) => a.id;

/// The default tile: one [ReferenceTileCard] line. The common case is one
/// expression mapping real fields onto the card.
Widget _tile(BuildContext context, _Article a) => ReferenceTileCard(
  title: a.title,
  subtitle: '${a.section} · ${a.author}',
  swatch: a.color,
  icon: Icons.article_outlined,
);

/// A fully custom tile — same builder seam, returns whatever it likes. Author
/// avatar + title + a section pill.
Widget _customTile(BuildContext context, _Article a) {
  return Row(
    children: [
      Avatar(name: a.author, color: a.color, size: 34),
      const Gap(AdminSpacing.lg),
      Expanded(
        child: Text(
          a.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.bodyStrong,
        ),
      ),
      const Gap(AdminSpacing.md),
      Tag(a.section, variant: TagVariant.outline),
    ],
  );
}

// ── the catalog page ─────────────────────────────────────────────────────────

class ReferenceFieldDemo extends StatelessWidget {
  @Preview(name: 'Reference', wrapper: adminUiPreview)
  const ReferenceFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        DemoSection('Single reference'),
        DemoVariant(
          'Empty — the link trigger opens a search picker',
          const _Live(label: 'Featured article', maxItems: 1),
        ),
        DemoVariant(
          'Seeded — host already had the entity (no skeleton)',
          _Live(
            label: 'Featured article',
            maxItems: 1,
            initial: const [3],
            seed: [_articles[2]],
          ),
        ),
        DemoVariant(
          'Lazy resolve — slow loader, skeleton until it lands',
          const _Live(
            label: 'Featured article',
            maxItems: 1,
            initial: [5],
            resolveDelay: Duration(milliseconds: 1600),
          ),
        ),
        DemoSection('Multiple references'),
        DemoVariant(
          'Live — add, reorder (drag handle), remove',
          const _Live(label: 'Related stories', initial: [1, 8, 19]),
        ),
        DemoVariant(
          'Open — the search picker; a checked row, the rest to add',
          PinnedOpen(
            makeRoom: true,
            child: _Live(
              label: 'Related stories',
              initial: const [1],
              seed: [_articles[0]],
              searchDelay: Duration.zero,
            ),
          ),
        ),
        DemoVariant(
          'Mixed states — loading · ready · missing · error',
          const _Live(
            label: 'Related stories',
            initial: [2, 99, 7],
            resolveDelay: Duration(milliseconds: 1500),
            drop: {99},
            failIds: {7},
          ),
        ),
        DemoVariant(
          'Cap reached (max 3) — trigger hidden, warning shown',
          _Live(
            label: 'Related stories',
            maxItems: 3,
            initial: const [1, 4, 10],
            seed: [_articles[0], _articles[3], _articles[9]],
            warning: 'Up to 3 related stories.',
          ),
        ),
        DemoSection('Custom tile (same builder seam, real T)'),
        DemoVariant(
          'Author avatar + section pill instead of the default card',
          _Live(
            label: 'Related stories',
            initial: const [6, 11],
            seed: [_articles[5], _articles[10]],
            tile: _customTile,
          ),
        ),
        DemoSection('Picker edge states'),
        DemoVariant(
          'Type-to-search — blank query is idle, typing finds results',
          const _Live(
            label: 'Featured article',
            maxItems: 1,
            searchBlankIdle: true,
          ),
        ),
        DemoVariant(
          'No matches — type a query that matches nothing',
          const _Live(
            label: 'Featured article',
            maxItems: 1,
            searchEmpty: true,
          ),
        ),
        DemoVariant(
          'Search error — retry in the popover',
          const _Live(label: 'Featured article', maxItems: 1, searchFail: true),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — no trigger, no remove',
          _Live(
            label: 'Featured article',
            maxItems: 1,
            readOnly: true,
            initial: const [12],
            seed: [_articles[11]],
          ),
        ),
        DemoVariant(
          'Read-only & empty — the box stays, with a neutral "No reference"',
          const _Live(label: 'Featured article', maxItems: 1, readOnly: true),
        ),
        DemoVariant(
          'Disabled — rows dimmed, the trigger inert',
          _Live(
            label: 'Related stories',
            enabled: false,
            initial: const [12],
            seed: [_articles[11]],
          ),
        ),
        DemoVariant(
          'Resolve error on a settled list',
          const _Live(
            label: 'Related stories',
            initial: [1, 2],
            resolveFail: true,
          ),
        ),
        DemoVariant(
          'Field-level validation error',
          const _Live(
            label: 'Featured article',
            maxItems: 1,
            error: 'A featured article is required before publishing.',
          ),
        ),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Draft override tint + capability cluster',
          const _FullyLoaded(),
        ),
        const SizedBox(height: 8),
        Text(
          'The field holds ids and lazily resolves them through an injected '
          'batched resolver, so it paints immediately and fills tiles in '
          'place. Search is debounced + paginated. Resolution and search '
          'are Screen concerns mocked here with delays.',
          style: TextStyle(fontSize: 12, color: context.colors.foregroundMuted),
        ),
      ],
    );
  }
}

/// A reference field with local id state, parameterised so one widget drives
/// every demo variant.
class _Live extends StatefulWidget {
  final String label;
  final int? maxItems;
  final List<int> initial;
  final List<_Article>? seed;
  final ReferenceTile<_Article>? tile;
  final bool readOnly;
  final bool enabled;
  final String? warning;
  final String? error;

  final Duration resolveDelay;
  final Set<int> drop;
  final Set<int> failIds;
  final bool resolveFail;
  final bool searchEmpty;
  final bool searchFail;
  final bool searchBlankIdle;
  final Duration searchDelay;

  const _Live({
    required this.label,
    this.maxItems,
    this.initial = const [],
    this.seed,
    this.tile,
    this.readOnly = false,
    this.enabled = true,
    this.warning,
    this.error,
    this.resolveDelay = const Duration(milliseconds: 650),
    this.drop = const {},
    this.failIds = const {},
    this.resolveFail = false,
    this.searchEmpty = false,
    this.searchFail = false,
    this.searchBlankIdle = false,
    this.searchDelay = _searchDelay,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late List<int> _value = [...widget.initial];

  Future<List<_Article>> _resolveImpl(Iterable<int> ids) {
    if (widget.failIds.isNotEmpty) {
      var asked = ids.toSet();
      if (asked.length == 1 && widget.failIds.contains(asked.first)) {
        return _resolve(ids, delay: widget.resolveDelay, fail: true);
      }
    }
    return _resolve(
      ids,
      delay: widget.resolveDelay,
      drop: widget.drop,
      fail: widget.resolveFail,
    );
  }

  Future<ReferencePage<_Article>> _searchImpl(String q, {String? cursor}) =>
      _search(
        q,
        cursor: cursor,
        delay: widget.searchDelay,
        empty: widget.searchEmpty,
        fail: widget.searchFail,
        blankIdle: widget.searchBlankIdle,
      );

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      enabled: widget.enabled,
      warning: widget.warning,
      errorText: widget.error,
      child: ReferenceBody<_Article, int>(
        value: _value,
        onChanged: widget.readOnly ? null : (v) => setState(() => _value = v),
        idOf: _idOf,
        resolve: _resolveImpl,
        search: _searchImpl,
        tile: widget.tile ?? _tile,
        seed: widget.seed,
        maxItems: widget.maxItems,
      ),
    );
  }
}

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '6m',
    body: 'Swap the second story for the tidal-turbine piece?',
  ),
];

const _versions = [
  FieldVersion(
    label: '3 stories',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: '2 stories',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '1d ago',
  ),
];

/// One field wired with every capability slot; the modified fill stays on
/// while the selection differs from the published two.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const _published = [1, 8];
  List<int> _value = [1, 8, 19];
  final List<CommentEntry> _messages = [..._comments];

  Future<List<_Article>> _resolveImpl(Iterable<int> ids) => _resolve(ids);
  Future<ReferencePage<_Article>> _searchImpl(String q, {String? cursor}) =>
      _search(q, cursor: cursor);

  @override
  Widget build(BuildContext context) {
    var modified = !_listEq(_value, _published);
    return FieldShell(
      label: 'Related stories',
      modified: modified,
      help: const HelpButton(
        text: 'Up to a handful of related stories, shown under the article.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: '${_value.length} stories',
        baseline: '${_published.length} stories',
        versions: _versions,
        onRevert: () => setState(() => _value = [..._published]),
      ),
      child: ReferenceBody<_Article, int>(
        value: _value,
        onChanged: (v) => setState(() => _value = v),
        idOf: _idOf,
        resolve: _resolveImpl,
        search: _searchImpl,
        tile: _tile,
        seed: [_articles[0], _articles[7], _articles[18]],
      ),
    );
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
