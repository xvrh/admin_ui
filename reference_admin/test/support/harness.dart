import 'dart:async';
import 'dart:math' as math;

import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart' show AdminBreakpoint;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/api/shop_api.dart';
import 'package:reference_admin/src/app.dart';
import 'package:reference_admin/src/fake/fake_shop_api.dart';
import 'package:reference_admin/src/keys/shell_keys.dart';
import 'package:reference_admin/src/l10n/ref_strings.dart';
import 'package:reference_admin/src/routing/router_delegate.dart';
import 'package:reference_admin/src/routing/routes.dart';
import 'package:reference_admin/src/services.dart';

export 'package:reference_admin/src/api/shop_api.dart';
export 'package:reference_admin/src/fake/fake_shop_api.dart';
export 'package:reference_admin/src/keys/shell_keys.dart';
export 'package:reference_admin/src/routing/routes.dart';

/// One scenario's shop: the app's services over a fresh fake, and the
/// handles a scenario arms and asserts on.
class Shop {
  final AppServices services;

  Shop(this.services);

  FakeShopApi get api => services.fake!;
  FakeShopDb get db => api.db;
  FaultPlan get faults => api.faults;
  CallLog get calls => api.calls;
  AppRouterDelegate get router => services.router;

  /// The page shown, after the guards.
  AppRoute get route => router.route;
}

/// Pumps Potting Shed over a fresh fake shop and returns its handles.
///
/// Call it inside the scenario's body, so every `split` replay starts from
/// a fresh shop. [as] signs in the first active staff member with that role
/// without a call (null starts signed out). [theme], [mode] and [accent] set
/// the appearance without saving it. [before] arms faults and holds before
/// the first frame. [shot] and [settle] are the pump's.
///
/// Every call the fake answers is filed on the step it happened in, as a
/// `CALL <endpoint>` request in the run report.
Future<Shop> openShop(
  ScenarioTester s, {
  DemoSeed seed = DemoSeed.demo,
  AppRoute at = const Dashboard(),
  Role? as = Role.owner,
  String theme = 'Iris',
  ThemeMode mode = ThemeMode.system,
  Color? accent,
  Latency latency = Latency.realistic,
  void Function(Shop shop)? before,
  Shot? shot,
  Settle? settle,
}) async {
  final services = AppServices.fake(latency: latency, seed: seed, signInAs: as);
  services.appearance.apply(
    UserPrefs(
      theme: theme,
      mode: switch (mode) {
        ThemeMode.system => AppearanceMode.system,
        ThemeMode.light => AppearanceMode.light,
        ThemeMode.dark => AppearanceMode.dark,
      },
      accent: accent?.toARGB32(),
    ),
  );
  final shop = Shop(services);
  shop.calls.onCall = (call) => recordAppEvent(
    AppEvent.request(
      method: 'CALL',
      url: call.endpoint.path,
      status: call.status,
      data: {...call.args, if (call.error != null) 'error': '${call.error}'},
    ),
  );
  before?.call(shop);
  await s.pumpWidget(
    // Keyed by the shop, so a second openShop in one scenario mounts a new
    // app (and router) rather than updating the first one's.
    ReferenceAdminApp(
      key: ObjectKey(services),
      services: services,
      initialRoute: at,
    ),
    shot: shot,
    settle: settle,
  );
  return shop;
}

extension ShopScenario on ScenarioTester {
  BuildContext get _app => tester.element(find.byType(Navigator).first);

  /// The kit's strings as the mounted app reads them: how a scenario names a
  /// kit control that takes no key, in whatever language it runs.
  AdminLocalizations get kit => AdminLocalizations.of(_app);

  /// The app's strings as the mounted app reads them.
  RefStrings get strings => RefStrings.of(_app);

  /// The app's language: what translated data (a product's name) shows in.
  String get language => Localizations.localeOf(_app).languageCode;

  /// The frame's layout at the device this scenario runs on.
  AdminBreakpoint get breakpoint => AdminBreakpoint.of(_app);
}

/// Opens [nav]'s page the way a person would at this width: the sidebar's
/// row, the rail's icon, or the phone's drawer.
Future<void> navTo(
  ScenarioTester s,
  Nav nav, {
  Shot? shot,
  Settle? settle,
}) async {
  if (s.breakpoint == AdminBreakpoint.compact) {
    await s.tap(ShellKeys.menu, shot: Shot.skip);
  }
  await s.tap(ShellKeys.nav(nav), shot: shot, settle: settle);
}

// FRICTION(T-001): no hover, click, secondary-click or key-chord verbs; the
// helpers below are named acts around the raw tester.

/// The mouse [hover] or [click] left over the app, until [unhover] takes it
/// away.
final _hovering = Expando<TestGesture>('hovering');

/// Moves a mouse over [target] and holds it there long enough for a hover
/// card or tip to open and read what it shows. A named step: flutterware has
/// no hover verb (T-001). The mouse stays until [unhover], or the next
/// [hover], removes it, so later steps do not depend on where it rests.
// FRICTION(F-207): a HoverCard opens after a 700 ms delay no test can read;
// the rest outlasts it and the card's own fetch.
Future<void> hover(ScenarioTester s, Object target, {required String shot}) =>
    s.act(shot, () async {
      await _removeMouse(s);
      final mouse = _hovering[s] = await _addMouse(s);
      await mouse.moveTo(s.tester.getCenter(s.finderFor(target)));
    }, settle: const Settle.elapse(Duration(milliseconds: 1500)));

