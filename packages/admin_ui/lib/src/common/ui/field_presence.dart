import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The minimal presence surface field chrome needs — adapted from the CRDT
/// session's awareness by the editor host (see `EditorPresenceScope`), so this
/// layer stays free of the collaboration transport.
abstract interface class PresenceChannel {
  int get clientId;

  /// Every client's shared state map, keyed by client id (self included).
  Map<int, Map<String, Object?>> get states;

  /// Subscribes [cb] to state changes; returns the unsubscribe.
  void Function() onChange(void Function() cb);

  /// Publish which field the local user is editing (the `field` state key
  /// [peersOnField] reads).
  void setLocalField(String fieldId);
}

/// Ambient field-level presence: which field each peer is editing, so every
/// field shell can frame itself when a remote peer focuses it. Provided by the
/// editor host; a null [channel] keeps the form single-player.
class FieldPresenceScope extends InheritedWidget {
  final PresenceChannel? channel;

  const FieldPresenceScope({super.key, this.channel, required super.child});

  static PresenceChannel? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FieldPresenceScope>()?.channel;

  @override
  bool updateShouldNotify(FieldPresenceScope old) => channel != old.channel;
}

/// A stable, peer-agnostic color for a client id (golden-angle hue spread), so
/// every peer draws a given client the same color without coordinating — the
/// same scheme the block editor's remote carets and the server-seeded identity
/// use, so a user is one consistent color across carets, rings and roster.
Color presenceColorFor(int clientId) {
  final hue = (clientId * 137.508) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
}

/// One remote peer currently focused in a field.
class PresencePeer {
  final int clientId;
  final String name;
  final Color color;
  const PresencePeer(this.clientId, this.name, this.color);

  @override
  bool operator ==(Object other) =>
      other is PresencePeer &&
      other.clientId == clientId &&
      other.name == name &&
      other.color == color;

  @override
  int get hashCode => Object.hash(clientId, name, color);
}

PresencePeer _peerFrom(int clientId, Map<String, Object?> state) {
  final user = state['user'];
  final name = user is Map && user['name'] is String
      ? user['name'] as String
      : 'User $clientId';
  final rawColor = user is Map ? user['color'] : null;
  final color = rawColor is int ? Color(rawColor) : presenceColorFor(clientId);
  return PresencePeer(clientId, name, color);
}

/// The remote peers whose awareness `field` equals [fieldId] (excludes self).
/// Reads the shared presence keys written by every [FieldShell] on focus.
List<PresencePeer> peersOnField(PresenceChannel channel, String fieldId) {
  final out = <PresencePeer>[];
  channel.states.forEach((clientId, state) {
    if (clientId == channel.clientId) return;
    if (state['field'] != fieldId) return;
    out.add(_peerFrom(clientId, state));
  });
  return out;
}

/// Every remote peer present in this doc (excludes self), for the header roster.
/// Ordered by client id so the face pile is stable across rebuilds.
List<PresencePeer> presentPeers(PresenceChannel channel) {
  final states = channel.states;
  final ids = states.keys.where((id) => id != channel.clientId).toList()
    ..sort();
  return [for (final id in ids) _peerFrom(id, states[id]!)];
}

/// Up-to-two-letter initials for an avatar (first + last word).
String presenceInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

/// Frames a field the moment a remote peer focuses it: a colored ring around the
/// body plus a small name badge in the top end corner. Purely decorative
/// (ignores pointers); renders nothing when no peer is present. Rebuilds only
/// when the set of peers on [fieldId] actually changes, so a burst of remote
/// typing elsewhere doesn't churn every field.
class FieldPresenceRing extends StatefulWidget {
  final PresenceChannel channel;
  final String fieldId;
  final Widget child;

  const FieldPresenceRing({
    super.key,
    required this.channel,
    required this.fieldId,
    required this.child,
  });

  @override
  State<FieldPresenceRing> createState() => _FieldPresenceRingState();
}

class _FieldPresenceRingState extends State<FieldPresenceRing> {
  List<PresencePeer> _peers = const [];
  void Function()? _unsub;

  @override
  void initState() {
    super.initState();
    _peers = peersOnField(widget.channel, widget.fieldId);
    _unsub = widget.channel.onChange(_recompute);
  }

  @override
  void didUpdateWidget(FieldPresenceRing old) {
    super.didUpdateWidget(old);
    if (old.channel != widget.channel || old.fieldId != widget.fieldId) {
      _unsub?.call();
      _unsub = widget.channel.onChange(_recompute);
      _recompute();
    }
  }

  void _recompute() {
    if (!mounted) return;
    final next = peersOnField(widget.channel, widget.fieldId);
    if (_listEquals(next, _peers)) return;
    setState(() => _peers = next);
  }

