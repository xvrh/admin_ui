import 'package:flutter/foundation.dart';

/// Keys of this area's controls, as `ValueKey('<area>.<thing>')`.
abstract final class AccessKeys {
  // sign in
  static const signInPage = ValueKey('access.signInPage');
  static const signInForm = ValueKey('access.signInForm');
  static const demoAccounts = ValueKey('access.demoAccounts');

  // set password
  static const setPasswordPage = ValueKey('access.setPasswordPage');
  static const setPasswordForm = ValueKey('access.setPasswordForm');
  static const inviteProblem = ValueKey('access.inviteProblem');
  static const backToSignIn = ValueKey('access.backToSignIn');

  // dashboard
  static const dashboardPage = ValueKey('access.dashboardPage');
  static const range = ValueKey('access.range');
  static const stats = ValueKey('access.stats');
  static const revenue = ValueKey('access.revenue');
  static const attention = ValueKey('access.attention');
  static const revenueChart = ValueKey('access.revenueChart');
  static const topProducts = ValueKey('access.topProducts');
  static const channels = ValueKey('access.channels');
  static const statsError = ValueKey('access.statsError');
  static const loading = ValueKey('access.loading');
  static const empty = ValueKey('access.empty');
  static const setUpShop = ValueKey('access.setUpShop');

  // setup and shop settings
  static const setupPage = ValueKey('access.setupPage');
  static const wizard = ValueKey('access.wizard');
  static const summary = ValueKey('access.summary');
  static const shopName = ValueKey('access.shopName');
  static const supportEmail = ValueKey('access.supportEmail');
  static const currency = ValueKey('access.currency');
  static const taxRate = ValueKey('access.taxRate');
  static const languages = ValueKey('access.languages');
  static const zones = ValueKey('access.zones');
  static const review = ValueKey('access.review');
  static const ready = ValueKey('access.ready');
  static const goToDashboard = ValueKey('access.goToDashboard');
  static const shopSettingsPage = ValueKey('access.shopSettingsPage');
  static const shopSaveBar = ValueKey('access.shopSaveBar');

  /// The fields of the shipping zone at [index].
  static ValueKey<String> zoneName(int index) =>
      ValueKey('access.zone.$index.name');
  static ValueKey<String> zoneCountries(int index) =>
      ValueKey('access.zone.$index.countries');
  static ValueKey<String> zoneRate(int index) =>
      ValueKey('access.zone.$index.rate');
}
