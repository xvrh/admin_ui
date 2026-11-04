import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../api/shop_api.dart';
import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';
import '../routing/routes.dart';
import '../services.dart';

/// Where each navigation item leads.
AppRoute routeOf(Nav nav) => switch (nav) {
  Nav.dashboard => const Dashboard(),
  Nav.orders => const Orders(),
  Nav.customers => const Customers(),
  Nav.products => const Products(),
  Nav.media => const Media(),
  Nav.team => const Team(),
  Nav.settings => const SettingsAppearance(),
};

/// The permission a navigation item needs to be shown.
Permission? permissionOf(Nav nav) => routeOf(nav).permission;

String navLabel(ShellStrings strings, Nav nav) => switch (nav) {
  Nav.dashboard => strings.navDashboard,
  Nav.orders => strings.navOrders,
  Nav.customers => strings.navCustomers,
  Nav.products => strings.navProducts,
  Nav.media => strings.navMedia,
  Nav.team => strings.navTeam,
  Nav.settings => strings.navSettings,
};

IconData navIcon(Nav nav) => switch (nav) {
  Nav.dashboard => Icons.space_dashboard_outlined,
  Nav.orders => Icons.receipt_long_outlined,
  Nav.customers => Icons.people_outline,
  Nav.products => Icons.local_florist_outlined,
  Nav.media => Icons.photo_library_outlined,
  Nav.team => Icons.badge_outlined,
  Nav.settings => Icons.settings_outlined,
};

/// The sidebar's entries for the signed-in role: the items it may open,
/// grouped, each valued by its [Nav] (`Sidebar(selected:)` lights the
/// current route's), the orders item carrying [toShip].
///
/// [onOpen] is called once the sidebar has asked the leave guards, so it
/// navigates without asking again.
List<NavEntry> navEntries(
  BuildContext context, {
  required int toShip,
  required void Function(AppRoute route) onOpen,
}) {
  final strings = context.strings.shell;
  final session = context.services.session;
  NavItem? item(Nav nav) {
    final permission = permissionOf(nav);
    if (permission != null && !session.can(permission)) return null;
    return NavItem(
      navLabel(strings, nav),
      icon: navIcon(nav),
      value: nav,
      badge: nav == Nav.orders && toShip > 0
          ? context.adminFormats.integer(toShip)
          : null,
      onTap: () => onOpen(routeOf(nav)),
    );
  }

  return [
    NavSection(strings.sectionSales),
    ?item(Nav.dashboard),
    ?item(Nav.orders),
    ?item(Nav.customers),
    NavSection(strings.sectionCatalogue),
    ?item(Nav.products),
    ?item(Nav.media),
    NavSection(strings.sectionShop),
    ?item(Nav.team),
    ?item(Nav.settings),
  ];
}

/// The frame's sidebar: the entries, [selected]'s lit, and the signed-in
/// staff member at the foot. The shop's mark sits in the top bar above it,
/// where the kit's frame puts a logo; the phone's drawer heads itself with
/// the bar's.
class FrameSidebar extends StatelessWidget {
  final List<NavEntry> entries;
  final Nav? selected;
  final bool collapsed;

  const FrameSidebar({
    super.key,
    required this.entries,
    this.selected,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      entries: entries,
      selected: selected,
      collapsed: collapsed,
      footer: _SignedIn(collapsed: collapsed),
    );
  }
}

/// The page's tokens, whatever palette the chrome around [context] has
/// (Carbon's dark header has its own).
AdminTokens pageTokens(BuildContext context) {
  final appearance = context.services.appearance;
  final dark = switch (appearance.mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };
  return dark ? appearance.darkTokens : appearance.lightTokens;
}

/// The colour a staff member's avatar takes everywhere in the frame: the
/// kit's own pick, made against the page's palette.
// FRICTION(F-023): Avatar hashes its colour against the ambient palette,
// so the same person gets two colours in a top bar with its own palette;
// the kit's pick is repeated here over the page's palette and pinned.
Color staffAvatarColor(BuildContext context, String name) {
  final chart = pageTokens(context).palette.chart;
  final mid = [
    for (final c in chart)
      if (relativeLuminance(c) case final l when l >= 0.025 && l <= 0.65) c,
  ];
  final series = mid.isEmpty ? chart : mid;
  var hash = 0;
  for (final unit in name.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return series[hash % series.length];
}

/// The shop's mark and name, at the start of the top bar, in the bar's
/// palette (Carbon's dark header). A shop not named yet shows the product's
/// name.
class ShopMark extends StatelessWidget {
  const ShopMark({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.services.session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => _mark(context, session.session?.shopName),
    );
  }

  Widget _mark(BuildContext context, String? shopName) {
    final name = shopName == null || shopName.trim().isEmpty
        ? context.strings.shell.appName
        : shopName;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.yard_outlined,
          color: context.colors.primary,
          size: context.iconSizes.lg,
        ),
        const Gap(AdminSpacing.sm),
        Text(name, style: context.type.heading),
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  final bool collapsed;
  const _SignedIn({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final user = context.services.session.user;
    if (user == null) return const SizedBox.shrink();
    final avatar = Avatar(
      name: user.name,
      color: staffAvatarColor(context, user.name),
      size: 28,
    );
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: collapsed
          ? Center(
              child: Tip(message: user.name, child: avatar),
            )
          : Row(
              children: [
                avatar,
                const Gap(AdminSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: context.type.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.strings.shell.role(user.role),
                        style: context.type.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