  static bool _listEquals(List<PresencePeer> a, List<PresencePeer> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _unsub?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The body stays the Stack's first child whether or not a peer is on the
    // field, so a peer arriving never remounts it (and never takes the local
    // editor's focus, selection or undo history with it).
    final peers = _peers;
    // Just outside the body, where the focus ring would be, and following the
    // body's corners out to it.
    final offset = context.focus.offset;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (peers.isNotEmpty) ...[
          Positioned.fill(
            left: -offset,
            top: -offset,
            right: -offset,
            bottom: -offset,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    math.max(0, context.radii.radius + offset),
                  ),
                  border: Border.all(
                    // token-literal: a peer's presence ring
                    color: peers.first.color.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: -9,
            start: 6,
            end: 6,
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: _Badges(peers: peers),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The stacked name chips shown at a field's corner while peers edit it. Shows
/// the first two by name; any beyond fold into a "+N" chip.
class _Badges extends StatelessWidget {
  final List<PresencePeer> peers;
  const _Badges({required this.peers});

  @override
  Widget build(BuildContext context) {
    const maxShown = 2;
    final shown = peers.take(maxShown).toList();
    final extra = peers.length - shown.length;
    // Names give way to the field's width and ellipsize; the count does not.
    final chips = [
      for (final p in shown) Flexible(child: _chip(context, p.color, p.name)),
      if (extra > 0) _chip(context, peers[maxShown].color, '+$extra'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.xs),
          chips[i],
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.radii.radiusPill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.type
            .weighted(context.type.micro, FontWeight.w700)
            .copyWith(color: context.colors.foregroundOn(color)),
      ),
    );
  }
}

/// A live face pile of the other people in this document, for the editor header.
/// Overlapping colored initials (name on hover); any beyond [maxAvatars] fold
/// into a "+N" chip that lists the rest. Updates as peers join / leave / rename,
/// and renders nothing when you're alone.
class DocumentPresenceRoster extends StatefulWidget {
  final PresenceChannel channel;
  final double avatarSize;
  final int maxAvatars;

  const DocumentPresenceRoster({
    super.key,
    required this.channel,
    this.avatarSize = 26,
    this.maxAvatars = 4,
  });

  @override
  State<DocumentPresenceRoster> createState() => _DocumentPresenceRosterState();
}

class _DocumentPresenceRosterState extends State<DocumentPresenceRoster> {
  List<PresencePeer> _peers = const [];
  void Function()? _unsub;

  @override
  void initState() {
    super.initState();
    _peers = presentPeers(widget.channel);
    _unsub = widget.channel.onChange(_recompute);
  }

  @override
  void didUpdateWidget(DocumentPresenceRoster old) {
    super.didUpdateWidget(old);
    if (old.channel != widget.channel) {
      _unsub?.call();
      _unsub = widget.channel.onChange(_recompute);
      _recompute();
    }
  }

  void _recompute() {
    if (!mounted) return;
    final next = presentPeers(widget.channel);
    if (_samePeers(next, _peers)) return;
    setState(() => _peers = next);
  }

  static bool _samePeers(List<PresencePeer> a, List<PresencePeer> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _unsub?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PresenceAvatars(peers: _peers, maxAvatars: widget.maxAvatars);
}

/// An overlapping face pile of [peers] — colored initials, full name on hover,
/// with any beyond [maxAvatars] folded into a "+N" chip that lists the rest.
/// The one avatar-stack used everywhere presence shows up (document roster,
/// global header, list-row badges). Renders nothing for an empty list.
class PresenceAvatars extends StatelessWidget {
  final List<PresencePeer> peers;
  final double avatarSize;
  final int maxAvatars;

  /// Ring color separating overlapping avatars; defaults to the surface color.
  final Color? borderColor;

  const PresenceAvatars({
    super.key,
    required this.peers,
    this.avatarSize = 26,
    this.maxAvatars = 4,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (peers.isEmpty) return const SizedBox.shrink();
    final size = avatarSize;
    final step = size * 0.68; // ~32% overlap
    final shown = peers.take(maxAvatars).toList();
    final extra = peers.length - shown.length;
    final border = borderColor ?? context.colors.background;

    final children = <Widget>[
      for (var i = 0; i < shown.length; i++)
        PositionedDirectional(
          start: i * step,
          child: Tooltip(
            message: shown[i].name,
            child: _circle(
              context,
              shown[i].color,
              presenceInitials(shown[i].name),
              size,
              border,
            ),
          ),
        ),
    ];
    var width = (shown.length - 1) * step + size;
    if (extra > 0) {
      final rest = peers.skip(shown.length).map((p) => p.name).join(', ');
      children.add(
        PositionedDirectional(
          start: shown.length * step,
          child: Tooltip(
            message: rest,
            child: _circle(
              context,
              context.colors.foregroundMuted,
              '+$extra',
              size,
              border,
            ),
          ),
        ),
      );
      width = shown.length * step + size;
    }
    return SizedBox(
      height: size,
      width: width,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _circle(
    BuildContext context,
    Color color,
    String text,
    double size,
    Color border,
  ) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: Text(
        text,
        style: context.type.weighted(
          TextStyle(
            color: context.colors.foregroundOn(color),
            // token-literal: initials scale with the avatar they fill
            fontSize: size * 0.38,
            height: 1.0,
          ),
          FontWeight.w700,
        ),
      ),
    );
  }
}
