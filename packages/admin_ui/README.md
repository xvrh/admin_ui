# admin_ui

A Flutter UI kit for building admin apps: an app shell, data tables and
collections, forms and field bodies, overlays, media and asset pickers, charts,
and sign-in screens. It is plain Flutter with no backend: data reaches it
through small interfaces your app implements, such as a `CollectionFetcher`
(or a `LocalCollectionSource` over rows in memory), an `AssetSource` and a
`SavedViewsStore`.

Everything is themed from one set of design tokens. The kit ships six themes,
each with a light and a dark mode:

| Theme | Modelled on | Font |
|---|---|---|
| Iris | the kit's own look (the default) | Inter (bundle it as for shadcn) |
| Material | Material 3 | Roboto |
| shadcn | shadcn/ui and Radix | Inter |
| Ant | Ant Design | the platform's |
| Fluent | Fluent 2 | Segoe UI, where the system has it |
| Carbon | Carbon | IBM Plex Sans |

Any of them can take a brand accent, and you can define your own theme without
changing the package. The colour roles meet their WCAG contrast targets in
every theme, mode and brand, and the tests hold them to it. The kit works with
the keyboard and screen readers, ships English, French and Arabic strings, and
lays out right to left.

- [Install](#install)
- [material_ui, not flutter/material](#material_ui-not-fluttermaterial)
- [A minimal app](#a-minimal-app)
- [The frame at every width](#the-frame-at-every-width)
- [Routing](#routing)
- [Libraries](#libraries)
- [Layer order](#layer-order)
- [Theming](#theming)
- [Localisation and right-to-left](#localisation-and-right-to-left)
- [Forms](#forms)
- [Saved views](#saved-views)
- [A media page](#a-media-page)
- [Comments and mentions](#comments-and-mentions)
- [Version history](#version-history)
- [Ancestor scopes](#ancestor-scopes)
- [Name clashes](#name-clashes)
- [API conventions](#api-conventions)
- [The preview catalog](#the-preview-catalog)
- [Sweeps](#sweeps)
- [Testing an app on the kit](#testing-an-app-on-the-kit)

## Install

The kit is not on pub.dev. It is released as git tags of its repository,
`v0.1.0` and on, and an app depends on one:

```yaml
environment:
  sdk: ^3.13.0
  flutter: '>=3.47.0'

dependencies:
  admin_ui:
    git:
      url: https://github.com/xvrh/admin_ui.git
      path: packages/admin_ui
      ref: v0.1.0
  flutter:
    sdk: flutter
  material_ui: ^1.4.0

flutter:
  uses-material-design: true # the kit draws Material icons
```

To change the kit and an app together, point the app at a checkout of the
kit in its `pubspec_overrides.yaml`, and send the change back to the kit as
a pull request:

```yaml
dependency_overrides:
  admin_ui:
    path: ../admin_ui/packages/admin_ui
```

**Flutter 3.47 and Dart 3.13 are the floor**, set by material_ui 1.4. The
kit uses no later API: it analyzes clean against Flutter 3.47's last beta
(3.47.0-0.4.pre). Its other dependencies take caret constraints.

**Build the app on material_ui**, as the next section explains. A kit widget
under a `MaterialApp` from `package:flutter/material.dart` finds no theme
it can read: a debug build throws a `FlutterError` that names the fix, and a
release build draws the Iris defaults.

**Wire it as [the minimal app](#a-minimal-app) does**: `buildAppTheme` for
`theme` and `darkTheme`, `AdminLocalizations.localizationsDelegates` and
`supportedLocales`, a `ToastScope` in `MaterialApp.builder`, and
`AdminScope` around the home page, which mounts the scopes the kit's
widgets need (see [Ancestor scopes](#ancestor-scopes)). Import the barrels,
never `package:admin_ui/src/…`: the `src` tree moves between releases.

### Fonts

Four themes name a font: Iris and shadcn Inter, Material Roboto and Carbon
IBM Plex Sans. Ant uses the platform's font, and Fluent names Segoe UI,
which it gets only where the system has it. `defaultTokens`, what the kit
draws with when no theme is above it, is Iris's palette and metrics in the
platform's font.

The kit ships no font file and fetches none, so an app pays for no font it
did not choose and calls no font server unless it asks to. A theme's family
draws where the app bundles it, and in the platform's font where it does
not. To draw a theme in its own font, bundle the family under its name:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Italic.ttf
          style: italic
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

The example bundles Inter, Roboto and IBM Plex Sans this way, with their
OFL licences, in `example/assets/fonts/`.

To load a family another way, fetching it from Google Fonts at runtime
say, hand the kit a resolver before the first theme is built. It is called
with the family of a theme's text, and returns null to leave a family the
kit should set as it is:

```dart
void main() {
  AdminFonts.resolver = (family, style) =>
      GoogleFonts.asMap().containsKey(family)
      ? GoogleFonts.getFont(family, textStyle: style)
      : null;
  runApp(const MyAdmin());
}
```

### Platform notes

- **Picking files.** `showAssetPicker`'s upload tab opens the system file
  dialog through `file_picker`. A sandboxed macOS app needs the
  `com.apple.security.files.user-selected.read-only` entitlement in both
  `DebugProfile.entitlements` and `Release.entitlements`. On iOS, add
  `NSPhotoLibraryUsageDescription` to `Info.plist` for images and videos,
  and `NSAppleMusicUsageDescription` for audio; `file_picker` 13 needs iOS
  14 or later. `file_picker`'s setup guide covers the other platforms.
- **Fetching fonts.** A sandboxed macOS app whose font resolver fetches
  over the network needs `com.apple.security.network.client`.
- **Plugins.** `desktop_drop` (drop targets), `file_picker` (the picker),
  `url_launcher` (menu links) and `pointer_interceptor` (overlays above web
  platform views) are plugins, so every app that depends on the kit
  registers them, whichever barrels it imports.

### Licence

BSD 3-Clause; see [LICENSE](LICENSE).

### Versions

Below 1.0, a breaking change bumps the minor version (`0.1.0` to `0.2.0`)
and anything else the patch. A change of look counts as breaking: a token's
default, or a widget's shape, moves pixels in every app on the kit. The
CHANGELOG lists each release's look changes under a heading of their own.

A rename keeps the old name, deprecated, with a `dart fix` rule to the new
one, until the next breaking release removes it. [`api.txt`](api.txt)
lists the public surface and [`looks.txt`](looks.txt) every theme's
resolved tokens, so a release's diff of the two shows which bump it needs.

## material_ui, not flutter/material

The kit is built on [`material_ui`](https://pub.dev/packages/material_ui) and
`cupertino_ui`, the standalone copies of Material and Cupertino. Import those,
never `package:flutter/material.dart` or `package:flutter/cupertino.dart`:

```dart
import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';
```

The two copies of Material define different types with the same names. The
kit's tokens are a `ThemeExtension` on material_ui's `Theme`, so a `MaterialApp`
from `package:flutter/material.dart` installs a `Theme` the kit cannot see.
That app still compiles, but:

- in a debug build, the first kit widget to read a token throws a
  `FlutterError`, which says to build the app with material_ui's
  `MaterialApp` and `theme: buildAppTheme(tokens)`;
- in a release build, every kit widget falls back to the default tokens
  (Iris, light) and ignores your theme.

`AdminScope(tokens: …)` does not make such an app work: it gives the kit a
theme, but the kit's dialogs still find no material_ui
`MaterialLocalizations` and throw. An app on the SDK's `MaterialApp` is not
supported.

Under material_ui's `MaterialApp` with a theme that `buildAppTheme` did not
build, the kit also draws Iris light, and a debug build prints a warning
once. Localisations are the same: register material_ui's delegates, not
those from `flutter_localizations`.

To move existing code over, run material_ui's fix, then check that no
`package:flutter/material.dart` import is left:

```sh
dart fix --apply --code=migrate_design_widgets
```

## A minimal app

```dart
import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

class MyAdmin extends StatelessWidget {
  const MyAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = adminThemes.first; // Iris
    return MaterialApp(
      title: 'My admin',
      theme: buildAppTheme(theme.tokens),
      darkTheme: buildAppTheme(theme.dark ?? theme.tokens),
      themeMode: ThemeMode.system,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      // Above the Navigator, so toasts paint over route dialogs too.
      // AdminScope uses this one.
      builder: (context, child) => ToastScope(child: child!),
      // Inside the home route, so back closes a modal before the page.
      home: const AdminScope(child: HomePage()),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      sidebar: Sidebar(
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            selected: true,
            onTap: () {},
          ),
          NavItem('Orders', icon: Icons.receipt_long_outlined, onTap: () {}),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: PageScaffold(
        title: 'Home',
        actions: [
          Button(
            'Say hello',
            variant: ButtonVariant.primary,
            onPressed: () => ToastScope.of(context).show(const Toast('Hello')),
          ),
        ],
        body: Text('Welcome', style: context.type.body),
      ),
    );
  }
}
```

`buildAppTheme(tokens)` returns a material_ui `ThemeData` that carries the
tokens and styles the stock Material widgets (inputs, menus, dialogs, snack
bars, selection controls) from them. `buildAppTheme(defaultTokens)` is Iris
light in the platform's font; `buildAppTheme(irisTheme.tokens)` is Iris in
Inter.

`AdminScope` mounts the scopes the kit's widgets reach for: the command
registry, the anchor that modals open on, and a `ToastScope` when the app
has none above it. A material_ui app whose theme `buildAppTheme` did not
build can pass the kit one, `AdminScope(tokens: irisTheme.tokens, child: …)`,
which themes that subtree and the dialogs opened from it.

A route pushed on the Navigator is not below the home route, so none of
those scopes reach it. A routed app keeps one frame under one
`AdminScope` and swaps its page body instead ([Routing](#routing)); a
page pushed all the same gets an `AdminScope` of its own (pass the same
`commands` and `leaveGuards` to share them), and the whole app is themed
with `buildAppTheme` rather than through `tokens:`.

Read the tokens anywhere below the app with `context.adminTokens`, or one
part of them with the short getters of the `AdminTokensContext` extension:
`context.colors` (the palette), `context.type`, `context.radii`,
`context.elevation`, `context.focus`, `context.sizes` and
`context.tableMetrics`. Spacing is the `AdminSpacing` constants
(`AdminSpacing.md` is 8).

## The frame at every width

`Shell` lays out by its own width against the theme's breakpoints
(`context.breakpoints`, see [Breakpoints](#breakpoints)):

- **Compact**, under `medium` (600): the page takes the whole width. The
  navigation is in a drawer from the start edge, which the `TopBar` opens
  from the menu button it then leads with. `Shell.openDrawer(context)`
  opens it from anywhere below the shell, and `Shell.isCompact(context)`
  says whether the frame is compact.
- **Medium and expanded**: the `sidebar` stands beside the page. An app
  that wants the rail between the breakpoints passes
  `Sidebar(collapsed: AdminBreakpoint.of(context).isMedium)`.

A sidebar's `header` and `footer` fit the rail by reading
`Sidebar.isCollapsed(context)`, which is false in the drawer. The
signed-in account goes in the footer as a `SidebarAccount`, which does
this itself.

The drawer holds the `sidebar`, expanded, or `Shell(drawer:)` when the
app gives it one of its own (to key it, say). Its head is as tall as the
top bar, with a close button where the bar has its menu button and the
top bar's `leading` where the bar has it, so the logo does not move as
the drawer covers it. That `leading` is then built twice, so a logo that
carries a `GlobalKey`, or that of a top bar of the app's own, goes to the
head as `Shell(drawerLeading:)`, built apart. It opens on the
`ModalAnchor` of the `AdminScope` above the shell, and so sees the scopes
the page does: an item asks the page's leave guards first, then closes the
drawer and navigates, or opens a modal on that anchor, which shows once
the drawer has gone. The scrim, Escape and back close it. A frame of the app's own opens the same
drawer with `showNavigationDrawer(context, sidebar: …, leading: …)`.

The menu button is a `ShellMenuButton`. Pass one to key it, or a trigger
of your own that calls `Shell.openDrawer`:
`TopBar(menuButton: const ShellMenuButton(key: Keys.menu), …)`.

On a device with insets (a camera island, a home indicator), the top bar
runs under the status bar in its own colour and the sidebar keeps the
bottom inset under its footer in its own, in the rail and in the drawer
alike. A `SideSheet` keeps its parts clear of the insets at their edges;
`SideSheet(safeArea: false)` leaves the body's to a child that paints its
own background under them.

The notifications follow the same split: `NotificationCenter` drops its
inbox down from the bell where there is room, and on a phone a
`NotificationBell` opens a `NotificationInbox` in a sheet as wide as the
screen:

```text
NotificationBell(
  unreadCount: unread,
  onPressed: () {
    final modals = ModalAnchor.of(context);
    modals.showSheet<void>(
      width: double.infinity,
      builder: (context) => SideSheet(
        semanticLabel: 'Notifications',
        child: NotificationInbox(
          sections: sections,
          onMarkAllRead: markAllRead,
          onDismiss: modals.close,
        ),
      ),
    );
  },
)
```

## Routing

`AdminScope`'s scopes reach only what is below it, and a page pushed on
the Navigator is beside the home route, not below it. So a routed app
keeps one Navigator page for the signed-in app: one frame under one
`AdminScope`, whose page body the route swaps. Every page then shares the
leave guards, the commands and the modal anchor (the phone's drawer and
every dialog open there, and back closes them before the page), and the
frame, with its sidebar, its inbox and its subscriptions, stays mounted
from page to page.

Route with flutterware's `router_outlet`, unless the browser's back button
and a deep link must ask a page with unsaved edits before they leave it:
then write the router yourself, as in
[the second recipe](#leave-guards-on-back-and-deep-links). The kit does
not depend on flutterware; an app that routes with it adds it to its own
dependencies.

### With router_outlet

`package:flutterware/router_outlet.dart` maps the URL onto nested
outlets. `RouterOutlet.root`, above the
`MaterialApp`, reads and writes the browser's URL. A `RouterOutlet` in the
`Shell`'s body picks the page from the path's next segment, and a page
holds an outlet of its own for what follows it (`/orders/42`).

- `context.go('orders')` navigates relative to the outlet it is called
  under; a path starting with `/` is absolute.
- `context.router.isSelected('orders')` lights a sidebar item, on
  `/orders/42` too: pass it as `NavItem(selected:)`.
- A sidebar item asks the leave guards before it calls `onTap`, so it
  navigates without asking again. Any other link (a command, a button, a
  row) asks `LeaveGuardScope.confirmLeave` first, as `go` below does.
- `router_outlet` does not stop the browser's back button or a URL typed
  in the address bar: those leave the page without asking its guards.

```dart
import 'package:admin_ui/admin_ui.dart';
import 'package:flutterware/router_outlet.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

class MyAdmin extends StatelessWidget {
  const MyAdmin({super.key});

  // The root reads and writes the browser's URL; outlets below match it.
  @override
  Widget build(BuildContext context) => RouterOutlet.root(
    child: MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      builder: (context, child) => ToastScope(child: child!),
      home: const AdminScope(child: Frame()),
    ),
  );
}

/// The one frame: its body is the outlet, which follows the URL.
class Frame extends StatelessWidget {
  const Frame({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Shell(
      sidebar: Sidebar(
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            selected: router.isSelected('home'),
            onTap: () => context.go('home'),
          ),
          NavItem(
            'Orders',
            icon: Icons.receipt_long_outlined,
            // Lit on /orders/42 too.
            selected: router.isSelected('orders'),
            onTap: () => context.go('orders'),
          ),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: RouterOutlet({
        'home': (_) => const PageScaffold(title: 'Home', body: SizedBox()),
        'orders': (_) => const OrdersPage(),
      }, onNotFound: (_) => 'home'),
    );
  }
}

/// The orders and one order: an outlet of its own, matching what follows
/// /orders in the URL.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) => RouterOutlet({
    '': (_) => PageScaffold(
      title: 'Orders',
      body: Builder(
        // Relative to this outlet: /orders/42.
        builder: (context) =>
            TextLink('Order 42', onPressed: () => go(context, '42')),
      ),
    ),
    ':number': (path) =>
        PageScaffold(title: 'Order ${path['number']}', body: const SizedBox()),
  });
}

/// Opens [route] once the page's leave guards let it go. A sidebar item asks
/// them before its `onTap`; every other link in the app comes through here.
Future<void> go(BuildContext context, String route) async {
  if (!await LeaveGuardScope.confirmLeave(context)) return;
  if (context.mounted) context.go(route);
}
```

### Leave guards on back and deep links

A `RouterDelegate` of your own sees every change of route, the browser's
back and a deep link included, and can ask the page's leave guards before
it lets one through. The reference app (`reference_admin/`, beside the
kit in its repository) routes this way, in about 150 lines with its route
parser, for the edits its product and settings pages hold.

- Each route names the destination it belongs to, and the frame passes
  it as `Sidebar(selected: route.section)`, the items valued with
  `NavItem(value:)`: a detail page lights its list's item with no
  bookkeeping.
- A sidebar item asks the leave guards before it calls `onTap`, so it
  navigates without asking again. Any other change of route (a link, a
  deep link, the browser's back, signing out) asks
  `LeaveGuardScope.confirmLeave` first, with a context below the scope:
  a `GlobalKey` on the frame. When the user stays, the delegate notifies
  anyway, so the browser's URL goes back to the page kept.
- The signed-out page is the Navigator's other page, under an
  `AdminScope` of its own; pass both scopes the same `leaveGuards`
  registry. A page that must be pushed (a full-screen editor) gets its
  own `AdminScope` with the same `commands` and `leaveGuards`.

```dart
import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

/// The sidebar's destinations.
enum Section { home, orders }

/// Every page: its URL, and the destination the sidebar lights for it.
sealed class AppRoute {
  const AppRoute();
  Uri get uri;
  Section get section;
}

class HomeRoute extends AppRoute {
  const HomeRoute();
  @override
  Uri get uri => Uri(path: '/');
  @override
  Section get section => Section.home;
}

class OrderRoute extends AppRoute {
  final int? number;
  const OrderRoute([this.number]);
  @override
  Uri get uri => Uri(path: number == null ? '/orders' : '/orders/$number');
  @override
  Section get section => Section.orders;
}

class RouteParser extends RouteInformationParser<AppRoute> {
  @override
  Future<AppRoute> parseRouteInformation(RouteInformation info) async =>
      switch (info.uri.pathSegments) {
        ['orders'] => const OrderRoute(),
        ['orders', final n] => OrderRoute(int.tryParse(n)),
        _ => const HomeRoute(),
      };

  @override
  RouteInformation restoreRouteInformation(AppRoute route) =>
      RouteInformation(uri: route.uri);
}

class AppRouter extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  /// On the frame, below its AdminScope: where leaving is asked from.
  final _frame = GlobalKey();

  AppRoute _route = const HomeRoute();

  @override
  AppRoute get currentConfiguration => _route;

  /// Opens [route] once the page's leave guards let it go. A sidebar item
  /// has asked them itself, and passes [asked].
  Future<void> go(AppRoute route, {bool asked = false}) async {
    final frame = _frame.currentContext;
    if (!asked && frame != null && !await LeaveGuardScope.confirmLeave(frame)) {
      // Stayed: puts the browser's URL back on the page kept.
      notifyListeners();
      return;
    }
    _route = route;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) => go(configuration);

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    // One page: the frame stays, and its body follows the route.
    pages: [
      MaterialPage<void>(
        child: AdminScope(
          child: Frame(key: _frame, route: _route, router: this),
        ),
      ),
    ],
    onDidRemovePage: (_) {},
  );
}

class Frame extends StatelessWidget {
  final AppRoute route;
  final AppRouter router;

  const Frame({super.key, required this.route, required this.router});

  @override
  Widget build(BuildContext context) {
    return Shell(
      sidebar: Sidebar(
        selected: route.section,
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            value: Section.home,
            onTap: () => router.go(const HomeRoute(), asked: true),
          ),
          NavItem(
            'Orders',
            icon: Icons.receipt_long_outlined,
            value: Section.orders,
            onTap: () => router.go(const OrderRoute(), asked: true),
          ),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: switch (route) {
        HomeRoute() => const PageScaffold(title: 'Home', body: SizedBox()),
        OrderRoute(:final number) => PageScaffold(
          title: number == null ? 'Orders' : 'Order $number',
          body: const SizedBox(),
        ),
      },
    );
  }
}

class MyAdmin extends StatefulWidget {
  const MyAdmin({super.key});

  @override
  State<MyAdmin> createState() => _MyAdminState();
}

class _MyAdminState extends State<MyAdmin> {
  final _router = AppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    theme: buildAppTheme(irisTheme.tokens),
    localizationsDelegates: AdminLocalizations.localizationsDelegates,
    supportedLocales: AdminLocalizations.supportedLocales,
    builder: (context, child) => ToastScope(child: child!),
    routerDelegate: _router,
    routeInformationParser: RouteParser(),
  );
}
```

## Libraries

Import `package:admin_ui/admin_ui.dart` for everything, or a narrower barrel:

| Barrel | Contents |
|---|---|
| `theme.dart` | Tokens, the six themes, `buildAppTheme`, `AdminAppearance` |
| `widgets.dart` | Primitives: buttons, inputs and their decoration (`fieldInputDecoration`), menus, popovers, modals, toasts, tabs, charts, calendar, command palette, the notification inbox (`NotificationCenter`, `NotificationInbox`, `NotificationBell`), `StatusPill` and `StatusDot`, attention tiles (`AttentionGrid`) |
| `shell.dart` | `Shell` and its phone drawer (`showNavigationDrawer`, `ShellMenuButton`), `Sidebar`, `TopBar`, page headers and scaffolds, `SaveBar` and its `SaveCluster`, `AppearancePicker` |
| `auth.dart` | Sign-in and password forms |
| `history.dart` | Revision and diff views, and `VersionDiff.of` to build a diff from two records |
| `l10n.dart` | `AdminLocalizations`, formats, shortcut labels |
| `fields.dart` | Field bodies, the pure views over a typed `Cell`; the language lanes and their model (`LocaleInfo`, `LocaleStatus`, `LangScope`); `SourceTargetPair`; `ChangeScope`; `FormGrid` |
| `forms.dart` | Cells, `bind()` and its `FieldBinder` hook, field presets, `ValueFormController` and `ValueForm`, `Validators`, `FormWizard`, `FormSaveBar`, `AssetDetailView` |
| `collection.dart` | `CollectionController`, `CollectionTable`, cards, kanban, toolbar, saved views and `showSaveViewDialog`; `AsyncValueController` and `AsyncValueBuilder` for one value outside a table |
| `assets.dart` | `AssetSource`, the asset library, its `AssetLibraryController` and the picker, `AssetBody`, the image cropper |
| `comments.dart` | Field comment anchors and mentions: `MentionField` to write them, `MentionText` to show them |
| `testing.dart` | Test support, not re-exported by `ui.dart` or `admin_ui.dart`: `loadAdminFonts`, `withTestFontFallback`, `textWithoutFont` (see [Testing an app on the kit](#testing-an-app-on-the-kit)) |
| `ui.dart` | `theme`, `widgets`, `shell`, `auth`, `history` and `l10n` |
| `admin_ui.dart` | `ui.dart` plus `fields`, `forms`, `collection`, `assets` and `comments` |

The barrels are generated by `tool/gen_barrels.dart`, which exports each
file's public symbols with an explicit `show` list. The helpers the widgets are
built from stay in `src/`. [`api.txt`](api.txt) lists every exported symbol,
so a change to the public surface shows in review. Run
`dart run tool/gen_barrels.dart` after adding or removing a public
declaration; `test/barrels_test.dart` fails until you do.

## Layer order

Each directory of `lib/src` sits on a layer. A file imports only its own
directory and the layers below it: never a higher layer, never another
directory on its own layer, and never a public barrel of the package. A lower
layer can then be used, tested and moved without what is built on it.

| Layer | Directory | Holds |
|---|---|---|
| 0 | `theme` | Tokens, palettes and the six themes |
| 1 | `l10n` | The kit's strings, formats, bidi helpers and shortcut labels |
| 2 | `common` | The primitives of `widgets.dart`, input decoration, the status pill, attention tiles |
| 3 | `i18n` | The language model: `LocaleInfo`, `LocaleStatus`, `LaneLanguage`, `languageName`, `LangScope` |
| 4 | `shell`, `auth` | The app frame, the save bar and its cluster; the sign-in and password forms |
| 5 | `history`, `comments`, `collection` | Diff and version views; comment anchors and mentions; the collection model, tables and views |
| 6 | `fields` | Field bodies, `FieldShell`, `ChangeScope`, the language lanes, `SourceTargetPair` |
| 7 | `assets` | The media library, picker, cropper and `AssetBody` |
| 8 | `forms` | Cells, `bind()` and `FieldBinder`, field presets, `FormController`, the form save bar, the asset form fields |
| 9 | `testing` | The test-support library: real fonts in widget tests, the check for text drawn in none |

No import breaks the order. A module contributes its asset providers
through `AdminModule.extensions`, a list of any type, which the app reads
back with `extensionsOf<ExternalAssetProvider>()`, so `shell` never names a
type of `assets`.

[`test/layers_test.dart`](test/layers_test.dart) enforces the order. It parses
every import and export under `lib/src`, conditional ones included, and fails
with the file, the line and the rule broken. A new directory of `lib/src`
needs a layer in its table. The test keeps an `allowed` list for a
deliberate exception, which is empty; an allowed import that is no longer
there fails, so the list only shrinks.

## Theming

### Themes, dark mode and brand accents

`adminThemes` is the unmodifiable list of shipped themes: `irisTheme`,
`materialTheme`, `shadcnTheme`, `antTheme`, `fluentTheme` and `carbonTheme`.
Each `AdminTheme` has a `name`, light `tokens` and optional `dark` tokens. To
offer more themes, build your own list, for example `[...adminThemes, myTheme]`.

Listing themes loads nothing. A theme builds its tokens, and calls the font
resolver if the app set one, the first time `tokens` or `dark` is read (see
[Fonts](#fonts)).

To brand a theme for a client, swap only the accent:

```dart
final brand = carbonTheme.branded('Carbon (Acme)', const Color(0xFF0D9488));
// or, on one token set:
final tokens = shadcnTheme.tokens.branded(const Color(0xFFE11D48));
```

`branded(seed)` makes the seed the primary colour. If needed, it nudges the
seed's lightness until the text on a primary fill reaches 4.5:1. It then
re-derives every role that comes from the primary: hover and pressed fills,
text-safe primary, focus ring, selected navigation item, selected table row
and the soft fill. It does the same in the sidebar and top-bar palettes a
theme's shell carries (Ant's dark sider, Carbon's header). Surfaces, text,
status colours, the field and neutral fills, radii, typography and chart
colours are left unchanged.

### Appearance

`AdminAppearance` holds how an app looks, as one value: a `theme`, a
`mode` (`ThemeMode`), an optional brand `accent` and the tables'
`density`. `tokens(brightness)` is the token set to draw with: the
theme's light or dark set (a light-only theme's light set in both),
branded with the accent. `themeData(brightness)` is `buildAppTheme` of
it. Both are built once per theme, accent and brightness, so rebuilding
the `MaterialApp` on every change costs no new tokens.

`AppearancePicker` edits one, and applies each change at once through
`onChanged`: the theme as a radio list, Light, Dark or System, the
accents as swatches after the theme's own colour (`adminAccents` unless
you pass `accents:`), and the table density (`showDensity: false` drops
it). Its labels, modes, densities and the kit's accent names are in the
app's language; theme names stay as they are. Where the mode or density
segments would cut a label, they turn into a radio list.

```dart
class MyAdmin extends StatefulWidget {
  const MyAdmin({super.key});

  @override
  State<MyAdmin> createState() => _MyAdminState();
}

class _MyAdminState extends State<MyAdmin> {
  var _look = AdminAppearance(theme: irisTheme);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _look.themeData(Brightness.light),
      darkTheme: _look.themeData(Brightness.dark),
      themeMode: _look.mode,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xxl),
          child: AppearancePicker(
            value: _look,
            onChanged: (look) => setState(() => _look = look),
          ),
        ),
      ),
    );
  }
}
```

The picker keeps nothing and saves nothing. Store `_look.toJson()` with
the user's preferences and read it back with
`AdminAppearance.fromJson(json, themes: myThemes)`: a theme is kept by
its name, and a name the list no longer has reads as its first theme. A
language or motion setting is the app's, in rows of its own beside the
picker. The density changes no token: pass it to the app's tables,
`CollectionTable(density: look.density)`.

### A theme of your own

`AdminTheme.from` builds a theme from a name, a light palette and an optional
dark one. Everything else is optional:

```dart
final acmeTheme = AdminTheme.from(
  name: 'Acme',
  palette: irisPalette.copyWith(
    primary: const Color(0xFF2563EB),
    primaryStrong: const Color(0xFF1D4ED8),
    primarySubtle: const Color(0xFFDBEAFE),
    primaryFaint: const Color(0xFFEFF6FF),
  ),
  dark: irisDarkPalette.branded(const Color(0xFF2563EB)),
  radii: const AdminRadii(radiusSmall: 4, radius: 6, radiusLarge: 10),
  type: const AdminTypeSpec(fontFamily: 'Inter', uppercaseLabels: false),
  sizes: const AdminControlSizes(small: 28, medium: 36, large: 44),
  table: const AdminTableMetrics(
    rowCompact: 36,
    rowStandard: 48,
    rowComfortable: 60,
    headerHeight: 44,
    cellPaddingX: 12,
    selectionColumnWidth: 44,
  ),
);
```

`AdminTheme.from` also takes `elevation`, `darkElevation`, `focus`, `motion`,
`stroke`, `iconSizes`, and the anatomy: `field`, `button`, `shell` and
`darkShell` (see [Anatomy](#anatomy)). If you leave them out, the dark set
gets `defaultDarkElevation`, the light set `defaultElevation`, the focus ring
`AdminFocusSpec()`, the dark set the light `shell`, and the rest the kit's own
(`defaultMotion`, `AdminStroke()`, `AdminIconSizes()`, `AdminFieldStyle()`,
`AdminButtonStyle()`, `AdminShellStyle()`). The type ramp comes with the type spec:
`AdminTypeSpec(ramp: …)`, `defaultTypeRamp` when left out. To build a single
token set without a theme, use `AdminTokens.from(palette: …)` with the same
optional parameters.

### Palette roles

`AdminPalette` has 22 required colours, grouped in families. Within each family
the plain name is the main step, and `Subtle` and `Faint` step toward
`surface`, in light and dark mode alike.

| Role | Used for |
|---|---|
| `primary` | The brand accent: primary buttons, selected controls |
| `primaryStrong` | `primary` a step deeper; the hover fill derives from it |
| `primarySubtle` | A soft primary tint: a selected item's fill |
| `primaryFaint` | A fainter tint, nearer `surface`: an unread row, a previewed selection |
| `surface` | Cards, inputs and overlays (Material's `ColorScheme.surface`) |
| `background` | The page and its rails, under the cards |
| `surfaceMuted` | A muted well: table headers, nested panels |
| `foreground` | Body text and icons |
| `foregroundSecondary` | Field and section labels, quiet buttons |
| `foregroundMuted` | Supporting text at 4.5:1: captions, hints, secondary cells |
| `foregroundSubtle` | Tertiary glyphs and text, not held to 4.5:1 |
| `foregroundFaint` | Disabled glyphs, decorative marks, unfilled tracks |
| `border` | Dividers, card edges, rules |
| `borderSubtle` | A fainter rule: row rules, nested separators |
| `success`, `warning`, `danger`, `info` | Status accents for fills, dots and borders |
| `warningText` | `warning` as text, at 4.5:1 |
| `highlight` | The fill behind text that a comment is anchored to |
| `modifiedFill` | A field whose value differs from the one it overrides |
| `tabDivider` | The rule under a tab bar |

The other roles are optional. When you leave one out, it is derived from the
required roles to meet its contrast target. Set one only when the derived value
is not the look you want:

| Role | Derived from |
|---|---|
| `onPrimary`, `onDanger`, `onSuccess`, `onWarning`, `onInfo` | White or near-black, whichever contrasts more with the fill |
| `primaryText`, `dangerText`, `successText`, `infoText` | The accent, adjusted to 4.5:1 on `surface`, `background` and its own tint |
| `primaryHover`, `primaryActive` | `primaryStrong`, or an 8% / 12% state layer on a light primary |
| `dangerHover`, `dangerActive` | `danger`, stepped the way the primary is |
| `focusRing` | `primary` where it reaches 3:1 (on `fieldFill` too), otherwise `primaryText` |
| `controlBorder` | `border` moved toward `foreground` until it reaches 3:1; for input outlines and unchecked controls |
| `controlAccent` | `primary` where it reaches 3:1 (on `fieldFill` too), otherwise `primary` lightened or darkened (hue kept) until it does; for checked, selected and on controls, and an accent-focused field |
| `fieldFill`, `fieldFillHover`, `fieldRule` | `surface`, `hoverOverlay` over it, and `controlBorder` held to 3:1 on the fill and the page: a field's box and the bottom rule of a filled or underlined one |
| `softFill`, `onSoft` | `primarySubtle`, and `primaryText` held to 4.5:1 on it: a soft (tonal) button |
| `neutralFill`, `neutralFillHover`, `neutralFillActive`, `onNeutralFill` | `foregroundSecondary`, `surface` over it at the hover and pressed opacities, and white or near-black on it: a filled neutral button (Carbon's secondary) |
| `placeholder` | `foregroundMuted`, or `foregroundSubtle` adjusted to 4.5:1 |
| `listHighlight`, `separator` | `foreground` over `surface` at 6% (8% dark), and the stronger of `border` and `borderSubtle`: menu hover rows and overlay dividers |
| `navHoverFill`, `navSelectedFill`, `navSelectedText`, `navIndicator` | `foreground` over `background`, `primarySubtle`, `primaryText` and `primary`, each held to its contrast floor: the sidebar's items |
| `tableRowStripe`, `tableRowHover`, `tableRowSelected`, `tableRowSelectedHover` | Neutral `foreground` washes, and `primary` mixed into `surface`: a data table's row fills |
| `scrim`, `shadow` | Black at 45% (60% in dark mode), and black |
| `chart` | An 8-colour categorical ramp, each at 3:1 on `surface` and `background` |

A few roles are always derived, and follow whatever the roles above resolve to:

| Role | Derived from |
|---|---|
| `onControlAccent` | `onPrimary` while `controlAccent` is `primary`, otherwise white or near-black on it; for the check glyph and a toggle's knob |
| `controlAccentHover` | `primaryHover` while `controlAccent` is `primary`, otherwise `controlAccent` stepped the way `primaryHover` steps `primary` |
| `foregroundMutedOnTint` | `foregroundMuted`, adjusted to 4.5:1 on every tinted fill (`surfaceMuted`, `primarySubtle`, `primaryFaint`, `listHighlight`, the selected table rows, a hovered `surface`); for captions and SKUs in selected or highlighted rows |

`palette.colorScheme` maps every role to Material's `ColorScheme`, so stock
Material widgets follow the palette too.

### Control sizes and table density

`AdminControlSizes` sets the height of every button, input and field trigger at
three sizes, so controls line up in a row. Each theme uses the ramp of its
design system:

| Theme | small / medium / large |
|---|---|
| Iris | 28 / 36 / 40 |
| shadcn | 32 / 36 / 40 |
| Material | 32 / 40 / 48 |
| Ant | 24 / 32 / 40 |
| Fluent | 24 / 32 / 40 |
| Carbon | 32 / 40 / 48 |

Every control with a size takes `size: ControlSize` (`small`, `medium` or
`large`), buttons included. `context.sizes.height(size)` returns the height.

`AdminTableMetrics` sets a data table's row heights at each `TableDensity`,
along with the header height and the cell padding. Choose a density per table
with `CollectionTable(density: TableDensity.compact)`, and read the metrics
with `context.tableMetrics`.

| Theme | compact / standard / comfortable | header | cell padding |
|---|---|---|---|
| Iris | 40 / 52 / 64 | 44 | 12 |
| Material | 36 / 52 / 64 | 56 | 16 |
| shadcn | 40 / 48 / 56 | 40 | 8 |
| Ant | 40 / 48 / 56 | 48 | 8 |
| Fluent | 32 / 44 / 52 | 44 | 8 |
| Carbon | 40 / 48 / 64 | 48 | 16 |

### Type ramp

`AdminTypeSpec.ramp` is the theme's type scale: an `AdminTypeRamp` holding one
`AdminTypeStep` per role, a whole-pixel size on a fixed line with the role's
own letter spacing. `AdminTypography.from` builds each `context.type` style
from its step: the size times `AdminTypeSpec.scale`, `height` set to line over
size with the leading split evenly, and the step's letter spacing plus
`AdminTypeSpec.tracking`, which the shipped themes leave at 0. A line of text
therefore takes the same box in every font, and a control sized from the line
centres its text. Weights come from the spec (`heading`, `label`, `strong`,
`body`), colours from the palette.

Each theme takes its steps from its design system. Values are size/line, with
the letter spacing after them where it is not 0:

| Role | Iris | Material | shadcn | Ant | Fluent | Carbon |
|---|---|---|---|---|---|---|
| `pageTitle` | 22/28 | 24/32 | 24/32 −0.6 | 20/28 | 24/32 | 28/36 |
| `heading` | 16/24 | 16/24 +0.15 | 18/28 −0.45 | 16/24 | 16/22 | 16/22 |
| `sectionLabel` | 12/16 +0.3 | 12/16 +0.5 | 12/16 | 12/20 | 12/16 | 14/18 +0.16 |
| `fieldLabel` | 12/16 | 12/16 +0.4 | 14/20 | 14/22 | 14/20 | 12/16 +0.32 |
| `fieldText` | 13/20 | 16/24 +0.5 | 14/20 | 14/22 | 14/20 | 14/18 +0.16 |
| `fieldDescription` | 12/16 | 12/16 +0.4 | 14/20 | 14/22 | 12/16 | 12/16 +0.32 |
| `fieldMessage` | 12/16 | 12/16 +0.4 | 14/20 | 14/22 | 12/16 | 12/16 +0.32 |
| `body` | 13/20 | 14/20 +0.25 | 14/20 | 14/22 | 14/20 | 14/20 +0.16 |
| `bodySmall` | 12/18 | 12/16 +0.4 | 12/16 | 12/20 | 12/16 | 12/16 +0.32 |
| `caption` | 12/16 | 12/16 +0.4 | 12/16 | 12/20 | 12/16 | 12/16 +0.32 |
| `micro` | 11/14 +0.2 | 11/16 +0.5 | 12/16 | 12/20 | 10/14 | 12/16 +0.32 |
| `button` | 13/20 | 14/20 +0.1 | 14/20 | 14/22 | 14/20 | 14/18 +0.16 |
| `buttonSmall` | 12/16 | 14/20 +0.1 | 14/20 | 14/22 | 12/16 | 14/18 +0.16 |
| `mono` | 13/20 | 14/20 | 14/20 | 14/22 | 14/20 | 14/20 +0.32 |
| `monoSmall` | 12/16 | 12/16 | 12/16 | 12/20 | 12/16 | 12/16 +0.32 |

- **Iris** is the kit's own, set in Inter: 13/20 body and control text,
  12/16 labels, captions, descriptions and messages. Inter's ascent less its
  descent is its cap height, so an evenly led line centres its capitals in
  a control, on every platform.
- **Material** is M3's type scale: `bodyMedium` for body, `bodySmall` for
  captions and labels, `labelLarge` for buttons, `labelMedium` and
  `labelSmall` for section labels and micro text, `titleMedium` for headings,
  `headlineSmall` for page titles, and `bodyLarge` for a field's text, as in
  an M3 text field.
- **shadcn** is Tailwind's: `text-sm` (14/20) for body, controls, labels and
  a form's description and message, `text-xs` (12/16) below it, `text-lg` and
  `text-2xl` headings. Headings take `tracking-tight` (−0.025em); nothing
  smaller is tracked.
- **Ant** is its 14px base on a 22px line, a form item's help and explain
  lines included, `fontSizeSM` (12/20) below it, and the `fontSizeHeading`
  steps above.
- **Fluent** is the Fluent 2 ramp: `body1` (14/20), `caption1` (12/16),
  `caption2` (10/14) for micro text, `subtitle2` for headings and `title3` for
  page titles.
- **Carbon** is the productive set: `body-01` for body, `body-compact-01` in
  controls and buttons, `label-01` and `helper-text-01` for labels, captions
  and messages, `heading-compact-01` for section labels, `heading-compact-02`
  for headings, `heading-04` for page titles, `code-01` and `code-02` for mono.

A field's label is `fieldLabel` in `foregroundSecondary`, at the spec's
`label` weight: regular in Material, Ant, Fluent and Carbon, medium (500) in
shadcn, and the heading weight in Iris, which sets none. Its description is
`fieldDescription` in `foregroundMuted`, and its error `fieldMessage` at weight
500. The description and the message take one step in every theme, so a
description and the error that replaces it are one size: the caption's, or
the body's in shadcn and Ant, whose forms set both at body size. `fieldText`'s
line fits every theme's small control height (24 in Ant and Fluent).

`mono` and `monoSmall` use `AdminTypeSpec.monoFontFamily` (`monospace`, with
`monoFontFamilyFallback` for platforms without one), which the font
resolver never sees. Change a weight with `context.type.weighted(style, weight)`:
it keeps a mono style in the monospace font.

The ramp also carries the display, headline and `titleLarge` steps of the
Material text theme. `buildAppTheme` sets that whole text theme from the ramp:
`bodyLarge` is `fieldText`, `bodyMedium` is `body`, `bodySmall` is `caption`,
`labelLarge`, `labelMedium` and `labelSmall` are `button`, `sectionLabel` and
`micro`, and `titleMedium` and `titleSmall` are `heading` and `bodyStrong`. A
bare `Text` is therefore set in `body`, and a stock `TextField` or
`TextFormField` is exactly as tall as a medium `InputField`.

### Motion

`AdminMotion` holds three durations by how far something travels, a `pulse`
for a loading placeholder's breathing, and four curves: `standard` for a move
between two resting places, `enter` for something arriving, `exit` for
something leaving, and `emphasized` for a larger move. Read them through
`context.motion`: `context.motion.medium`, `context.motion.enter`.

| Theme | fast / medium / slow | pulse | Curves (standard · enter · exit) |
|---|---|---|---|
| Iris | 120 / 180 / 240ms | 900ms | ease-out cubic · ease-out cubic · ease-in cubic |
| Material | 100 / 200 / 300ms (short2, short4, medium2) | 900ms | standard · emphasized decelerate · emphasized accelerate |
| shadcn | 150 / 200 / 300ms | 1000ms | ease-in-out · ease-out · ease-in |
| Ant | 100 / 200 / 300ms (`motionDurationFast`, `Mid`, `Slow`) | 700ms | `motionEaseInOut` · `motionEaseOut` · `motionEaseIn` |
| Fluent | 100 / 200 / 250ms (faster, normal, gentle) | 900ms | easy ease · decelerate mid · accelerate mid |
| Carbon | 110 / 150 / 240ms (fast-02, moderate-01, moderate-02) | 1500ms | productive standard · entrance · exit |

`fast` is a change in place (a toggle's knob, a chevron turning), `medium` a
panel opening in the flow (an accordion, a tree's rows, a tab indicator), and
`slow` an overlay crossing the screen (a side sheet, a modal, a toast).

While the platform asks for less motion (`MediaQuery.disableAnimations`),
`context.motion` returns `AdminMotion.reduced`: every duration zero, the curves
kept, so an animation that reads its duration there lands on its end state at
once. Two things cannot run at zero: an `AnimatedSize`, and a scroll position
animating to an offset. Check `motionReduced(context)` and leave the one out,
or jump the other. A timer that paces an interaction, such as a hover delay, a
search debounce or a toast's time on screen, is not motion and keeps its
duration.

### Stroke, icon sizes and state layers

`AdminStroke` sets line widths, read through `context.stroke`: `hairline`
(dividers, card edges) and `control` (a resting outline) are 1,
`controlStrong` (an unchecked checkbox or radio) 1.5 and `indicator` (a
selection bar or underline) 2. A field's focused and invalid outlines follow
each design system; a focused invalid field takes the wider of the two.
`resolveFieldChrome` draws them in the theme's field anatomy (see
[Anatomy](#anatomy)); `fieldBorderSide(palette, states, stroke:
context.stroke)` is the outlined box alone. `fieldFocusHalo` is a band outside
a focused field's edge, in its ring at `AdminFieldStyle.haloOpacity` (half by
default; the danger colour at a fifth when invalid): shadcn's `ring-[3px]
ring-ring/50`, Ant's 2px `activeShadow`. Where the focused outline is no wider than the
resting one, the hover step stops at the focus ring's contrast, so a hovered
field never outweighs a focused one.

| Theme | `fieldFocus` | `fieldError` | `fieldFocusHalo` |
|---|---|---|---|
| Iris | 1.5 | 1.5 | 0 |
| Material | 2 | 1 | 0 |
| shadcn | 1 | 1 | 3 |
| Ant | 1 | 1 | 2 |
| Fluent | 2 | 1 | 0 |
| Carbon | 2 | 2 | 0 |

`AdminIconSizes` sets glyph sizes, read through `context.iconSizes`: `xs` 12
(in a badge or chip), `sm` 14 (beside small text), `md` 16 (in a control or
beside body text), `lg` 20 (leading a larger element) and `xl` 24 (an empty
state). Every shipped theme uses these.

`AdminStateLayer` sets the opacity an interaction state lays its colour at:
`palette.stateLayer`, from which the palette derives `hoverOverlay`,
`focusOverlay`, `pressedOverlay`, `draggedOverlay`, `primaryHoverOverlay` and
`primaryPressedOverlay`. The kit's own is a 5% hover and focus, a 10% press
and drag, an 8% selection wash, an 8% and 14% wash of a saturated colour
(`tintHover`, `tintPressed`: a link's primary, a destructive menu row's
danger, a column's accent under a dragged card), and 38% for disabled
content. The Material palettes use M3's: 8% hover, 10% focus and press, 16%
drag.

### Anatomy

Four anatomy tokens give each theme the shapes of its reference system, not
only its colours: `AdminFieldStyle` (`context.fieldStyle`),
`AdminButtonStyle` (`context.buttonStyle`), `AdminShellStyle`
(`context.shellStyle`) and `AdminOverlayStyle` (`context.overlayStyle`),
beside the role radii `radiusField` and `radiusButton`
(`context.radii.button(size)`). A component reads them; it never asks which
theme it is in.

A field's box is `outlined` (stroked on every side), `filled` (a
`fieldFill` box with only a bottom `fieldRule`, square at the bottom) or
`underlined` (a hairline box over a `fieldRule` bottom stroke). Focus
strokes the whole edge (`FieldFocusIndicator.outline`) or thickens the rule
(`underline`), in `focusRing` or, with `accentFocus`, `controlAccent`.
`resolveFieldChrome(tokens, states)` returns a state's `FieldChromeSpec`:
its fill, outline, rule, halo, and the `border` the edges take inside the
box. `FieldBorder` draws it for an `InputDecorator` (the input theme uses one
at `radiusField`), and `fieldDecoration` and `fieldForegroundDecoration` for
a box.

| Theme | Field | Button | Shell (sidebar / rail / item / top bar) |
|---|---|---|---|
| Iris | outlined, 1.5px focus ring | centred, `height / 2 − 4` padding | 240 / 64 / 36 / 56 |
| Material | outlined, 4dp corner, 2dp primary on focus | stadium, 24dp padding (16 on the icon side), w500, outlined in `controlBorder`, a primary text button | 360 / 80 / 56 / 64, a stadium pill |
| shadcn | outlined, a 3px ring at 50% | faded to 50% when disabled | 240 / 64 / 36 / 56 |
| Ant | outlined, 6px corner, colorPrimary focus with a 2px ring, a primary hover | w400, 16px padding, a primary hover | 200 / 80 / 40 / 64, the dark #001529 sider in light mode |
| Fluent | underlined, a 2px brand underline on focus | radius 4, w600, 12px padding, 96px wide at least | 260 / 48 / 40 / 48, a 4px bar |
| Carbon | filled, square, a 2px inset `$focus` | square, label at the start and icon at the end (16 / 64), w400, a Gray 80 filled secondary, a `$link-primary` ghost | 256 / 48 / 32 / 48, a 3px edge rule, the g100 header in both modes |

`AdminOverlayStyle` sets whether a tooltip points at its target with an
arrow, the width it wraps at, and the size of the arrow a tooltip or a
popover with `showArrow` draws: Iris and Material's plain tooltips have none
and wrap at 280 and 200, shadcn's has Radix's 10×5 arrow, Ant's a 16×8 one at
250, Fluent's wraps at 240 and Carbon's at 288, both with a 12×6 arrow.

Each theme also takes its design system's shadows: M3's elevation levels,
Ant's `boxShadowSecondary`, Fluent's `shadow4`, `shadow16` and `shadow64`,
and Carbon's `0 2px 6px`. Fluent's focus ring carries a 1px `surface` band
inside it (`AdminFocusSpec.innerWidth`). The shell's `sidebarPalette` and
`topBarPalette` draw the frame in a scheme of its own: `carbonShellPalette`
and `antSiderPalette`. A wide sidebar keeps to `Sidebar.maxWindowShare` of
a narrow window, down to 240, so Material's drawer narrows before the page
does. The catalog's Foundations / Anatomy page draws the active theme's
tokens.

### Breakpoints

`AdminBreakpoints` are the window widths where a layout changes: Material
3's window size classes, folded to the three an admin needs.
`AdminBreakpoint.of(context)` classifies the window by its `MediaQuery`
width, and `AdminBreakpoint.forWidth(width, context.breakpoints)` any
width, such as a widget's own from a `LayoutBuilder`:

| Class | Width | Material 3 | For example |
|---|---|---|---|
| `compact` | under 600 | compact | a phone: the navigation in the Shell's drawer, lists as cards, dialogs full screen |
| `medium` | 600 to 1199 | medium and expanded | a tablet or a small window: the sidebar folds to a rail |
| `expanded` | 1200 and up | large and extra-large | a desktop window |

Every shipped theme keeps these widths. A theme of your own sets others
with `AdminTheme.from(breakpoints: …)`, for example
`AdminBreakpoints(medium: 480, expanded: 1024)`. They are
`AdminTokens.breakpoints`, read as `context.breakpoints`, and a theme
animating into another switches at one set of widths or the other, never in
between. Test a class with `isCompact`, `isMedium` and `isExpanded`.

### Tokens, not literals

Outside `lib/src/theme/`, the kit reads sizes, radii, spacing, motion and
state washes from the tokens. `test/theme_token_literals_test.dart` fails on
a literal `fontSize`, a numeric radius, a number inside `EdgeInsets` or
`Gap`, a `SizedBox` of one dimension of 32 or less used as a gap, a
`Curves.` reference, a `Duration` literal passed as an animation's duration,
and a colour taken to a literal opacity (`withValues(alpha: 0.12)`). A
literal that is not a token's job, such as a 1px nudge that keeps content
still as a border thickens, is allowed where its line or the line above says
why, with a `// token-literal: <reason>` comment. A marker without a reason,
or one that allows nothing, fails the test too. `test/theme_literals_test.dart`
does the same for colour literals, which only the palette may name.

## Localisation and right-to-left

Register the delegates as in the minimal app above.
`AdminLocalizations.localizationsDelegates` holds the kit's delegate plus
material_ui's Material, Cupertino and widgets delegates. The kit ships English,
French and Arabic (`AdminLocalizations.supportedLocales`). For any other
language it falls back to English, while numbers and dates still follow the
app's locale. Without the delegate nothing fails: the kit falls back to
English.

Kit widgets read their strings from `context.adminL10n` and format numbers,
sizes and dates with `context.adminFormats`. Most widgets that show text also
take a label parameter that overrides the string. To change strings globally,
subclass `AdminLocalizationsEn` and list your own delegate first. The class
documentation shows how.

The strings are grouped in sections, one per part of the kit. The language
lanes read theirs from the `fields` section (`context.adminL10n.fields`): the
per-language status words (Source, Up to date, Needs review, Outdated,
Missing), Re-translate, the source lane's label, the language menu, and the
Inherited and Custom modes. A package built on the kit keeps its own
strings in localizations of its own, whose delegates it lists beside the
kit's.

The layout mirrors in a right-to-left locale, or under
`Directionality(textDirection: TextDirection.rtl)`.

## Forms

A form edits cells: typed handles over a `FormScope`, one cell per field,
which the field presets (`Field`, `NumberField`, `SelectField`, …) bind to
through `bind()`. What backs the scope decides what saving means. A
collaborative document keeps its own controller; for plain values, a
dialog or a settings page or a record loaded over RPC and saved back
whole, use `ValueFormController`:

- `read` builds your value type from the cells and `write` sets the cells
  from one, both through typed handles over the controller's `scope` (its
  own `LocalScope` unless you pass one). Build the fields' handles over the
  same `scope`: the controller tracks every cell it hands out, record-list
  rows included, and knows whether the form is dirty without a snapshot of
  your own.
- `seed(value)` loads a value and makes it the baseline, `reset()` goes
  back to it, and `submit()` calls `onSubmit` with the current value. A
  successful submit rebases; an `onSubmit` that throws a
  `FormSubmitException` puts its messages under the fields it names.
- `rules` returns the validation: a `FieldRules` per field, with
  `Validators` (`required`, `minLength`, `maxLength`, `pattern`, `email`,
  `url`, `min`, `max`) and optional async checks, which are debounced and
  never let an older answer win; a `ListRules` for how many rows or items
  a list holds (at least one by default: "Add at least 1 item" under a
  `RecordListField`); a `FormRule` for a check across fields; and
  `visibleWhen` for a field that only applies sometimes. A field whose
  rules hold `Validators.required()`, or a list whose `ListRules` want
  an item, is marked required. A record list is a `Cell` of its rows, so
  a `FormWizardStep` names it among its fields.
- `mode` decides when a message shows: once its field is edited
  (`ValidationMode.onEdit`, the default), after a submit attempt, or at
  once. `errors` holds the messages shown, which the fields and the save
  bar read, and `allErrors` every one.
- The scope hands out a cell per kind of value: text, numbers, dates,
  enums, lists, a `map(field)` for a `KeyValueField`, asset references
  and record lists. The controller tracks each the same way, so a map
  field is dirty, discarded and saved with the rest.

Put the form in a `ValueForm` of the controller. It shows each field's
message under it, keeps every field's message line so a message appearing
does not move the fields below (a `FieldGroup` or `FormGrid` inside spaces
its rows for that line), marks the required fields in the theme's way,
says "Checking…" under a field whose async check is running, and, after a
refused submit, focuses the first invalid field and scrolls the whole of it
into view, its message clear of a save bar docked under the page. Pass
`readOnly: true` for a user who may look but not edit. A `FormSaveBar`
or `FormActions` of the same controller saves it; put it inside the
`ValueForm`, or give both the same `FormFieldRegistry`, for its "2 fields
need attention" to reach the fields.

A contact editor, saved by `save`; the save bar's Save stays disabled
until the form is edited and valid:

```dart
typedef Contact = ({String name, String email});

extension type ContactFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
}

ValueFormController<Contact> contactForm(Future<void> Function(Contact) save) =>
    ValueFormController<Contact>(
      read: (s) {
        final f = ContactFields(s);
        return (name: f.name.value, email: f.email.value);
      },
      write: (s, contact) => ContactFields(s)
        ..name.set(contact.name)
        ..email.set(contact.email),
      onSubmit: save,
      rules: (s) {
        final f = ContactFields(s);
        return [
          FieldRules(
            f.name,
            validators: [Validators.required(), Validators.maxLength(80)],
          ),
          FieldRules(
            f.email,
            validators: [Validators.required(), Validators.email()],
          ),
        ];
      },
    );

class ContactEditor extends StatelessWidget {
  final ValueFormController<Contact> form;

  const ContactEditor({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final f = ContactFields(form.scope);
    return ValueForm(
      controller: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FormGrid(
            children: [
              Field(f.name, label: 'Name'),
              Field(f.email, label: 'Email'),
            ],
          ),
          FormActions(controller: form),
        ],
      ),
    );
  }
}
```

For layout, `FormGrid` sets fields in columns that follow the grid's own
width, and `FormWizard` splits a form into steps that validate before the
next shows. `ValidationSummary` lists what needs fixing, each entry a link
to its field; it takes no room while hidden, and its `margin` parts it from
the fields only while it shows (`ValidationSummary.showsFor` says when). A
`FormWizard` places one between its indicator and the step with
`summary:`. `UnsavedChangesGuard` keeps unsaved edits from being lost to
a back gesture, a sidebar tap or closing the tab.

## Saved views

A `SavedViewsController` keeps a collection's named filter, sort and
column presets in a `SavedViewsStore` (yours, or
`InMemorySavedViewsStore`), and a `SavedViewsBar` shows them above the
list. Bind the bar to the controller: `views`, `activeId` and `dirty`
from it, `onSelect: views.select`, `onSaveChanges: views.saveChanges`
and `onDiscardChanges: views.discardChanges`.

The bar asks for names itself. `onCreate: (view) =>
views.saveAsNew(view.name, scope: view.scope)` offers the "+", and
`onRenamed: views.rename` a Rename in each view's menu; both open
`showSaveViewDialog`, which a screen can also call on its own. Pass
`askScope: false` where every view is personal.

With no view marked default the list opens on every row, no view
active. `onSelectAll: views.clearView` adds a first tab for it, "All"
unless `allLabel` says otherwise, which returns to the query the
collection started with. The controller never opens on a view that is
not marked default.

Below the medium breakpoint (600, `context.breakpoints.medium`) the bar
is the active view's name over a menu of every view and the active
view's actions, so no name is cut at a phone's edge. It goes by its own
width; `layout: SavedViewsLayout.strip` or `menu` fixes the form.

## A media page

`AssetLibrary` renders the assets it is handed. Over an `AssetSource`,
`AssetLibrary.connected` takes them from an `AssetLibraryController`,
which pages, searches and filters the source: the first page as it is
made, the next as the grid nears its end, and the first again whenever the
search, the type filter or `where` changes. An answer to a search since
replaced is dropped. A first page that fails shows with a Retry; a next
page that fails keeps the grid and says why in a toast, and "Load more"
tries it again. `showAssetPicker` runs on the same controller.

A filter of the app's goes in `toolbarActions`, beside the type filter,
and its choice in `where`: `FilterCondition`s the kit hands to
`AssetSource.browse` untouched, for the source to answer where the assets
are, so the library still pages. On a phone the grid is two-up;
`maxTileExtent` sets the widest column instead.

`showAssetDetail` opens an asset in a side sheet, with the app's `actions`
in its header and `footerActions` at the end of its footer, Delete at the
start. `AdminScope`'s anchor sits above the page, so pass the page's
`context`: the sheet takes the page's `LangScope`, which the alt text
needs, and its `AssetSourceScope` from there. The sheet stays above the
keyboard.

```dart
/// A media page over [source], below the app's `LangScope`: search, the
/// type filter and an "Unused" filter of the app's, a page at a time, and
/// each asset's details with a Crop of the app's.
class MediaPage extends StatefulWidget {
  const MediaPage({super.key, required this.source});

  final AssetSource source;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late final _library = AssetLibraryController(source: widget.source);
  bool _unused = false;

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  void _showUnused(bool unused) {
    setState(() => _unused = unused);
    // The source answers 'inUse' where the assets are: the grid still pages.
    _library.where = [if (unused) const BoolFilter('inUse', false)];
  }

  void _open(Asset asset) => showAssetDetail(
    ModalAnchor.of(context),
    // AdminScope's anchor is above this page: the sheet takes the page's
    // LangScope, for the alt text, from here.
    context: context,
    asset: asset,
    onSaveAlt: (alt) async {
      final saved = await widget.source.updateAlt(asset.id, alt);
      if (saved != null) _library.replace(saved);
      return saved;
    },
    footerActions: [
      if (asset.thumbnail case final image?)
        Button(
          'Crop',
          icon: Icons.crop_rounded,
          variant: ButtonVariant.secondary,
          onPressed: () => showCropDialog(
            context,
            image: image,
            imageAspect: (asset.width ?? 1) / (asset.height ?? 1),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AssetLibrary.connected(
      controller: _library,
      onOpen: _open,
      toolbarActions: [
        FilterMenuButton<bool>(
          value: _unused,
          tooltip: 'Usage',
          onChanged: _showUnused,
          options: const [
            FilterMenuOption(false, 'All assets'),
            FilterMenuOption(true, 'Unused', icon: Icons.link_off_rounded),
          ],
        ),
      ],
    );
  }
}
```

## Comments and mentions

A mention is stored as a durable token, `<@id>`, so a renamed person reads
right everywhere. `MentionField` is where one is written: typing `@` offers
the `candidates` whose name holds what follows it, in a list below the
field that the keyboard drives while focus stays in the field (ArrowDown
and ArrowUp, Enter or Tab to accept, Escape to close). Accepting writes
`@Name`; `onSubmit` receives the body with each mention as its token, on
Ctrl+Enter (⌘+Enter) in a multi-line field or Enter in a one-line one. A
send button beside it tokenizes the text itself with `tokenizeMentions`.
`MentionText` draws a stored body back, each token as `@Name` in the link
colour, resolving the names as it renders:

```dart
class NoteBox extends StatefulWidget {
  final List<MentionCandidate> team;
  final String Function(String id) nameOf;
  final ValueChanged<String> onSend;

  const NoteBox({
    super.key,
    required this.team,
    required this.nameOf,
    required this.onSend,
  });

  @override
  State<NoteBox> createState() => _NoteBoxState();
}

class _NoteBoxState extends State<NoteBox> {
  final _text = TextEditingController();
  final _sent = <String>[];

  void _send(String body) {
    // body holds tokens: 'Can you check, <@u2>?'
    widget.onSend(body);
    setState(() => _sent.add(body));
    _text.clear();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final body in _sent) MentionText(body, nameOf: widget.nameOf),
      MentionField(
        controller: _text,
        candidates: widget.team,
        label: 'Note',
        minLines: 2,
        maxLines: 5,
        onSubmit: _send,
      ),
    ],
  );
}
```

## Version history

`DiffView` draws a `VersionDiff`: the fields that changed between two
versions, per language, with their restore buttons. Build one from the
two versions of a record by declaring its fields: `FieldDiff.text` for
plain text, which the view diffs word by word, `FieldDiff.translated` for
text by locale, and `FieldDiff.scalar` for any other value, compared as
the text `format` gives it. Each works out its ops: a value on one side
only is added or removed, and a null or empty one is absent.
`VersionDiff.of` keeps every field in the order declared, unchanged ones
included for the view's "Unchanged" switch, and collects the languages
for its filter. A field's key is what `DiffView.onRestorePart` names in
the `RestoreTarget` it hands back.

```dart
typedef Product = ({
  Map<String, String> name,
  String sku,
  int priceCents,
  List<String> tags,
});

/// What changed in a product from version [base], where it was [a], to
/// version [compare], where it is [b].
VersionDiff productDiff(
  VersionRef base,
  Product a,
  VersionRef compare,
  Product b,
) => VersionDiff.of(
  base: base,
  compare: compare,
  fields: [
    FieldDiff.translated('name', 'Name', a.name, b.name, locales: ['en', 'fr']),
    FieldDiff.text('sku', 'SKU', a.sku, b.sku),
    FieldDiff.scalar(
      'price',
      'Price',
      a.priceCents,
      b.priceCents,
      format: (cents) => '€${(cents / 100).toStringAsFixed(2)}',
    ),
    FieldDiff.scalar(
      'tags',
      'Tags',
      a.tags,
      b.tags,
      format: (t) => t.join(', '),
    ),
  ],
);
```

Rich bodies and record lists carry their own block and record changes:
build those `FieldDiff`s with the constructor.

## Ancestor scopes

Some widgets need a scope above them. `AdminScope` mounts the app-wide ones
in one widget. Put it inside the home route, around the shell, as the
minimal app does. From the outside in, it mounts:

- a material_ui `Theme` of `buildAppTheme(tokens)`, only when you pass
  `tokens`;
- a `ToastScope`, unless one is above it already;
- a `LeaveGuardScope` over the `leaveGuards` registry you pass, or, unless
  one is above it already, over one of its own, which it disposes;
- a `CommandScope` over the `commands` registry you pass, or over one of
  its own, which it disposes;
- a `ModalAnchor`, opened through the `modals` controller when you pass
  one.

A toast paints over a route's dialog only from a scope above the
`Navigator`. An app that raises toasts from dialogs keeps its own
`ToastScope` in `MaterialApp.builder`, and `AdminScope` uses that one. The
scopes stay public, for an app that wants one somewhere else.

`AssetSourceScope` and `LangScope` belong to a part of the app, so you mount
them where that part starts. Each `of()` below throws a `FlutterError` that
names the missing scope, and most scopes also have a `maybeOf()` for code
that can do without one.

| Scope | Where | Needed by |
|---|---|---|
| `ToastScope` | `AdminScope`, or `MaterialApp.builder` above the Navigator | `ToastScope.of(context).show(…)`. The kit's own notices go through it too: files a drop target refuses, and a page the asset picker fails to load. Without a scope, those notices are dropped. |
| `ModalAnchor` | `AdminScope`: below every scope that modal content reads, and inside a route, so that back closes its modal before it leaves the page | `showAssetPicker`, `showAssetEditor` and `showCommandPalette` (unless you pass `modals:`), and so `AssetBody` and `AssetMediaCanvas`, which open them. The compact `Shell` opens its navigation drawer there. A modal sees the scopes above the anchor. `showAssetEditor`, and the picker it opens, also takes the `AssetSourceScope`, `ExternalProviderScope`, `LangScope`, `FieldPresenceScope` and `FieldBinderScope` of the widget that opened it, so an asset field works with `AdminScope`'s anchor alone, however deep the page mounts them; `showAssetDetail` takes the `LangScope` and `AssetSourceScope` of the `context` you pass it. |
| `AssetSourceScope` | Above asset fields | `AssetBody`, `AssetMediaCanvas` and the asset editor. They read it with `maybeOf`: without a scope, asset fields show read-only placeholders. |
| `LangScope` | Above forms with translated fields | `bind()`, and so every field preset, when bound to a translated cell. Also `AssetDetailView` when given `onSaveAlt`; `showAssetDetail` takes it from its `context:`. |
| `CommandScope` | `AdminScope`, around the app shell | Your code that registers commands with `CommandScope.of(context)`. `FormFieldCommands` adds the current form's fields to it when one is present. |
| `LeaveGuardScope` | `AdminScope`, over its `leaveGuards` registry | `UnsavedChangesGuard`, which registers with it, and `Sidebar`, which calls `LeaveGuardScope.confirmLeave` before it navigates. Without one, only a route's own back is guarded. |
| `ValueFormScope` | `ValueForm`, around a form | `bind()`, and so every field preset, which reads its field's visibility and requiredness from the form's rules. Without one, a field shows as its own parameters say. |
| `FieldFeedbackScope` | `ValueForm`, around a form | `FieldShell` and `LabeledField`, for the reserved message line, the "Checking…" line and the optional mark (on the fields the form validates); `FormGrid`, whose rows close up for the reserved line. Without one, none of the three shows unless a field asks. |

`ExternalProviderScope`, `CommentsScope`, `FieldStateScope`,
`FieldErrorsScope`, `FieldBinderScope` and the other form scopes are
optional; a `ValueForm` mounts the ones a form needs. When one is missing,
the widget that reads it does without: with no `FieldBinderScope`, `bind()`
renders every cell with its own body.

## Name clashes

The kit's services on `BuildContext` carry an `admin` prefix, so they do
not collide with an app's own: `context.adminTokens`, `context.adminL10n`
and `context.adminFormats`, each on an extension of its own
(`AdminThemeContext`, `AdminLocalizationsContext`, `AdminFormatsContext`).
Its class names start with `Admin`, never `AdminUi`.

The token shorthands are the one unprefixed extension, `AdminTokensContext`:
`context.colors`, `context.type`, `context.radii`, `context.elevation`,
`context.focus`, `context.sizes`, `context.tableMetrics`, `context.motion`,
`context.stroke`, `context.iconSizes`, `context.fieldStyle`,
`context.buttonStyle`, `context.shellStyle`, `context.overlayStyle` and
`context.breakpoints`. An app with getters of its own under those names
hides it, and reads the tokens through `context.adminTokens`, which hiding
leaves in place:

```dart
import 'package:admin_ui/admin_ui.dart' hide AdminTokensContext;
import 'package:material_ui/material_ui.dart';

/// The app's own `context.colors`, which the kit's would clash with.
extension BrandColors on BuildContext {
  Color get colors => const Color(0xFF0D9488);
}

Widget price(BuildContext context) => Text(
  '42 €',
  style: context.adminTokens.typography.body.copyWith(color: context.colors),
);
```

An import with a `show` list names the extensions it uses:
`AdminTokensContext` for the shorthands, `AdminThemeContext` for
`adminTokens`. Only the `context.motion` shorthand is zeroed under reduced
motion: `adminTokens.motion` is the theme's motion as authored, so an app that
hides the shorthands takes `adminTokens.motion.reduced` when
`motionReduced(context)` says so.

Top-level functions are named for what they do, with a verb:
`showConfirmDialog`, `showModal`, `showSideSheet`, `showAssetPicker`.
Widgets keep short names, and a few of them clash with other packages, such
as `Gap` in `package:gap`, `LineChart` and `BarChart` in chart packages,
`Toast` in toast packages and `showModal` in `package:animations`. Hide the
one you don't want:

```dart
import 'package:admin_ui/admin_ui.dart' hide Gap;
import 'package:gap/gap.dart';
```

The kit's `Gap(size)` behaves as `package:gap`'s does: in a `Row` or a
`Column` it takes `size` along the main axis only, so it never makes a row
taller or a column wider, and anywhere else (a `Wrap`, a `Stack`) it is a
`size` square.

## API conventions

The kit names the same thing the same way on every widget. A new widget
follows these rules, and the ones that did not were renamed, with the old
name kept as a deprecated alias for one release (see
[CHANGELOG.md](CHANGELOG.md)).

| Concept | Convention | For example |
|---|---|---|
| Errors | An error message is `errorText: String?`. Error chrome with no message is `invalid: bool`. A collection view's slot for a failed load stays `error`, a widget, beside `empty`. | `InputField(errorText:)`, `FieldChrome(invalid:)` |
| Placeholders and empty states | Placeholder text in an input is `hint`. A widget slot for no content is `empty`. The text a display widget shows for a missing value is `emptyText`. | `CommandPalette(hint:)`, `Tree(empty:)`, `DescriptionList(emptyText:)` |
| Disabled and read-only | A control is disabled with `enabled: bool`: it dims and takes no input. `readOnly` shows a value that cannot change, at full contrast, and text in it can still be selected and copied; every field body honours both, through `FieldState`. As in Flutter, a null `onChanged` or `onPressed` also disables. | `FieldShell(enabled:, readOnly:)`, `InputField(enabled:)` |
| Size | `size: ControlSize` (`small`, `medium`, `large`) on every control, at the theme's three control heights. A flag for a denser look is a size. `Tabs` reads it as a strip height instead: 32, 40 or 48 in every theme. | `Button(size:)`, `Tabs(size:)` |
| Changes and choices | A change to a value the widget holds or shows is `onChanged`. A one-shot choice from a list or a menu, where the widget keeps no value, is `onSelect`. An active index keeps its domain name, with `onChanged`. | `Calendar(onChanged:)`, `MenuItem(onSelect:)`, `Steps(current:, onChanged:)` |
| Dismissing | An overlay or a banner is dismissed through `onDismiss`, and shows a close button exactly when it is set. `Toast` is the one exception: a toast can always be dismissed, so it always shows its close button, and its `onDismiss` hears why it left, as a `ToastDismissReason`. `onCancel` cancels an operation, such as an upload. | `Modal(onDismiss:)`, `SideSheet(onDismiss:)`, `Toast(onDismiss:)` |
| Placement | An overlay opens on a `side: PopoverSide` and lines up by `align: PopoverAlign`. `start` and `end` follow the text direction, in both: `PopoverSide.start` is the anchor's left in a left-to-right app and its right in a right-to-left one, so a layout written once mirrors. | `Popover(side: PopoverSide.end)`, `Tip(side:)` |
| Taps and loading | A button calls `onPressed`; a row, a tile or a card calls `onTap`. A busy state is `loading`. | `ClearButton(onPressed:)` |
| Text selection | Text is selected only in a read-only place: a page the app wraps in `SelectionArea`, `JsonView`, `MentionText`, a table with no row tap. A tap target (`Tappable`, `Button`, a row with `onRowTap`, a card with `onTap`, a menu item, a field's label) leaves its text out of any selection above it and shows its own cursor, never the text I-beam. A value worth copying out of one gets a `CopyButton`. | `SelectionArea(child: DescriptionList(…))`, `CopyButton(order.email)` |
| Pointer cursor | An enabled control shows the hand on every platform, as the web does; a desktop build is for development and looks like the shipped app. The hand says a control is under the pointer, not that this click changes anything: a selected option and the current page show it like their neighbours. A disabled control shows the arrow, as do a target a double click or a long press acts on and a field's label. A link shows the hand. A drag handle shows the open hand, a splitter or column edge the resize arrows. Text input, and text in a read-only place, show the I-beam. A target goes through `Tappable` or `CursorRegion`; an `InkWell` passes `mouseCursor: WidgetStateMouseCursor.clickable`, since Material's default shows the arrow off the web. | `Tappable(onTap: open, child: row)`, `CursorRegion(cursor: SystemMouseCursors.basic, child: label)` |
| Actions on feedback | A data object takes `actionLabel` and `onAction`; a widget takes an `action` widget. Both take `icon`. | `Toast(actionLabel:, onAction:)`, `Alert(action:)` |
| Locales | A parameter that holds a locale code ends in `Locale`, and the callback for a new active locale is `onActiveLocaleChanged`. | `sourceLocale`, `targetLocale`, `activeLocale` |
| One enum per concept | `ControlSize` for size, `Severity` for tone, `LocaleStatus` for a language's status. | `ProgressBar(severity:)` |
| Context getters | The kit's services are `admin`-prefixed getters. The token shorthands are the one unprefixed extension, which an app can hide (see [Name clashes](#name-clashes)). Classes are `Admin*`. | `context.adminTokens`, `context.adminL10n`, `AdminLocalizations` |
| Functions and widgets | A top-level function is named for what it does, with a verb. Widgets keep their short names. | `showConfirmDialog`, `Gap`, `Toast` |
| Keys | Every control the kit builds takes a key from the app, so a test finds it without its words. A data object that describes a control takes `key`, which the kit puts on the control it builds for it, or on its row when a narrow layout folds it into a menu. A widget or a function that builds a control of its own takes `<part>Key` for it. A widget that is one control takes its own `key`, as any widget does. | `NavItem(key:)`, `MenuItem(key:)`, `showConfirmDialog(confirmKey:)`, `ErrorState(retryKey:)`, `SaveBar(discardKey:)` |

## The preview catalog

`example/` is a catalog of every widget with its states. Each demo is a
`@Preview`, wrapped in `adminUiPreview`, which adds Theme, Mode (Light/Dark),
Brand, Direction and Locale axes. You can run the catalog as an app:

```sh
cd example
flutter run -d macos
```

You can also render a single entry with flutterware from the repository root
(`alias fw='dart run flutterware'`):

```sh
fw run previews entries --package=packages/admin_ui/example
fw run previews screenshot \
  --entry='lib/src/ui/primitives/button.dart#ButtonDemo.new' \
  --axes='Theme=Carbon,Mode=Dark,Brand=Teal' --output=/tmp/button.png
fw run previews inspect --entry='lib/src/ui/primitives/button.dart#ButtonDemo.new'
fw run previews audit --package=packages/admin_ui/example
```

To add a demo, annotate its constructor with
`@Preview(name: …, wrapper: adminUiPreview)`, then list it on a catalog page
(`example/lib/src/catalog.dart`) or, for a preview the catalog leaves out,
in `previewOnly` (`example/test/support/entries.dart`).
`example/test/entries_guard_test.dart` fails on a demo that is in neither.

The catalog's last group, Labs, holds prototypes of private widgets, each
kept to settle an open design question that its class doc names. The sweeps
below pump the labs too.

## Sweeps

Four sweeps pump every demo of the catalog, catalog pages and preview-only
demos alike, with the real fonts, and fail on an exception or an overflow.
They compare no pixels, so they run the same on every machine:

- **Themes** (`example/test/sweeps/themes_sweep_test.dart`): every demo once,
  in a theme and mode picked by a stable hash of its id, so all 12
  combinations are pumped; and a core set of 8 (buttons, control states,
  field heights, select, tabs, menu, modal and the app frame) in all 12.
- **Text size** (`text_scale_sweep_test.dart`): every demo at twice the text
  size, in Iris and in Ant, whose ramp has the tallest lines in the
  smallest controls. Text a box clips fails too.
- **Reduced motion** (`reduced_motion_sweep_test.dart`): every demo with the
  platform asking for less motion, where nothing may still schedule a frame
  once the fixed pumps are over.
- **Locales** (`example/test/rtl_smoke_test.dart`): every demo mirrored in
  Arabic, and in French, whose strings run longest.

A sweep that cannot pump a demo yet lists it with the reason and the line a
fix starts from, so nothing is left out silently. Run them from
`example/`:

```sh
flutter test test/sweeps test/rtl_smoke_test.dart
```

Fluent's Segoe UI cannot be shipped, so Roboto stands in for it, and Ant
names no font and draws in the platform's, which under the tests is Roboto.
No Hebrew test font ships, so Hebrew text is measured as boxes.

The harness (fonts, the theme matrix, `pumpEntry` and the entries guard) is
in `example/test/support/harness/`. Its fonts are the kit's
[test support](#testing-an-app-on-the-kit) plus the catalog's own test
faces.

A change that moves pixels on purpose shows them in its pull request: a
screenshot of each demo it touches, before and after, taken with
`fw run previews screenshot`.

## Testing an app on the kit

`package:admin_ui/testing.dart` draws the kit in a widget test as a device
draws it. Neither `admin_ui.dart` nor `ui.dart` exports it, so import it
from tests only; it imports no test package, so the kit needs none.

`flutter test` has no network, and draws each glyph as a box of its test
font, an em wide: a theme's text measures wrong, and a label that fits on a
device overflows in a test. Call `await loadAdminFonts()` once per test
file from the `testExecutable` of `test/flutter_test_config.dart`, after
`TestWidgetsFlutterBinding.ensureInitialized()` and before anything builds
a theme's tokens, then run the tests. It loads:

- the families of the app's `FontManifest.json`: those it bundles, as
  [Fonts](#fonts) says, and `MaterialIcons`;
- with a `fontDirectory`, a path to font files named as
  `Inter-Regular.ttf` or `IBMPlexSans-SemiBold.ttf` are, the family of
  each; for a package whose tests bundle no fonts, as the kit's own load
  Iris's Inter from the example's files;
- `standIns`, each family registered from the files of another face: Roboto
  under `testPlatformFamily` (Roboto, the family the Material text theme
  names under `flutter test`) for a theme that names no font, such as Ant,
  and under Fluent's `Segoe UI` and `Georgia`, which cannot be
  redistributed.

Every family the light and dark tokens of `themes` name (by default
`adminThemes`) must come from one of those, or it fails naming the theme
and the family to bundle. `loadTestFontFamily` registers a family of the
app's own, such as a script fallback.

The test engine falls back to no other font, so
`withTestFontFallback(tokens, fallback: …)` gives a theme that names no font
the platform family and appends the families that hold the symbols and
scripts its font lacks. `textWithoutFont()` lists the text on screen still
drawn in the box font, empty when every run is in one of
`testFontFamilies`. The example's sweep harness
(`example/test/support/harness/`) is built on these.

### Finding the kit's controls

The kit's controls carry its own words, in the app's language, so a test that
finds them by text breaks with a translation. Give them keys instead (see
[API conventions](#api-conventions)):

```dart
const ordersKey = ValueKey('nav.orders');
const confirmDeleteKey = ValueKey('dialog.confirm');

NavItem ordersItem(VoidCallback openOrders) => NavItem(
  'Orders',
  key: ordersKey,
  icon: Icons.receipt_long_outlined,
  onTap: openOrders,
);

Future<bool> confirmDelete(BuildContext context) => showConfirmDialog(
  context,
  title: 'Delete the order?',
  message: 'It cannot be restored.',
  danger: true,
  confirmKey: confirmDeleteKey,
);
```

A test then taps `find.byKey(ordersKey)` in every language, on the rail as
in the drawer. An input takes its key on the field, and
`tester.enterText` reaches its text inside it.

See [CHANGELOG.md](CHANGELOG.md) for what changed in each release.
