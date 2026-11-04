import 'package:flutter/foundation.dart';

import '../api/shop_api.dart';
import '../appearance/appearance_controller.dart';

/// Who is signed in, and what their role lets them do.
///
/// The UI asks [can] to hide what a role may not do, and passes
/// `readOnly: true` to forms; the shop refuses the same calls with
/// `ShopError.forbidden` all the same.
// FRICTION(F-014): the kit has no permission model beyond a read-only form.
class SessionController extends ChangeNotifier {
  final ShopApi _api;
  final AppearanceController _appearance;

  SessionController(this._api, this._appearance);

  Session? _session;

  Session? get session => _session;
  StaffMember? get user => _session?.staff;
  bool get isSignedIn => _session != null;
  Role? get role => user?.role;

  bool can(Permission permission) => role?.can(permission) ?? false;

  /// The shop was renamed (its settings saved, or setup finished): the
  /// frame's header follows.
  void shopRenamed(String name) {
    final session = _session;
    if (session == null || session.shopName == name) return;
    _session = session.copyWith(shopName: name);
    notifyListeners();
  }

  /// Signs in, then takes the staff member's appearance before the first
  /// page shows.
  Future<void> signIn(String email, String password) async =>
      _enter(await _api.signIn(email, password));

  /// Accepts an invitation with a first password, and signs in.
  Future<void> setPassword(String token, String password) async =>
      _enter(await _api.setPassword(token, password));

  /// Starts signed in as [session] without asking the shop: the app launched
  /// signed in, or a scenario that is not about signing in.
  void adopt(Session session) {
    _session = session;
    _appearance.save = _api.savePrefs;
    notifyListeners();
  }

  Future<void> _enter(Session session) async {
    _session = session;
    try {
      _appearance.apply(await _api.loadPrefs());
    } on ShopError {
      // The last look stays; the next change saves over it.
    }
    _appearance.save = _api.savePrefs;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _api.signOut();
    } on ShopError {
      // Signed out here whatever the shop says.
    }
    _session = null;
    _appearance.save = null;
    notifyListeners();
  }
}
