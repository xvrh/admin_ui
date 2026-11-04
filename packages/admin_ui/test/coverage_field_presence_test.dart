import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A [PresenceChannel] the test drives by hand: [put] and [leave] stand in
/// for a remote peer's awareness update arriving.
class _Channel implements PresenceChannel {
  _Channel({this.clientId = 1});

  @override
  final int clientId;

  @override
  final Map<int, Map<String, Object?>> states = {};

  final _listeners = <void Function()>[];

  /// Every field [setLocalField] was handed, in order.
  final published = <String>[];

  int get listeners => _listeners.length;

  @override
  void Function() onChange(void Function() cb) {
    _listeners.add(cb);
    return () => _listeners.remove(cb);
  }

  @override
  void setLocalField(String fieldId) {
    published.add(fieldId);
    (states[clientId] ??= {})['field'] = fieldId;
    _notify();
  }

  void put(int clientId, Map<String, Object?> state) {
    states[clientId] = state;
    _notify();
  }

  void leave(int clientId) {
    states.remove(clientId);
    _notify();
  }

  void _notify() {
    for (final cb in [..._listeners]) {
      cb();
    }
  }
}

/// A peer's awareness state while it edits [field].
Map<String, Object?> _on(String field, {String? name, Object? color}) => {
  'user': {'name': ?name, 'color': ?color},
  'field': field,
};

const _alice = Color(0xFFAA0000);
const _bob = Color(0xFF0055AA);

/// [theme]'s dark tokens in the default type, so no font loads.
AdminTokens _dark(AdminTheme theme) {
  final source = theme.dark!;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
  );
}

Widget _host(
  AdminTokens tokens,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 280, child: child),
        ),
      ),
    ),
  ),
);

const _bodyKey = ValueKey('body');
const _body = SizedBox(key: _bodyKey, width: double.infinity, height: 40);

final _ring = find.byWidgetPredicate(
  (w) => w is Container && (w.decoration as BoxDecoration?)?.border != null,
);

/// The row of name chips a badge [text] sits in.
Finder _badgeRow(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Row)).first;

