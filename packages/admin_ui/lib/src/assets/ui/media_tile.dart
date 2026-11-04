import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/button.dart';
import '../../common/ui/field_chrome.dart' show filterTriggerChrome;
import '../../common/ui/focus_ring.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/spinner.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/thumbnail_image.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// When a [MediaTile] or [MediaListTile] shows its check disc.
enum MediaTileCheck {
  /// Never: a browser that opens what it shows.
  none,

  /// Once picked: a single-pick browser, where the ring already says which.
  selected,

  /// Always, empty until picked: a multi-select browser, so every tile reads
  /// as pickable.
  always,
}

/// What a media tile shows: [image] decoded at the size it is drawn (a
/// broken-image glyph where it fails to load), else a [swatch] gradient
/// standing one in, else [icon] on a neutral fill. Fills its parent.
class MediaThumb extends StatelessWidget {
  final ImageProvider? image;

  /// A stand-in colour for a picture with no [image] — demos and fixtures.
  final Color? swatch;

  /// The glyph on a [swatch] or on the neutral fill.
  final IconData icon;

  /// The [icon]'s size; the theme's extra-large icon when null.
  final double? iconSize;

  /// How [image] fills the box: cropped to cover it in a grid, whole in a
  /// preview.
  final BoxFit fit;

  const MediaThumb({
    super.key,
    this.image,
    this.swatch,
    this.icon = Icons.image_outlined,
    this.iconSize,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconSize = this.iconSize ?? context.iconSizes.xl;
    if (image case final image?) {
      return ThumbnailImage(image: image, fit: fit);
    }
    if (swatch case final swatch?) {
      final light = Color.alphaBlend(
        // token-literal: a swatch's lighter corner
        swatch.withValues(alpha: 0.85),
        colors.surface,
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [light, swatch],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: colors.foregroundOn(Color.lerp(light, swatch, 0.5)!),
          ),
        ),
      );
    }
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: colors.readableOn(
            colors.foregroundMuted,
            surfaces: [colors.surfaceMuted],
            minContrast: 3,
          ),
        ),
      ),
    );
  }
}

/// One item in a media grid: a square [thumbnail] over a [title] and a
/// [subtitle] — the tile the asset library and the stock-provider browser
/// share.
///
/// Its edge is drawn over the picture, so it shows on any image: a hairline at
/// rest, a ring at 40% of the control accent under the pointer, and once
/// [selected] a 2px ring of the control accent, as a checked Check is filled —
/// at 3:1 on the surface and the page, hovered too — kept off the picture by
/// a mat of the surface colour. Keyboard focus draws the theme's focus ring
/// around the square. None of it moves or resizes anything. [check] adds a
/// check disc to the corner.
///
/// A click, Space or Enter runs [onTap]; with [onConfirm], Enter runs that
/// instead. Announced as a button named [semanticLabel] (the title and the
/// subtitle by default), with its selected state unless [selected] is null.
///
/// Given a fixed height, the square takes what the caption leaves (a
/// [MediaGrid] sizes the tile so that is exactly its width); otherwise the
/// square is as tall as the tile is wide.
class MediaTile extends StatelessWidget {
  /// The square's content, usually a [MediaThumb].
  final Widget thumbnail;
  final String title;
  final String? subtitle;

  /// Whether the item is picked; null where nothing can be picked.
  final bool? selected;
  final MediaTileCheck check;
  final VoidCallback? onTap;

  /// Run by Enter in place of [onTap]: pick this item and confirm the pick.
  final VoidCallback? onConfirm;
  final String? semanticLabel;
  final FocusNode? focusNode;

  /// Reports, and can seed, the hovered, pressed and focused states — e.g.
  /// to pin one in a catalog.
  final WidgetStatesController? statesController;

  const MediaTile({
    super.key,
    required this.thumbnail,
    required this.title,
    this.subtitle,
    this.selected,
    this.check = MediaTileCheck.none,
    this.onTap,
    this.onConfirm,
    this.semanticLabel,
    this.focusNode,
    this.statesController,
  });

  static TextStyle _titleStyle(BuildContext context) => context.type
      .weighted(context.type.caption, FontWeight.w600)
      .copyWith(color: context.colors.foreground);

