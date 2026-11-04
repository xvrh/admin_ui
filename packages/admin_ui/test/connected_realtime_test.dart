import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _coalesce = Duration(milliseconds: 20);

Future<void> _wait([Duration d = const Duration(milliseconds: 50)]) =>
    Future<void>.delayed(d);

void main() {
  late StreamController<Object?> changes;
  late StreamController<bool> connected;
  late int fetches;
  late CollectionController<int> controller;

  setUp(() {
    changes = StreamController<Object?>.broadcast();
    connected = StreamController<bool>.broadcast();
    fetches = 0;
    controller = CollectionController<int>(
      fetcher: (_) async {
        fetches++;
        return const CollectionPage(items: [1], total: 1);
      },
    );
  });

  tearDown(() {
    changes.close();
    connected.close();
  });

  test('a burst of changes refetches once', () async {
    final binding = CollectionRealtime.bind(
      controller,
      onChanged: changes.stream,
      onConnected: connected.stream,
      coalesce: _coalesce,
    );
    addTearDown(binding.dispose);
    addTearDown(controller.dispose);
    await _wait();
    expect(fetches, 1);
    changes
      ..add(null)
      ..add(null)
      ..add(null);
    await _wait();
    expect(fetches, 2);
  });

  test('each reconnect refetches; staying up does not', () async {
    final binding = CollectionRealtime.bind(
      controller,
      onChanged: changes.stream,
      onConnected: connected.stream,
      coalesce: _coalesce,
    );
    addTearDown(binding.dispose);
    addTearDown(controller.dispose);
    await _wait();
    connected.add(true);
    await _wait();
    connected.add(true);
    await _wait();
    expect(fetches, 2);
    connected
      ..add(false)
      ..add(true);
    await _wait();
    expect(fetches, 3);
  });

  test(
    'a change pending when the controller is disposed refetches nothing',
    () async {
      final binding = CollectionRealtime.bind(
        controller,
        onChanged: changes.stream,
        onConnected: connected.stream,
        coalesce: _coalesce,
      );
      addTearDown(binding.dispose);
      await _wait();
      changes.add(null);
      controller.dispose();
      await _wait();
      expect(fetches, 1);
    },
  );

  test(
    'a change arriving after the controller is disposed is ignored',
    () async {
      final binding = CollectionRealtime.bind(
        controller,
        onChanged: changes.stream,
        onConnected: connected.stream,
        coalesce: _coalesce,
      );
      addTearDown(binding.dispose);
      await _wait();
      controller.dispose();
      changes.add(null);
      connected.add(true);
      await _wait();
      expect(fetches, 1);
    },
  );

  test('dispose cancels a pending refetch', () async {
    final binding = CollectionRealtime.bind(
      controller,
      onChanged: changes.stream,
      onConnected: connected.stream,
      coalesce: _coalesce,
    );
    addTearDown(controller.dispose);
    await _wait();
    changes.add(null);
    binding.dispose();
    await _wait();
    expect(fetches, 1);
  });
}
