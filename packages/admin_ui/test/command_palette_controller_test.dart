import 'dart:async';

import 'package:admin_ui/src/common/ui/command_palette.dart';
import 'package:admin_ui/src/common/ui/command_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

PaletteItem _item(
  String title,
  String group, {
  List<String> keywords = const [],
  VoidCallback? onSelect,
}) => PaletteItem(
  id: title,
  title: title,
  icon: Icons.circle_outlined,
  group: group,
  keywords: keywords,
  onSelect: onSelect ?? () {},
);

class _AsyncSource implements SearchSource {
  final Completer<List<PaletteSection>> completer;
  _AsyncSource(this.completer);
  @override
  Future<List<PaletteSection>> search(String query) => completer.future;
}

/// Hands out a fresh future per call, modelling independent network requests.
class _QueuedSource implements SearchSource {
  final completers = <Completer<List<PaletteSection>>>[];
  @override
  Future<List<PaletteSection>> search(String query) {
    final c = Completer<List<PaletteSection>>();
    completers.add(c);
    return c.future;
  }
}

void main() {
  // CommandRegistry._notify reads SchedulerBinding to defer mid-frame notifies.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandPaletteController', () {
    test('empty query shows only the recents section', () {
      final c = CommandPaletteController(
        sources: [
          CommandSource(() => [_item('New page', 'Commands')]),
          RecentsSource(() => [_item('About', 'Pages')]),
        ],
      );
      expect(c.sections.map((s) => s.title), ['Recent']);
      expect(c.sections.single.entries.single.item.title, 'About');
    });

    test(
      'typing groups by item.group, ordered by groupOrder, scored within',
      () {
        final c = CommandPaletteController(
          groupOrder: const ['Commands', 'Pages'],
          sources: [
            CommandSource(
              () => [
                _item('Pricing', 'Pages'),
                _item('Price list', 'Commands'),
                _item('Prince', 'Pages'),
              ],
            ),
          ],
        );
        c.setQuery('pri');
        expect(c.sections.map((s) => s.title), ['Commands', 'Pages']);
        // exact-prefix 'Pri…' outranks the gapped 'Pri nce'
        expect(c.sections.last.entries.first.item.title, 'Pricing');
      },
    );

    test('matches via keyword with zero score', () {
      final c = CommandPaletteController(
        sources: [
          CommandSource(
            () => [
              _item('Manage menus', 'Commands', keywords: ['navigation']),
            ],
          ),
        ],
      );
      c.setQuery('navigation');
      expect(c.resultCount, 1);
      expect(c.sections.single.entries.single.matched, isEmpty);
    });

    test('no matches yields no sections', () {
      final c = CommandPaletteController(
        sources: [
          CommandSource(() => [_item('Home', 'Pages')]),
        ],
      );
      c.setQuery('zzzz');
      expect(c.sections, isEmpty);
      expect(c.selectedItem, isNull);
    });

    test('moveSelection clamps and tracks selectedItem', () {
      final c = CommandPaletteController(
        sources: [
          RecentsSource(
            () => [_item('First', 'Recent'), _item('Second', 'Recent')],
          ),
        ],
      );
      expect(c.selected, 0);
      c.moveSelection(-1);
      expect(c.selected, 0); // clamped low
      c.moveSelection(1);
      expect(c.selectedItem!.title, 'Second');
      c.moveSelection(5);
      expect(c.selected, 1); // clamped high
    });

    test('setQuery resets selection to the top', () {
      final c = CommandPaletteController(
        sources: [
          RecentsSource(() => [_item('A', 'Recent'), _item('B', 'Recent')]),
        ],
      );
      c.moveSelection(1);
      expect(c.selected, 1);
      c.setQuery('x');
      expect(c.selected, 0);
    });

    test('async source flips loading then merges in', () async {
      final completer = Completer<List<PaletteSection>>();
      final c = CommandPaletteController(
        sources: [
          CommandSource(() => [_item('New page', 'Commands')]),
          _AsyncSource(completer),
        ],
      );
      c.setQuery('page');
      expect(c.loading, isTrue);
      expect(c.sections.map((s) => s.title), [
        'Commands',
      ]); // sync painted first

      completer.complete([
        PaletteSection('Pages', [
          ScoredItem(_item('Landing page', 'Pages'), const [], 50),
        ]),
      ]);
      await Future<void>.value();
      expect(c.loading, isFalse);
      expect(
        c.sections.map((s) => s.title),
        containsAll(['Commands', 'Pages']),
      );
    });

    test('a superseded async result is ignored', () async {
      final source = _QueuedSource();
      final c = CommandPaletteController(sources: [source]);
      c.setQuery('a'); // request 0
      c.setQuery('ab'); // request 1 supersedes it
      source.completers[0].complete([
        PaletteSection('Pages', [ScoredItem(_item('x', 'Pages'), const [], 1)]),
      ]);
      await Future<void>.value();
      expect(c.sections, isEmpty); // stale result dropped
      expect(c.loading, isTrue); // still awaiting request 1
    });
  });

  group('CommandRegistry', () {
    test('contribute adds, active flattens, dispose withdraws', () {
      final r = CommandRegistry();
      var notified = 0;
      r.addListener(() => notified++);

      final globalSub = r.contribute(() => [_item('Home', 'Go to')]);
      expect(r.active().map((i) => i.title), ['Home']);
      expect(notified, 1);

      final ctxSub = r.contribute(() => [_item('Title', 'Fields')]);
      expect(r.active().map((i) => i.title), ['Home', 'Title']);
      expect(notified, 2);

      ctxSub.dispose();
      expect(r.active().map((i) => i.title), ['Home']);
      expect(notified, 3);

      ctxSub.dispose(); // idempotent, no extra notify
      expect(notified, 3);

      globalSub.dispose();
    });

    test('active calls builders fresh each time', () {
      final r = CommandRegistry();
      var n = 0;
      r.contribute(() => [_item('item-${n++}', 'Fields')]);
      expect(r.active().single.title, 'item-0');
      expect(r.active().single.title, 'item-1');
    });

    testWidgets('a host disposing its registry as a contributor unmounts', (
      tester,
    ) async {
      await tester.pumpWidget(const _RegistryHost());
      final registry = tester
          .state<_RegistryHostState>(find.byType(_RegistryHost))
          .registry;
      expect(registry.active().map((i) => i.title), ['Publish']);

      // The contributor withdraws mid-frame, which defers the notify past the
      // frame, and the host disposes the registry in the same unmount.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('a subscription withdrawn after its registry is disposed', () {
      final r = CommandRegistry();
      final sub = r.contribute(() => [_item('Publish', 'Page')]);
      r.dispose();
      expect(sub.dispose, returnsNormally);
    });
  });
}

class _RegistryHost extends StatefulWidget {
  const _RegistryHost();

  @override
  State<_RegistryHost> createState() => _RegistryHostState();
}

class _RegistryHostState extends State<_RegistryHost> {
  final registry = CommandRegistry();

  @override
  void dispose() {
    registry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CommandScope(registry: registry, child: const _EditorCommands());
}

class _EditorCommands extends StatefulWidget {
  const _EditorCommands();

  @override
  State<_EditorCommands> createState() => _EditorCommandsState();
}

class _EditorCommandsState extends State<_EditorCommands> {
  CommandSubscription? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= CommandScope.of(context)
        .contribute(() => [_item('Publish', 'Page')]);
  }

  @override
  void dispose() {
    _subscription?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