  static TextStyle _subtitleStyle(BuildContext context) =>
      context.type.micro.copyWith(color: _metaColor(context.colors));

  /// The height of the caption under the square: the gap, the title line
  /// and the subtitle line, at the ambient text scale.
  static double captionExtent(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: ' ', style: inherited.style.merge(style)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        textHeightBehavior: inherited.textHeightBehavior,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return AdminSpacing.sm +
        line(_titleStyle(context)) +
        line(_subtitleStyle(context));
  }

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ??
        [title, if (subtitle case final s? when s.isNotEmpty) s].join(', ');
    return _withConfirm(
      onConfirm,
      Tappable.states(
        onTap: onTap,
        focusNode: focusNode,
        statesController: statesController,
        semanticLabel: label,
        excludeSemantics: true,
        selected: selected,
        // The ring hugs the square, not the caption under it.
        showFocusRing: false,
        builder: (context, states) => LayoutBuilder(
          builder: (context, constraints) {
            final square = FocusRing(
              focused: states.contains(WidgetState.focused),
              radius: context.radii.radius,
              child: _Frame(
                states: states,
                selected: selected ?? false,
                check: check,
                child: thumbnail,
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (constraints.hasTightHeight)
                  Expanded(child: square)
                else
                  AspectRatio(aspectRatio: 1, child: square),
                const Gap(AdminSpacing.sm),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(context),
                ),
                Text(
                  subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _subtitleStyle(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The square of a [MediaTile]: [child] clipped to the theme radius, with
/// the edge, the ring and the check drawn over it.
class _Frame extends StatelessWidget {
  final Set<WidgetState> states;
  final bool selected;
  final MediaTileCheck check;
  final Widget child;

  const _Frame({
    required this.states,
    required this.selected,
    required this.check,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final corner = context.radii.radius;
    final hovered = states.contains(WidgetState.hovered);
    final pressed = states.contains(WidgetState.pressed);
    final BorderSide edge;
    if (selected) {
      edge = BorderSide(
        color: _selectionRing(
          colors,
          hovered || pressed ? colors.controlAccentHover : colors.controlAccent,
        ),
        width: context.stroke.indicator,
      );
    } else if (hovered || pressed) {
      edge = BorderSide(
        // token-literal: a hover or press ring, short of the selected one
        color: colors.controlAccent.withValues(alpha: pressed ? 0.6 : 0.4),
        width: context.stroke.indicator,
      );
    } else {
      edge = BorderSide(color: _hairline(colors));
    }
    final showCheck = switch (check) {
      MediaTileCheck.none => false,
      MediaTileCheck.selected => selected,
      MediaTileCheck.always => true,
    };
    // A theme whose focus ring sits inside the edge would draw it over the
    // selection ring; the ring steps in past it (and its 1px band), so a
    // focused pick still shows both.
    final focus = context.focus;
    final inset = selected && states.contains(WidgetState.focused)
        ? math.max(0.0, -focus.offset + 1)
        : 0.0;
    final ringRadius = BorderRadius.circular(math.max(0, corner - inset));
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(corner),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (showCheck)
                PositionedDirectional(
                  top: AdminSpacing.sm,
                  end: AdminSpacing.sm,
                  child: _CheckDisc(selected: selected),
                ),
            ],
          ),
        ),
        IgnorePointer(
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: ringRadius,
                border: Border.fromBorderSide(edge),
              ),
              // A mat of the surface between the ring and the picture, as a
              // ring offset: the ring reads on an image of its own colour.
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: selected
                    ? BoxDecoration(
                        borderRadius: ringRadius,
                        border: Border.all(color: _mat(colors), width: 4),
                      )
                    : const BoxDecoration(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The edge of a picture at rest: the foreground at 12%, which darkens the rim
/// of a light image and all but vanishes on a dark one.
Color _hairline(AdminPalette colors) =>
    // token-literal: the rim a picture draws over itself
    colors.foreground.withValues(alpha: 0.12);

/// The band between a selected picture and its ring: the surface colour.
Color _mat(AdminPalette colors) => colors.surface;

/// The selection ring in [accent], nudged to 3:1 against its mat and the
/// surfaces a grid sits on — the control accent's hover shade may stand
/// nearer them, and would leave the check disc as the only cue.
Color _selectionRing(AdminPalette colors, Color accent) => colors.readableOn(
  accent,
  surfaces: [_mat(colors), colors.background],
  minContrast: 3,
);

/// Subtitle text on the surface, at 4.5:1.
Color _metaColor(AdminPalette colors) =>
    colors.readableOn(colors.foregroundMuted, surfaces: [colors.surface]);

Widget _withConfirm(VoidCallback? onConfirm, Widget child) {
  if (onConfirm == null) return child;
  return CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.enter): onConfirm,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): onConfirm,
    },
    child: child,
  );
}

/// The pick marker: an empty disc, or the control accent with a check, as a
/// checked Check is — rimmed in the surface colour, so it stands off a
/// picture of any colour, even the accent's own.
///
/// Not a `Check`: it overlays a photo, so it is round in every theme (a
/// square box on a picture reads as part of the image), sits on a
/// translucent surface wash rather than the field fill, and is no control of
/// its own — the tile takes the tap, the focus and the checked state.
class _CheckDisc extends StatelessWidget {
  final bool selected;
  const _CheckDisc({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected
            ? colors.controlAccent
            // token-literal: the unticked box over a picture
            : colors.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.surface : colors.controlBorder,
          width: context.stroke.controlStrong,
        ),
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: context.iconSizes.sm,
              color: colors.onControlAccent,
            )
          : null,
    );
  }
}

/// One item in a media list: a check disc, a 40px [thumbnail], a [title]
/// and a [subtitle] in a full-width row — [MediaTile]'s list form, with the
/// same input and semantics. A picked row takes the soft primary fill, and
/// the pointer lays the neutral hover and press overlays over whatever fill
/// the row has. Keyboard focus outlines the row inside its edge, where a
/// list that clips its rows still shows all of it.
class MediaListTile extends StatelessWidget {
  /// The 40px square's content, usually a [MediaThumb].
  final Widget thumbnail;
  final String title;
  final String? subtitle;

  /// Whether the item is picked; null where nothing can be picked.
  final bool? selected;
  final MediaTileCheck check;
  final VoidCallback? onTap;

  /// Run by Enter in place of [onTap]: pick this item and confirm the pick.
  final VoidCallback? onConfirm;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final WidgetStatesController? statesController;

  const MediaListTile({
    super.key,
    required this.thumbnail,
    required this.title,
    this.subtitle,
    this.selected,
    this.check = MediaTileCheck.none,
    this.onTap,
    this.onConfirm,
    this.semanticLabel,
    this.focusNode,
    this.statesController,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ??
        [title, if (subtitle case final s? when s.isNotEmpty) s].join(', ');
    final picked = selected ?? false;
    final showCheck = switch (check) {
      MediaTileCheck.none => false,
      MediaTileCheck.selected => picked,
      MediaTileCheck.always => true,
    };
    return _withConfirm(
      onConfirm,
      Tappable.states(
        onTap: onTap,
        focusNode: focusNode,
        statesController: statesController,
        semanticLabel: label,
        excludeSemantics: true,
        selected: selected,
        showFocusRing: false,
        builder: (context, states) {
          final colors = context.colors;
          final base = picked ? colors.primarySubtle : colors.surface;
          final overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : states.contains(WidgetState.hovered)
              ? colors.hoverOverlay
              : null;
          final fill = overlay == null ? base : Color.alphaBlend(overlay, base);
          return Container(
            color: fill,
            foregroundDecoration: states.contains(WidgetState.focused)
                ? BoxDecoration(
                    border: Border.all(
                      color: colors.focusRing,
                      width: context.focus.width,
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.xl,
              vertical: AdminSpacing.md,
            ),
            child: Row(
              children: [
                if (check != MediaTileCheck.none) ...[
                  SizedBox.square(
                    dimension: 20,
                    child: showCheck ? _CheckDisc(selected: picked) : null,
                  ),
                  const Gap(AdminSpacing.lg),
                ],
                SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        context.radii.radiusSmall,
                      ),
                      border: Border.all(color: _hairline(colors)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        context.radii.radiusSmall,
                      ),
                      child: thumbnail,
                    ),
                  ),
                ),
                const Gap(AdminSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type
                            .weighted(context.type.body, FontWeight.w600)
                            .copyWith(color: colors.foreground),
                      ),
                      if (subtitle case final subtitle?
                          when subtitle.isNotEmpty) ...[
                        const Gap(AdminSpacing.xxs),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // The on-tint muted, so the line keeps one
                          // colour as the row is picked and hovered.
                          style: context.type.caption.copyWith(
                            color: colors.readableOn(
                              colors.foregroundMutedOnTint,
                              surfaces: [fill],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A lazily built, keyboard-navigable collection of media: a grid of
/// [MediaTile]s, or with [MediaGrid.list] a list of [MediaListTile]s. Give it
/// a bounded height; it scrolls.
///
/// **Layout.** Columns are at most [maxTileExtent] wide and share the width
/// equally; each tile's square is exactly its column's width, and the gaps
/// between tiles are the same both ways.
///
/// **Keyboard.** The collection is one Tab stop — the item last focused, else
/// the first shown. The arrow keys move focus between items (up and down by
/// a row in a grid), Home and End to the first and the last; each item's own
/// Space and Enter select or open it. [itemBuilder] hands every item the
/// [FocusNode] that makes this work: pass it to the tile.
///
/// **More.** With [hasMore], scrolling near the end calls [onLoadMore] —
/// once, until [itemCount] or [hasMore] changes — and so does a collection
/// too short to scroll. A page that fails adds nothing, so it is not asked
/// for again until the "Load more" button is pressed. A bar under the items
/// shows [status] (a count, say), a spinner while [loadingMore], and
/// otherwise that button while [hasMore].
class MediaGrid extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, FocusNode focusNode)
  itemBuilder;

  /// The widest a grid column gets.
  final double maxTileExtent;

  /// Names the collection for assistive technology.
  final String? semanticLabel;

  /// Shown in the bar under the items, e.g. "24 of 120 assets".
  final String? status;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  /// The label of the button that loads the next page; "Load more" in the
  /// app's language by default.
  final String? loadMoreLabel;

  final bool _list;

  const MediaGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxTileExtent = 150,
    this.semanticLabel,
    this.status,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    this.loadMoreLabel,
  }) : _list = false;

  /// A list of full-width rows, separated by hairlines; ↑ and ↓ move focus.
  const MediaGrid.list({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.semanticLabel,
    this.status,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    this.loadMoreLabel,
  }) : maxTileExtent = 0,
       _list = true;

  /// Padding round the grid, and the gap between its tiles.
  static const padding = AdminSpacing.xl;
  static const gap = AdminSpacing.lg;

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  final _scroll = ScrollController();
  final _nodes = <int, FocusNode>{};

  /// The items currently built, of which the Tab stop has to be one.
  final _built = <int>{};

  /// The item focus returns to, until another takes it.
  int _active = 0;
  int _tabStop = -1;

  /// Columns and row stride of the last grid layout.
  int _columns = 1;
  double _rowStride = 0;

  /// [MediaGrid.onLoadMore] has been called for what is shown now.
  bool _requested = false;

  @override
  void didUpdateWidget(MediaGrid old) {
    super.didUpdateWidget(old);
    if (widget.itemCount != old.itemCount || widget.hasMore != old.hasMore) {
      _requested = false;
    }
    if (widget.itemCount < old.itemCount) {
      final gone = [
        for (final index in _nodes.keys)
          if (index >= widget.itemCount) index,
      ];
      // Released once the coming layout has unmounted their items.
      final nodes = [for (final index in gone) _nodes.remove(index)!];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in nodes) {
          node.dispose();
        }
      });
      _active = math.min(_active, math.max(0, widget.itemCount - 1));
      _syncTabStop();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeFor(int index) => _nodes[index] ??= FocusNode(
    debugLabel: 'Media item $index',
    skipTraversal: index != _tabStop,
  )..addListener(() => _onFocus(index));

  void _onFocus(int index) {
    if (_nodes[index]?.hasFocus ?? false) {
      _active = index;
      _syncTabStop();
    }
  }

  void _mounted(int index) {
    _built.add(index);
    _syncTabStop();
  }

  void _unmounted(int index) {
    _built.remove(index);
    _syncTabStop();
  }

  /// Keeps exactly one built item in the Tab order: [_active] while it is
  /// built, else the first one that is.
  void _syncTabStop() {
    final stop = _built.contains(_active) || _built.isEmpty
        ? _active
        : _built.reduce(math.min);
    if (stop == _tabStop) return;
    _nodes[_tabStop]?.skipTraversal = true;
    _nodes[stop]?.skipTraversal = false;
    _tabStop = stop;
  }

  int? get _focused {
    for (final MapEntry(key: index, value: node) in _nodes.entries) {
      if (node.hasPrimaryFocus) return index;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final current = _focused;
    if (current == null) return KeyEventResult.ignored;
    final count = widget.itemCount;
    final columns = widget._list ? 1 : _columns;
    final forward = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final int target;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight when !widget._list:
        target = current + forward;
      case LogicalKeyboardKey.arrowLeft when !widget._list:
        target = current - forward;
      case LogicalKeyboardKey.arrowDown:
        final below = current + columns;
        // Into a short last row, from a column it does not reach.
        final lastRow = (count - 1) ~/ columns;
        target = below >= count && current ~/ columns < lastRow
            ? count - 1
            : below;
      case LogicalKeyboardKey.arrowUp:
        target = current - columns;
      case LogicalKeyboardKey.home:
        target = 0;
      case LogicalKeyboardKey.end:
        target = count - 1;
      default:
        return KeyEventResult.ignored;
    }
    if (target >= 0 && target < count && target != current) {
      _moveTo(target, forward: target > current);
    }
    return KeyEventResult.handled;
  }

  void _moveTo(int index, {required bool forward}) {
    _active = index;
    if (_focusBuilt(index, forward: forward)) return;
    // Not built yet: scroll it into the viewport, then focus it.
    if (_scroll.hasClients) {
      final position = _scroll.position;
      final double offset;
      if (index == 0) {
        offset = position.minScrollExtent;
      } else if (index == widget.itemCount - 1) {
        offset = position.maxScrollExtent;
      } else if (widget._list) {
        offset = position.maxScrollExtent * index / (widget.itemCount - 1);
      } else {
        offset = MediaGrid.padding + index ~/ _columns * _rowStride;
      }
      position.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusBuilt(index, forward: forward);
    });
  }

  bool _focusBuilt(int index, {required bool forward}) {
    final node = _nodes[index];
    final target = node?.context;
    if (node == null || target == null || !_built.contains(index)) {
      return false;
    }
    node.requestFocus();
    Scrollable.ensureVisible(
      target,
      alignmentPolicy: forward
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    return true;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0) _maybeLoadMore(notification.metrics);
    return false;
  }

  void _maybeLoadMore(ScrollMetrics metrics) {
    final load = widget.onLoadMore;
    if (load == null || !widget.hasMore || widget.loadingMore || _requested) {
      return;
    }
    // Within half a screen of the end.
    if (metrics.extentAfter > metrics.viewportDimension / 2) return;
    _requested = true;
    load();
  }

  Widget _item(BuildContext context, int index) => _Slot(
    index: index,
    onMount: _mounted,
    onUnmount: _unmounted,
    child: widget.itemBuilder(context, index, _nodeFor(index)),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _maybeLoadMore(_scroll.position);
      });
    }
    Widget items = widget._list ? _listView(context) : _gridView(context);
    items = Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: items,
        ),
      ),
    );
    final bar =
        widget.status != null ||
        widget.loadingMore ||
        (widget.hasMore && widget.onLoadMore != null);
    if (!bar) return items;
    return Column(
      children: [
        Expanded(child: items),
        _StatusBar(
          status: widget.status,
          loadingMore: widget.loadingMore,
          onLoadMore: widget.hasMore ? widget.onLoadMore : null,
          loadMoreLabel: widget.loadMoreLabel,
        ),
      ],
    );
  }

