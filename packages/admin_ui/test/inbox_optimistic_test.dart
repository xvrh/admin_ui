import 'dart:async';

import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row with an identity apart from its content, so a patched copy is a new
/// object under the same key.
class _Row {
  final int id;
  final String name;

  const _Row(this.id, this.name);

  _Row renamed(String name) => _Row(id, name);

  @override
  String toString() => '$id:$name';
}

/// A server of five rows, one page of ten; [rows] is what the next fetch
/// returns.
class _Server {
  var rows = [for (var i = 0; i < 5; i++) _Row(i, 'row $i')];
  var fetches = 0;

  /// When set, the next fetch waits on it.
  Completer<void>? gate;

  Future<CollectionPage<_Row>> fetch(CollectionQuery query) async {
    fetches++;
    final snapshot = List.of(rows);
    if (gate case final gate?) await gate.future;
    return CollectionPage(items: snapshot, total: snapshot.length);
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

List<int> _ids(CollectionController<_Row> c) => [for (final r in c.items) r.id];

List<_Row> Function(List<_Row>) _without(int id) =>
    (rows) => rows.where((r) => r.id != id).toList();

void main() {
  late _Server server;
  late CollectionController<_Row> controller;

  setUp(() async {
    server = _Server();
    controller = CollectionController<_Row>(
      fetcher: server.fetch,
      rowKey: (r) => r.id,
      initialQuery: const CollectionQuery(pageSize: 10),
    );
    await _settle();
  });

  tearDown(() => controller.dispose());

  group('optimistic', () {
    test('applies the change at once and keeps it once committed', () async {
      final commit = Completer<void>();
      var notified = 0;
      controller.addListener(() => notified++);

      final done = controller.optimistic(
        update: _without(2),
        commit: () => commit.future,
      );
      expect(_ids(controller), [0, 1, 3, 4], reason: 'before the commit');
      expect(controller.total, 4);
      expect(notified, 1);

      server.rows.removeWhere((r) => r.id == 2);
      commit.complete();
      await done;
      expect(_ids(controller), [0, 1, 3, 4]);
      expect(controller.total, 4);
      expect(server.fetches, 1, reason: 'no refetch needed');
    });

    test('rolls back the rows, the total and the selection when the commit '
        'throws, and rethrows', () async {
      controller.setSelected({controller.items[2], controller.items[3]});
      final commit = Completer<void>();
      final done = controller.optimistic(
        update: _without(2),
        commit: () => commit.future,
      );
      expect(controller.selectedKeys, {3}, reason: 'a dropped row deselects');

      commit.completeError(StateError('offline'));
      await expectLater(done, throwsStateError);
      expect(_ids(controller), [0, 1, 2, 3, 4]);
      expect(controller.total, 5);
      expect(controller.selectedKeys, {2, 3});
      expect(
        identical(
          controller.selected.firstWhere((r) => r.id == 2),
          controller.items[2],
        ),
        isTrue,
      );
    });

    test('a patch rolls back to the row as it was', () async {
      final before = controller.items[1];
      controller.setSelected({before});
      final done = controller.optimistic(
        update: (rows) => [
          for (final r in rows) r.id == 1 ? r.renamed('x') : r,
        ],
        commit: () async => throw StateError('conflict'),
      );
      expect(controller.items[1].name, 'x');
      expect(controller.selected.single.name, 'x', reason: 'the fresh copy');
      await expectLater(done, throwsStateError);
      expect(identical(controller.items[1], before), isTrue);
      expect(identical(controller.selected.single, before), isTrue);
    });

    test('a page landing during the commit wins, and a failure takes the '
        'change out of it rather than restoring the older rows', () async {
      final commit = Completer<void>();
      final done = controller.optimistic(
        update: _without(2),
        commit: () => commit.future,
      );

      // Someone else renamed row 0 meanwhile; the refresh sees it, and still
      // shows row 2 as gone while its delete is in flight.
      server.rows[0] = server.rows[0].renamed('renamed');
      await controller.refresh();
      expect(_ids(controller), [0, 1, 3, 4]);
      expect(controller.items.first.name, 'renamed');

      commit.completeError(StateError('offline'));
      await expectLater(done, throwsStateError);
      expect(_ids(controller), [0, 1, 2, 3, 4]);
      expect(controller.items.first.name, 'renamed', reason: 'the newer page');
    });

    test('a page read before the commit keeps the change when it lands '
        'after it', () async {
      final gate = server.gate = Completer<void>();
      final refresh = controller.refresh(); // fetched before the delete
      server.gate = null;
      await controller.optimistic(
        update: _without(2),
        commit: () async => server.rows.removeWhere((r) => r.id == 2),
      );
      gate.complete();
      await refresh;
      expect(_ids(controller), [0, 1, 3, 4]);
    });

    test('overlapping changes each roll back only their own', () async {
      final first = Completer<void>();
      final second = Completer<void>();
      final a = controller.optimistic(
        update: _without(1),
        commit: () => first.future,
      );
      final b = controller.optimistic(
        update: _without(3),
        commit: () => second.future,
      );
      expect(_ids(controller), [0, 2, 4]);
      expect(controller.total, 3);

      first.completeError(StateError('offline'));
      await expectLater(a, throwsStateError);
      expect(_ids(controller), [0, 1, 2, 4], reason: 'row 3 still pending');
      expect(controller.total, 4);

      second.complete();
      await b;
      expect(_ids(controller), [0, 1, 2, 4]);
    });

    test('a selection replaced meanwhile is not added to', () async {
      controller.setSelected({controller.items[2]});
      final done = controller.optimistic(
        update: _without(2),
        commit: () async => throw StateError('offline'),
      );
      controller.setSelected({controller.items[0]});
      await expectLater(done, throwsStateError);
      expect(controller.selectedKeys, {0});
    });
  });

  group('undoable', () {
    test('hides at once, and an undo restores without committing', () async {
      controller.setSelected({controller.items[4]});
      final undone = Completer<bool>();
      var committed = false;
      final result = controller.undoable(
        update: _without(4),
        commit: () async => committed = true,
        undone: undone.future,
      );
      expect(_ids(controller), [0, 1, 2, 3]);
      expect(controller.selected, isEmpty);

      undone.complete(true);
      expect(await result, isFalse);
      expect(committed, isFalse);
      expect(_ids(controller), [0, 1, 2, 3, 4]);
      expect(controller.total, 5);
      expect(controller.selectedKeys, {4});
    });

    test('commits once the undo is no longer offered', () async {
      final undone = Completer<bool>();
      var committed = 0;
      final result = controller.undoable(
        update: _without(4),
        commit: () async => committed++,
        undone: undone.future,
      );
      expect(committed, 0, reason: 'held while Undo is on offer');

      undone.complete(false);
      expect(await result, isTrue);
      expect(committed, 1);
      expect(_ids(controller), [0, 1, 2, 3]);
    });

    test('rolls back and rethrows when the held commit fails', () async {
      final result = controller.undoable(
        update: _without(0),
        commit: () async => throw StateError('offline'),
        undone: Future.value(false),
      );
      await expectLater(result, throwsStateError);
      expect(_ids(controller), [0, 1, 2, 3, 4]);
    });

    test('a refresh during the undo window keeps the row hidden', () async {
      final undone = Completer<bool>();
      final result = controller.undoable(
        update: _without(1),
        commit: () async {},
        undone: undone.future,
      );
      await controller.refresh();
      expect(_ids(controller), [0, 2, 3, 4]);

      undone.complete(true);
      await result;
      expect(_ids(controller), [0, 1, 2, 3, 4]);
    });

    test('undoing one of two stacked deletes restores only its row', () async {
      final first = Completer<bool>();
      final second = Completer<bool>();
      final a = controller.undoable(
        update: _without(1),
        commit: () async {},
        undone: first.future,
      );
      final b = controller.undoable(
        update: _without(2),
        commit: () async {},
        undone: second.future,
      );
      expect(_ids(controller), [0, 3, 4]);

      first.complete(true);
      expect(await a, isFalse);
      expect(_ids(controller), [0, 1, 3, 4]);

      second.complete(false);
      expect(await b, isTrue);
      expect(_ids(controller), [0, 1, 3, 4]);
    });

    test('commits after the controller is disposed', () async {
      final own = CollectionController<_Row>(
        fetcher: server.fetch,
        rowKey: (r) => r.id,
      );
      await _settle();
      final undone = Completer<bool>();
      var committed = false;
      final result = own.undoable(
        update: _without(0),
        commit: () async => committed = true,
        undone: undone.future,
      );
      own.dispose();
      undone.complete(false);
      expect(await result, isTrue);
      expect(committed, isTrue);
    });
  });

  group('local edits', () {
    test('patchLocal swaps the matching rows and the selected copy', () {
      controller.setSelected({controller.items[3]});
      controller.patchLocal(
        (r) => r.renamed('edited'),
        where: (r) => r.id == 3,
      );
      expect(controller.items[3].name, 'edited');
      expect(controller.selected.single.name, 'edited');
      expect(controller.total, 5);
    });

    test('removeLocal drops the rows, their selection and the total', () {
      controller.setSelected({controller.items[0], controller.items[1]});
      controller.removeLocal((r) => r.id.isEven);
      expect(_ids(controller), [1, 3]);
      expect(controller.total, 2);
      expect(controller.selectedKeys, {1});
    });

    test('a page read before a local removal lands without the row', () async {
      final gate = server.gate = Completer<void>();
      final refresh = controller.refresh(); // fetched before the removal
      server.gate = null;
      server.rows.removeWhere((r) => r.id == 2);
      controller.removeLocal((r) => r.id == 2);
      gate.complete();
      await refresh;
      expect(_ids(controller), [0, 1, 3, 4]);
      expect(controller.total, 4);
    });

    test('a page read before a local patch lands with the patch', () async {
      final gate = server.gate = Completer<void>();
      final refresh = controller.refresh();
      server.gate = null;
      controller.patchLocal(
        (r) => r.renamed('edited'),
        where: (r) => r.id == 1,
      );
      gate.complete();
      await refresh;
      expect(controller.items[1].name, 'edited');
    });

    test('a local edit stays under a pending change that fails', () async {
      final done = controller.optimistic(
        update: _without(4),
        commit: () async => throw StateError('offline'),
      );
      controller.removeLocal((r) => r.id == 0);
      await expectLater(done, throwsStateError);
      expect(_ids(controller), [1, 2, 3, 4]);
    });
  });
}
