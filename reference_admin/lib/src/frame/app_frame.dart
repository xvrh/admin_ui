import 'dart:async';

import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../api/shop_api.dart';
import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';
import '../routing/routes.dart';
import '../screens/pages.dart';
import '../services.dart';
import 'inbox.dart';
import 'navigation.dart';
import 'palette.dart';
import 'user_menu.dart';

/// The signed-in app around every page: the sidebar (a rail at medium
/// width, and on a phone the kit's drawer), the top bar, the offline banner
/// and the progress bar, and the page [route] names.
///
/// It stays mounted while the route changes, so its scopes, its inbox and
/// its subscription to the shop's events outlive every page.
class AppFrame extends StatefulWidget {
  final AppRoute route;

  const AppFrame({super.key, required this.route});

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> {
  late final AppServices _services = context.services;
  ShopApi get _api => _services.api;

  final _subscriptions = <StreamSubscription<Object?>>[];
  var _toShip = 0;

  /// The inbox, newest first: a listenable, as a phone shows it in a sheet
  /// above the frame.
  final _notifications = ValueNotifier<List<AppNotification>>(const []);
  late bool _online = _api.isConnected;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_api.events.listen(_onEvent))
      ..add(
        _api.connected.listen((online) => setState(() => _online = online)),
      );
    _services.appearance.addListener(_rebuild);
    _loadBadges();
    _loadInbox();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _services.appearance.removeListener(_rebuild);
    _notifications.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _api.navBadges();
      if (mounted) setState(() => _toShip = badges.toShip);
    } on ShopError {
      // The badge keeps its last count.
    }
  }

  Future<void> _loadInbox() async {
    try {
      final inbox = await _api.notifications();
      if (mounted) _notifications.value = inbox;
    } on ShopError {
      // The inbox keeps what it had.
    }
  }

  void _onEvent(ShopEvent event) {
    switch (event) {
      case NewOrderEvent(:final order):
        _loadBadges();
        _announce(order);
      case OrdersChangedEvent():
        _loadBadges();
      case NotificationEvent(:final notification):
        _notifications.value = [notification, ..._notifications.value];
      case StockLowEvent(:final product):
        if (_services.session.can(Permission.editCatalogue)) _warnLow(product);
    }
  }

  void _warnLow(Product product) {
    final strings = context.strings.shell;
    final language = Localizations.localeOf(context).languageCode;
    ToastScope.maybeOf(context)?.show(
      Toast(
        strings.stockLowToast(
          bidiIsolate(inLanguage(product.name, language)),
          product.stock,
          context.adminFormats.integer(product.stock),
        ),
        title: strings.stockLowTitle,
        icon: Icons.inventory_2_outlined,
        severity: Severity.warning,
        actionLabel: strings.view,
        onAction: () => _services.router.go(ProductDetail(product.id)),
      ),
    );
  }

  void _announce(Order order) {
    final strings = context.strings.shell;
    ToastScope.maybeOf(context)?.show(
      Toast(
        strings.newOrderToast(
          bidiIsolate(order.label),
          bidiIsolate(order.customerName),
        ),
        title: strings.newOrderTitle,
        icon: Icons.shopping_bag_outlined,
        actionLabel: strings.view,
        onAction: () => _services.router.go(OrderDetail(order.number)),
      ),
    );
  }

  void _markRead(String id) => _notifications.value = [
    for (final n in _notifications.value)
      n.id == id ? n.copyWith(read: true) : n,
  ];

  void _markAllRead() => _notifications.value = [
    for (final n in _notifications.value) n.copyWith(read: true),
  ];

  void _openPalette() => openCommandPalette(context);

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.shell;
    final route = widget.route;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final entries = navEntries(
      context,
      toShip: _toShip,
      onOpen: (to) => _services.router.go(to, confirm: false),
    );

    final topBar = TopBar(
      leading: const ShopMark(),
      menuButton: const ShellMenuButton(key: ShellKeys.menu),
      search: CommandTrigger(key: ShellKeys.search, onTap: _openPalette),
      onSearch: _openPalette,
      searchLabel: strings.searchHint,
      actions: [
        IconAction(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ShellKeys.modeToggle,
          label: dark ? strings.switchToLight : strings.switchToDark,
          onPressed: () => _services.appearance.setMode(
            dark ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
        FrameInbox(
          notifications: _notifications,
          onRead: _markRead,
          onAllRead: _markAllRead,
        ),
        const UserMenu(),
      ],
    );

    final body = Column(
      children: [
        if (!_online)
          AnnouncementBar(
            strings.offlineMessage,
            key: ShellKeys.offline,
            title: strings.offlineTitle,
            severity: Severity.warning,
            icon: Icons.cloud_off_outlined,
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: buildPage(context, route)),
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: _InFlightBar(_api.inFlight),
              ),
            ],
          ),
        ),
      ],
    );

    return CallbackShortcuts(
      bindings: {
        primaryModifierActivator(LogicalKeyboardKey.keyK): _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: Shell(
          key: ShellKeys.frame,
          sidebar: FrameSidebar(
            collapsed: AdminBreakpoint.of(context).isMedium,
            selected: route.nav,
            entries: entries,
          ),
          drawer: KeyedSubtree(
            key: ShellKeys.drawer,
            child: FrameSidebar(selected: route.nav, entries: entries),
          ),
          topBar: topBar,
          child: body,
        ),
      ),
    );
  }
}

// FRICTION(F-015): DelayedLoading waits on a frameless timer; the bar shows
// at once instead.
/// The progress bar along the top of the page while any call is running.
///
/// Shown at once rather than after a delay: `DelayedLoading` waits on a
/// timer, which draws no frame, so a scenario settling on frames would
/// photograph the page before its data. The bar animates while it shows,
/// which keeps frames coming exactly until the data lands.
class _InFlightBar extends StatefulWidget {
  final ValueListenable<int> inFlight;
  const _InFlightBar(this.inFlight);

  @override
  State<_InFlightBar> createState() => _InFlightBarState();
}

class _InFlightBarState extends State<_InFlightBar> {
  @override
  void initState() {
    super.initState();
    widget.inFlight.addListener(_changed);
  }

  @override
  void dispose() {
    widget.inFlight.removeListener(_changed);
    super.dispose();
  }

  // A call can start while the tree is building (a page's initState), when
  // marking this dirty is not allowed; it then waits for the frame's end.
  void _changed() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.inFlight.value > 0
        ? const TopProgressBar(key: ShellKeys.progress)
        : const SizedBox.shrink();
  }
}