  Widget _gridView(BuildContext context) {
    final caption = MediaTile.captionExtent(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = MediaGrid.padding;
        const gap = MediaGrid.gap;
        final inner = math.max(0.0, constraints.maxWidth - 2 * pad);
        // The fewest columns whose tiles, gaps taken out, fit the extent.
        final columns = math.max(
          1,
          ((inner + gap) / (widget.maxTileExtent + gap)).ceil(),
        );
        final tile = math.max(0.0, (inner - gap * (columns - 1)) / columns);
        _columns = columns;
        _rowStride = tile + caption + gap;
        return GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(pad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: tile + caption,
          ),
          itemCount: widget.itemCount,
          itemBuilder: _item,
        );
      },
    );
  }

  Widget _listView(BuildContext context) {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
      itemCount: widget.itemCount,
      separatorBuilder: (context, _) =>
          Divider(height: 1, thickness: 1, color: context.colors.borderSubtle),
      itemBuilder: _item,
    );
  }
}

/// Tells the grid while item [index] is built.
class _Slot extends StatefulWidget {
  final int index;
  final ValueChanged<int> onMount;
  final ValueChanged<int> onUnmount;
  final Widget child;

  const _Slot({
    required this.index,
    required this.onMount,
    required this.onUnmount,
    required this.child,
  });

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> {
  @override
  void initState() {
    super.initState();
    widget.onMount(widget.index);
  }

  @override
  void didUpdateWidget(_Slot old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      old.onUnmount(old.index);
      widget.onMount(widget.index);
    }
  }

