import 'package:flutter/foundation.dart';

/// Keys of this area's controls, as `ValueKey('<area>.<thing>')`.
///
/// The kit's pickers take one key for the whole group: a theme, a segment
/// or a swatch is found inside its group by its localized label.
abstract final class SettingsKeys {
  static const appearancePage = ValueKey('settings.appearancePage');
  static const profilePage = ValueKey('settings.profilePage');

  /// The strip of settings pages: appearance, profile, shop.
  static const tabs = ValueKey('settings.tabs');

  /// The kit's appearance picker: theme, mode, accent and table density.
  static const theme = ValueKey('settings.theme');
  static const preview = ValueKey('settings.preview');
  static const language = ValueKey('settings.language');
  static const reduceMotion = ValueKey('settings.reduceMotion');

  static const account = ValueKey('settings.account');
  static const changePassword = ValueKey('settings.changePassword');
}
