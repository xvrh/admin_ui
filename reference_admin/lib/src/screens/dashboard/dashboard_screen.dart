import 'dart:async';

import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import 'dashboard_view.dart';

/// `/`: the morning glance. Loads the stats for the chosen range, keeps
/// the last ones on screen while another range loads, and refreshes when
/// the shop says orders changed.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AppServices _services = context.services;
  StreamSubscription<ShopEvent>? _events;

  DashboardRange _range = DashboardRange.days30;
  DashboardData? _data;
  ShopError? _error;
  bool _loading = true;

  /// Only the latest request's answer lands: a slow 7-day answer never
  /// overwrites the 90 days asked after it.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _events = _services.api.events.listen((event) {
      if (event is NewOrderEvent || event is OrdersChangedEvent) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final range = _range;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = _services.api;
      final stats = await api.stats(range);
      // Only an empty shop needs to know whether it was set up.
      final shop = stats.isEmpty ? await api.shop() : null;
      if (!mounted || request != _request) return;
      setState(() {
        _data = DashboardData(stats: stats, shop: shop);
        _loading = false;
      });
    } on ShopError catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _data = null;
        _error = error;
        _loading = false;
      });
    }
  }

  void _setRange(DashboardRange range) {
    if (range == _range) return;
    _range = range;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = _services.session;
    return DashboardView(
      userName: session.user?.name ?? '',
      now: clock.now(),
      range: _range,
      data: _data,
      error: _error,
      loading: _loading,
      canSetUp: session.can(Permission.manageShop),
      onRange: _setRange,
      onRetry: _load,
      onOpen: context.go,
      onSetUp: () => context.go(const Setup()),
    );
  }
}