  @override
  void dispose() {
    widget.onUnmount(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StatusBar extends StatelessWidget {
  final String? status;
  final bool loadingMore;
  final VoidCallback? onLoadMore;
  final String? loadMoreLabel;

  const _StatusBar({
    required this.status,
    required this.loadingMore,
    required this.onLoadMore,
    required this.loadMoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.type.caption.copyWith(color: _metaColor(colors));
    return Container(
      // Taller by as much as the status grows at a large text size.
      height:
          context.sizes.small +
          2 * AdminSpacing.sm +
          textGrowthOf(context, text),
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                status ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text,
              ),
            ),
          ),
          if (loadingMore)
            Semantics(
              container: true,
              liveRegion: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Spinner(size: context.iconSizes.sm, announce: false),
                  const Gap(AdminSpacing.sm),
                  Text(context.adminL10n.assets.loadingMore, style: text),
                ],
              ),
            )
          else if (onLoadMore != null)
            Button(
              loadMoreLabel ?? context.adminL10n.loadMore,
              variant: ButtonVariant.ghost,
              size: ControlSize.small,
              onPressed: onLoadMore,
            ),
        ],
      ),
    );
  }
}

/// The bar under a picker: what is picked, then Cancel and the confirm action.
/// [status] reads in the foreground colour, or muted while [muted] (nothing
/// picked yet, or a hint), wrapping to a second line where the bar is narrow; a
/// screen reader hears it change.
class SelectionFooter extends StatelessWidget {
  final String status;
  final IconData? icon;
  final bool muted;