/// The pill around one badge [text].
Finder _chip(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first;

BoxDecoration _ringDecoration(WidgetTester tester) =>
    tester.widget<Container>(_ring).decoration! as BoxDecoration;

/// Records each time an inherited dependency of its context changes.
class _DependencyProbe extends StatefulWidget {
  final List<PresenceChannel?> seen;
  const _DependencyProbe(this.seen);

  @override
  State<_DependencyProbe> createState() => _DependencyProbeState();
}

class _DependencyProbeState extends State<_DependencyProbe> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.seen.add(FieldPresenceScope.maybeOf(context));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  group('presenceColorFor', () {
    double hueDistance(double a, double b) {
      final d = (a - b).abs() % 360;
      return d > 180 ? 360 - d : d;
    }

    test('is stable and opaque', () {
      for (final id in [0, 1, 7, 123456789]) {
        expect(presenceColorFor(id), presenceColorFor(id));
        expect(presenceColorFor(id).a, 1.0);
      }
    });

    test('steps the hue by the golden angle at a fixed saturation and '
        'lightness', () {
      for (var id = 0; id < 12; id++) {
        final hsl = HSLColor.fromColor(presenceColorFor(id));
        expect(
          hueDistance(hsl.hue, id * 137.508 % 360),
          lessThan(1),
          reason: 'client $id',
        );
        expect(hsl.saturation, closeTo(0.7, 0.01), reason: 'client $id');
        expect(hsl.lightness, closeTo(0.5, 0.01), reason: 'client $id');
      }
    });

    test('spreads nearby ids far apart on the wheel', () {
      final hues = [
        for (var id = 1; id <= 8; id++)
          HSLColor.fromColor(presenceColorFor(id)).hue,
      ];
      for (var i = 0; i < hues.length; i++) {
        if (i > 0) {
          expect(hueDistance(hues[i], hues[i - 1]), greaterThan(130));
        }
        for (var j = 0; j < i; j++) {
          expect(
            hueDistance(hues[i], hues[j]),
            greaterThan(30),
            reason: 'clients ${i + 1} and ${j + 1}',
          );
        }
      }
    });

    test('takes any id a transport may hand out', () {
      for (final id in [0xFFFFFFFF, 1 << 53, -7]) {
        final hue = HSLColor.fromColor(presenceColorFor(id)).hue;
        expect(hue, inInclusiveRange(0, 360), reason: 'client $id');
      }
    });
  });

  group('awareness state', () {
    PresencePeer peer(Map<String, Object?> state, {int id = 7}) {
      final channel = _Channel()..put(id, {...state, 'field': 'title'});
      return peersOnField(channel, 'title').single;
    }

    test('reads the name and an int colour', () {
      expect(
        peer(_on('title', name: 'Alice', color: _alice.toARGB32())),
        const PresencePeer(7, 'Alice', _alice),
      );
    });

    test('a missing or non-string name reads "User <id>"', () {
      expect(peer(_on('title', color: _alice.toARGB32())).name, 'User 7');
      expect(
        peer({
          'user': {'name': 42},
        }).name,
        'User 7',
      );
      expect(peer({'user': 'Alice'}).name, 'User 7');
      expect(peer(const {}).name, 'User 7');
    });

    test('a colour that is not an int falls back to presenceColorFor', () {
      for (final state in <Map<String, Object?>>[
        _on('title', name: 'Alice', color: '#AA0000'),
        _on('title', name: 'Alice', color: 0.5),
        _on('title', name: 'Alice'),
        {'user': 'Alice'},
        const {},
      ]) {
        expect(peer(state).color, presenceColorFor(7), reason: '$state');
      }
    });

    test('peers are equal by client, name and colour', () {
      const a = PresencePeer(2, 'Alice', _alice);
      expect(a, const PresencePeer(2, 'Alice', _alice));
      expect(a.hashCode, const PresencePeer(2, 'Alice', _alice).hashCode);
      expect(a, isNot(const PresencePeer(3, 'Alice', _alice)));
      expect(a, isNot(const PresencePeer(2, 'Alicia', _alice)));
      expect(a, isNot(const PresencePeer(2, 'Alice', _bob)));
    });
  });

  group('peersOnField', () {
    test('only the remote peers on that field', () {
      final channel = _Channel(clientId: 1)
        ..setLocalField('title')
        ..put(2, _on('title', name: 'Alice'))
        ..put(3, _on('slug', name: 'Bob'))
        ..put(4, {
          'user': {'name': 'Cleo'},
        });

      expect(peersOnField(channel, 'title').map((p) => p.name), ['Alice']);
      expect(peersOnField(channel, 'slug').map((p) => p.name), ['Bob']);
      expect(peersOnField(channel, 'price'), isEmpty);
      expect(peersOnField(_Channel(), 'title'), isEmpty);
    });
  });

  group('presentPeers', () {
    test('every remote peer, on a field or not, ordered by client id', () {
      final channel = _Channel(clientId: 5)
        ..setLocalField('title')
        ..put(9, _on('title', name: 'Alice'))
        ..put(2, {
          'user': {'name': 'Bob'},
        })
        ..put(7, _on('slug', name: 'Cleo'));

      expect(presentPeers(channel).map((p) => p.clientId), [2, 7, 9]);
      expect(presentPeers(_Channel()), isEmpty);
    });
  });

  test('presenceInitials: first and last word, "?" for no name', () {
    expect(presenceInitials('alice'), 'A');
    expect(presenceInitials(' ada  b  lovelace '), 'AL');
    expect(presenceInitials(''), '?');
    expect(presenceInitials('   '), '?');
  });

  test('presenceInitials keeps a character outside the BMP whole', () {
    expect(presenceInitials('😀 Smile'), '😀S');
    expect(presenceInitials('𝓐da'), '𝓐');
  });

  group('FieldPresenceScope', () {
    testWidgets('maybeOf is null without a scope, or with no channel', (
      tester,
    ) async {
      final seen = <PresenceChannel?>[];
      await tester.pumpWidget(_host(defaultTokens, _DependencyProbe(seen)));
      await tester.pumpWidget(
        _host(defaultTokens, FieldPresenceScope(child: _DependencyProbe(seen))),
      );
      expect(seen, [null, null]);
    });

    testWidgets('dependents hear of a new channel, not of a rebuild', (
      tester,
    ) async {
      final a = _Channel();
      final b = _Channel();
      final seen = <PresenceChannel?>[];
      final probe = _DependencyProbe(seen);
      Future<void> pump(PresenceChannel channel) => tester.pumpWidget(
        _host(
          defaultTokens,
          FieldPresenceScope(channel: channel, child: probe),
        ),
      );

      await pump(a);
      await pump(a);
      expect(seen, [a]);
      await pump(b);
      expect(seen, [a, b]);
    });
  });

  for (final (name, tokens) in [
    ('Iris light', defaultTokens),
    ('Carbon dark', _dark(carbonTheme)),
  ]) {
    group('FieldPresenceRing, $name', () {
      Widget ring(
        _Channel channel, {
        String fieldId = 'title',
        TextDirection direction = TextDirection.ltr,
      }) => _host(
        tokens,
        FieldPresenceRing(channel: channel, fieldId: fieldId, child: _body),
        direction: direction,
      );

      testWidgets('draws only its child while nobody is on the field', (
        tester,
      ) async {
        final channel = _Channel()
          ..setLocalField('title')
          ..put(2, _on('slug', name: 'Alice'));
        await tester.pumpWidget(ring(channel));

        expect(_ring, findsNothing);
        expect(find.text('Alice'), findsNothing);
        expect(
          tester.getRect(find.byKey(_bodyKey)),
          tester.getRect(find.byType(FieldPresenceRing)),
        );
      });

      testWidgets('frames the child while a peer is on the field, and '
          'clears when they move on or leave', (tester) async {
        final channel = _Channel();
        await tester.pumpWidget(ring(channel));

        channel.put(2, _on('title', name: 'Alice', color: _alice.toARGB32()));
        await tester.pump();
        final body = tester.getRect(find.byKey(_bodyKey));
        final focus = tokens.focus;
        expect(tester.getRect(_ring), body.inflate(focus.offset));
        final decoration = _ringDecoration(tester);
        expect(
          decoration.border,
          Border.all(color: _alice.withValues(alpha: 0.9)),
        );
        expect(
          decoration.borderRadius,
          BorderRadius.circular(
            math.max(0.0, tokens.radii.radius + focus.offset),
          ),
        );
        final badge = tester.widget<Text>(find.text('Alice'));
        expect(badge.style!.color, tokens.palette.foregroundOn(_alice));

        channel.put(2, _on('slug', name: 'Alice', color: _alice.toARGB32()));
        await tester.pump();
        expect(_ring, findsNothing);
        expect(find.text('Alice'), findsNothing);

        channel.put(2, _on('title', name: 'Alice', color: _alice.toARGB32()));
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);
        channel.leave(2);
        await tester.pump();
        expect(_ring, findsNothing);
        expect(find.text('Alice'), findsNothing);
      });

      testWidgets('names two peers, folds the rest into "+N", and rings in '
          'the first one\'s colour', (tester) async {
        final channel = _Channel()
          ..put(2, _on('title', name: 'Alice', color: _alice.toARGB32()))
          ..put(3, _on('title', name: 'Bob', color: _bob.toARGB32()))
          ..put(4, _on('title', name: 'Cleo'))
          ..put(5, _on('title', name: 'Dan'));
        await tester.pumpWidget(ring(channel));

        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('Cleo'), findsNothing);
        expect(find.text('+2'), findsOneWidget);
        expect(
          (_ringDecoration(tester).border! as Border).top.color,
          _alice.withValues(alpha: 0.9),
        );
      });

      for (final direction in TextDirection.values) {
        testWidgets('the badge sits on the top edge at the end, '
            '${direction.name}', (tester) async {
          final channel = _Channel()..put(2, _on('title', name: 'Alice'));
          await tester.pumpWidget(ring(channel, direction: direction));

          final body = tester.getRect(find.byKey(_bodyKey));
          final badges = tester.getRect(_badgeRow('Alice'));
          expect(badges.top, body.top - 9);
          if (direction == TextDirection.ltr) {
            expect(badges.right, body.right - 6);
          } else {
            expect(badges.left, body.left + 6);
          }
        });
      }

      testWidgets('the last chip ends 6px in, with or without a "+N"', (
        tester,
      ) async {
        final channel = _Channel()..put(2, _on('title', name: 'Alice'));
        await tester.pumpWidget(ring(channel));
        final body = tester.getRect(find.byKey(_bodyKey));
        expect(tester.getRect(_chip('Alice')).right, body.right - 6);

        channel
          ..put(3, _on('title', name: 'Bob'))
          ..put(4, _on('title', name: 'Cleo'));
        await tester.pump();
        expect(tester.getRect(_chip('+1')).right, body.right - 6);
        expect(
          tester.getRect(_chip('+1')).left - tester.getRect(_chip('Bob')).right,
          4,
        );
      });

      testWidgets('a long name ellipsizes inside the field', (tester) async {
        final name = 'Maximiliane ' * 4;
        final channel = _Channel()
          ..put(2, _on('title', name: name))
          ..put(3, _on('title', name: 'Bob'))
          ..put(4, _on('title', name: 'Cleo'));
        await tester.pumpWidget(ring(channel));

        final body = tester.getRect(find.byKey(_bodyKey));
        final badges = tester.getRect(_badgeRow(name));
        expect(badges.left, greaterThanOrEqualTo(body.left + 6));
        expect(badges.right, body.right - 6);
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(name))
              .didExceedMaxLines,
          isTrue,
        );
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('lets taps through the ring and the badge', (tester) async {
        var taps = 0;
        final channel = _Channel()..put(2, _on('title', name: 'Alice'));
        await tester.pumpWidget(
          _host(
            tokens,
            FieldPresenceRing(
              channel: channel,
              fieldId: 'title',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: _body,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(_bodyKey));
        // Where the badge hangs over the body's top edge.
        final top = tester.getRect(find.byKey(_bodyKey)).top;
        await tester.tapAt(
          Offset(tester.getCenter(find.text('Alice')).dx, top + 4),
        );
        expect(taps, 2);
      });

      testWidgets('rebuilds only when the peers on its field change', (
        tester,
      ) async {
        final channel = _Channel()..put(2, _on('title', name: 'Alice'));
        await tester.pumpWidget(ring(channel));
        bool dirty() => tester.element(find.byType(FieldPresenceRing)).dirty;

        channel
          ..put(3, _on('slug', name: 'Bob'))
          ..put(2, _on('title', name: 'Alice'))
          ..setLocalField('slug');
        expect(dirty(), isFalse);

        channel.put(3, _on('title', name: 'Bob'));
        expect(dirty(), isTrue);
        await tester.pump();
        expect(find.text('Bob'), findsOneWidget);
      });

      testWidgets('lays its child out the same with or without a peer', (
        tester,
      ) async {
        const key = ValueKey('sized by its parent');
        final channel = _Channel();
        await tester.pumpWidget(
          _host(
            tokens,
            FieldPresenceRing(
              channel: channel,
              fieldId: 'title',
              child: const SizedBox(key: key, height: 40),
            ),
          ),
        );
        final alone = tester.getRect(find.byKey(key));

        channel.put(2, _on('title', name: 'Alice'));
        await tester.pump();
        expect(tester.getRect(find.byKey(key)), alone);
      });

      testWidgets('follows a new field id or channel, and unsubscribes', (
        tester,
      ) async {
        final first = _Channel()..put(2, _on('slug', name: 'Alice'));
        await tester.pumpWidget(ring(first));
        expect(find.text('Alice'), findsNothing);
        expect(first.listeners, 1);

        await tester.pumpWidget(ring(first, fieldId: 'slug'));
        expect(find.text('Alice'), findsOneWidget);
        expect(first.listeners, 1);

        final second = _Channel()..put(3, _on('slug', name: 'Bob'));
        await tester.pumpWidget(ring(second, fieldId: 'slug'));
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('Alice'), findsNothing);
        expect((first.listeners, second.listeners), (0, 1));

        await tester.pumpWidget(const SizedBox());
        expect(second.listeners, 0);
      });
    });

    group('FieldShell presence, $name', () {
      Widget shell(
        PresenceChannel? channel, {
        String? fieldId = 'title',
        FocusNode? focusNode,
      }) {
        final field = FieldShell(
          label: 'Title',
          fieldId: fieldId,
          child: InputField(value: 'Hello', focusNode: focusNode),
        );
        return _host(
          tokens,
          channel == null
              ? field
              : FieldPresenceScope(channel: channel, child: field),
        );
      }

      testWidgets('draws no ring without a channel', (tester) async {
        await tester.pumpWidget(shell(null));
        expect(find.byType(FieldPresenceRing), findsNothing);
      });

      testWidgets('frames its body while a peer is on its field id', (
        tester,
      ) async {
        final channel = _Channel();
        await tester.pumpWidget(shell(channel));
        channel.put(2, _on('title', name: 'Alice', color: _alice.toARGB32()));
        await tester.pump();

        expect(find.text('Alice'), findsOneWidget);
        expect(
          tester.getRect(_ring),
          tester.getRect(find.byType(InputField)).inflate(tokens.focus.offset),
        );
      });

      testWidgets('without a field id, it shows and publishes no presence', (
        tester,
      ) async {
        // A label is not an id: two fields may share one.
        final channel = _Channel()..put(2, _on('Title', name: 'Alice'));
        await tester.pumpWidget(shell(channel, fieldId: null));
        expect(find.text('Alice'), findsNothing);
        expect(find.byType(FieldPresenceRing), findsNothing);

        await tester.tap(find.byType(EditableText));
        await tester.pump();
        expect(channel.published, isEmpty);
      });

      testWidgets('publishes its field id when the body takes focus', (
        tester,
      ) async {
        final channel = _Channel();
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(shell(channel, focusNode: focus));

        await tester.tap(find.byType(EditableText));
        await tester.pump();
        expect(channel.published, ['title']);

        focus.unfocus();
        await tester.pump();
        expect(channel.published, ['title']);
      });

      testWidgets(
        'keeps the local editor focused when a peer joins its field',
        (tester) async {
          final channel = _Channel();
          await tester.pumpWidget(shell(channel));
          await tester.tap(find.byType(EditableText));
          await tester.pump();
          final editor = tester.state<EditableTextState>(
            find.byType(EditableText),
          );

          channel.put(2, _on('title', name: 'Alice'));
          await tester.pump();

          expect(find.text('Alice'), findsOneWidget);
          expect(tester.state(find.byType(EditableText)), same(editor));
          expect(editor.widget.focusNode.hasFocus, isTrue);
        },
      );
    });
  }
}