/// Clicks [target] with a mouse, as a hand does: the pointer moves onto it,
/// and frames go by between the press and the release. A tap presses and
/// releases in one frame with a finger (T-012), which hid a submenu row that
/// lost its click (F-029). A named step when [shot] is given (T-001); else
/// the click only settles. The mouse stays where it clicked, as [hover]'s
/// does, so a menu opened by a click keeps its pointer between clicks.
Future<void> click(ScenarioTester s, Object target, {String? shot}) async {
  Future<void> press() async {
    final mouse = _hovering[s] ??= await _addMouse(s);
    final at = s.tester.getCenter(s.finderFor(target));
    await mouse.moveTo(at);
    await s.tester.pump();
    await mouse.down(at);
    await s.tester.pump();
    await s.tester.pump(const Duration(milliseconds: 40));
    await mouse.up();
  }

  if (shot != null) return s.act(shot, press);
  await press();
  await s.settle();
}

Future<TestGesture> _addMouse(ScenarioTester s) async {
  final mouse = await s.tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(() => _removeMouse(s));
  await mouse.addPointer(location: Offset.zero);
  return mouse;
}

/// Takes away the mouse [hover] or [click] left; the next step's frames
/// close what it held open. Not a step of its own: `s.act` would name it as
/// a shot.
Future<void> unhover(ScenarioTester s) => _removeMouse(s);

Future<void> _removeMouse(ScenarioTester s) async {
  final gesture = _hovering[s];
  if (gesture == null) return;
  _hovering[s] = null;
  await gesture.removePointer();
}

/// Right-clicks [target]: a context menu. A named step (T-001).
Future<void> rightClick(
  ScenarioTester s,
  Object target, {
  required String shot,
}) => s.act(
  shot,
  () => s.tester.tap(s.finderFor(target), buttons: kSecondaryButton),
);

/// Presses [key] with the platform's primary modifier (⌘ where the device
/// is Apple's, Ctrl elsewhere) when [primary], as `primaryModifierActivator`
/// expects it. A named step (T-001).
Future<void> pressShortcut(
  ScenarioTester s,
  LogicalKeyboardKey key, {
  bool primary = true,
  bool shift = false,
  required String shot,
}) => s.act(shot, () async {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final modifiers = [
    if (primary)
      apple ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft,
    if (shift) LogicalKeyboardKey.shiftLeft,
  ];
  for (final m in modifiers) {
    await s.tester.sendKeyDownEvent(m);
  }
  await s.tester.sendKeyEvent(key);
  for (final m in modifiers.reversed) {
    await s.tester.sendKeyUpEvent(m);
  }
});

/// A typist's pause between two keystrokes: shorter than any debounce the
/// app or the kit waits out.
const keystroke = Duration(milliseconds: 90);

// FRICTION(T-011): enterText sets the whole value in one change, so a
// debounce is never exercised by it; the helpers below type one value per
// keystroke, a [keystroke] apart.

/// Types [text] into [target] one character at a time, from the first
/// [from] characters on, then settles the last keystroke with [settle].
Future<void> typeInto(
  ScenarioTester s,
  Object target,
  String text, {
  int from = 0,
  Settle? settle,
  Shot? shot,
}) => typeValues(
  s,
  target,
  [for (var i = math.max(from, 1); i <= text.length; i++) text.substring(0, i)],
  settle: settle,
  shot: shot,
);

/// Leaves [target] holding each of [values] in turn, a [keystroke] apart
/// (a correction is a value that drops the last character), and settles the
/// last with [settle].
Future<void> typeValues(
  ScenarioTester s,
  Object target,
  List<String> values, {
  Settle? settle,
  Shot? shot,
}) async {
  for (final value in values.take(values.length - 1)) {
    await s.enterText(
      target,
      value,
      settle: const Settle.elapse(keystroke),
      shot: Shot.skip,
    );
  }
  await s.enterText(target, values.last, settle: settle, shot: shot);
}

/// [finder], found only once [absent] finds nothing: what a settle waits on
/// when a list narrows to rows it already showed.
Finder onceGone(Finder finder, {required Finder absent}) =>
    find.byWidgetPredicate(
      (widget) =>
          absent.evaluate().isEmpty &&
          finder.evaluate().any((element) => element.widget == widget),
      description:
          '${finder.describeMatch(Plurality.many)} once '
          '${absent.describeMatch(Plurality.many)} is gone',
    );

/// Types [text] into [target] a keystroke at a time and waits until
/// [until] shows: a search box's debounce is a timer, which draws no frame,
/// so settling on frames alone would photograph the list before it
/// searched. [from] skips the characters already there.
Future<void> searchIn(
  ScenarioTester s,
  Object target,
  String text, {
  required Object until,
  int from = 0,
  Shot? shot,
}) => typeInto(
  s,
  target,
  text,
  from: from,
  settle: Settle.until(until),
  shot: shot,
);

/// Has the shop push something ([push], such as `shop.api.simulate
/// .newOrder`) and waits until [until] shows: realtime updates are coalesced
/// on a timer, which draws no frame.
Future<T> realtime<T>(
  ScenarioTester s,
  String shot,
  FutureOr<T> Function() push, {
  required Object until,
}) => s.act(shot, push, settle: Settle.until(until));