  /// The label of the cancel action; Material's "Cancel" by default.
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final String confirmLabel;

  /// Null disables the confirm action — with nothing picked, say.
  final VoidCallback? onConfirm;

  const SelectionFooter({
    super.key,
    required this.status,
    this.icon,
    this.muted = false,
    this.cancelLabel,
    this.onCancel,
    required this.confirmLabel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = muted
        ? colors.readableOn(
            colors.foregroundMuted,
            surfaces: [colors.background],
          )
        : colors.foreground;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: AdminSpacing.lg,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.iconSizes.md, color: tone),
            const Gap(AdminSpacing.sm),
          ],
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type
                    .weighted(
                      context.type.body,
                      muted ? FontWeight.w500 : FontWeight.w600,
                    )
                    .copyWith(color: tone),
              ),
            ),
          ),
          const Gap(AdminSpacing.lg),
          if (onCancel != null) ...[
            Button(
              cancelLabel ??
                  MaterialLocalizations.of(context).cancelButtonLabel,
              variant: ButtonVariant.ghost,
              onPressed: onCancel,
            ),
            const Gap(AdminSpacing.md),
          ],
          Button.primary(confirmLabel, onPressed: onConfirm),
        ],
      ),
    );
  }
}

/// One choice of a [FilterMenuButton].
class FilterMenuOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const FilterMenuOption(this.value, this.label, {this.icon});
}

/// A toolbar filter that picks one of [options] from a [Menu]: a trigger at
/// the theme's medium control height, level with a search field and a
/// button in the same row, showing the current choice. The open menu lists
/// the options as radio items, the current one checked.
///
/// The trigger is a field's box, as a select beside it draws, in the
/// theme's field anatomy and corner. The first option is the unfiltered
/// one; while any other is chosen the trigger takes the soft primary fill,
/// its edges in the primary. [tooltip] says what it
/// filters by — the tooltip, and with the current choice the accessible
/// name. A null [onChanged] disables it.
class FilterMenuButton<T> extends StatelessWidget {
  final T value;
  final List<FilterMenuOption<T>> options;
  final ValueChanged<T>? onChanged;
  final String tooltip;

  /// The trigger's glyph while unfiltered, or when the choice has none.
  final IconData icon;

  const FilterMenuButton({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.tooltip,
    this.icon = Icons.filter_list_rounded,
  });

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty, 'FilterMenuButton needs at least one option');
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    final active = !identical(current, options.first);
    final change = onChanged;
    return Menu(
      entries: [
        for (final option in options)
          MenuItem(
            option.label,
            icon: option.icon,
            checked: option.value == value,
            onSelect: change == null ? null : () => change(option.value),
          ),
      ],
      builder: (context, controller) => Tip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Tappable.states(
          onTap: change == null ? null : controller.toggle,
          expanded: controller.isOpen,
          semanticLabel: context.adminL10n.assets.filterChoice(
            tooltip,
            current.label,
          ),
          excludeSemantics: true,
          focusRadius: context.radii.radiusField,
          builder: (context, states) => _trigger(
            context,
            states,
            label: current.label,
            glyph: active ? (current.icon ?? icon) : icon,
            active: active,
          ),
        ),
      ),
    );
  }

  Widget _trigger(
    BuildContext context,
    Set<WidgetState> states, {
    required String label,
    required IconData glyph,
    required bool active,
  }) {
    final tokens = context.adminTokens;
    final colors = tokens.palette;
    final height = context.sizes.medium;
    final enabled = !states.contains(WidgetState.disabled);
    final chrome = filterTriggerChrome(tokens, states, active: active);
    final edges = chrome.border;
    final control = context.stroke.control;
    final fg = !enabled
        ? colors.foregroundSubtle
        : active
        ? colors.primaryText
        : colors.foregroundSecondary;
    return Container(
      // Taller by as much as the label grows at a large text size.
      height: height + textGrowthOf(context, context.type.body),
      // Long choices ellipsize rather than stretch the toolbar.
      constraints: const BoxConstraints(maxWidth: 240),
      // The decoration pads by its edges; the content sits inside a
      // control-wide one, whichever edges the anatomy draws.
      padding: EdgeInsetsDirectional.fromSTEB(
        height / 2 - AdminSpacing.sm + control - edges.left,
        control - edges.top,
        height / 2 - AdminSpacing.md + control - edges.right,
        control - edges.bottom,
      ).clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity),
      // Idle, a field's box, as a select's: it lines up with the search
      // box beside it in a toolbar.
      decoration: chrome.decoration(
        BorderRadius.circular(tokens.radii.radiusField),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            glyph,
            size: context.iconSizes.md,
            color: active || !enabled ? fg : colors.foregroundMuted,
          ),
          const Gap(AdminSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: context.type
                  .weighted(context.type.body, FontWeight.w500)
                  .copyWith(color: fg),
            ),
          ),
          const Gap(AdminSpacing.xs),
          Icon(
            Icons.expand_more_rounded,
            size: context.iconSizes.md,
            color: enabled ? colors.foregroundMuted : colors.foregroundSubtle,
          ),
        ],
      ),
    );
  }
}
