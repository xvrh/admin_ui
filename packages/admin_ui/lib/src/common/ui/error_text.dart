import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/sections/display_messages.dart';

/// [error] as one sentence a person can act on, never an exception's class
/// name or raw text: an unreachable server, a timeout, an HTTP status the
/// error names, an unreadable response — and otherwise 'Something went
/// wrong. Try again.' A [String] thrown as the error is taken as its own
/// message. The sentences come from [l10n], English by default;
/// [ErrorTextScope.describe] passes the ambient ones.
///
/// Recognition goes by type where the type exists on every platform and by
/// the error's text otherwise (`dart:io` is not there on the web, and a
/// release web build minifies class names). Show errors through
/// [ErrorTextScope.describe], which an app can override.
String describeError(
  Object error, [
  AdminLocalizations l10n = const AdminLocalizationsEn(),
]) {
  if (error is String && error.trim().isNotEmpty) return error.trim();
  final strings = l10n.display;
  final text = '$error'.toLowerCase();
  if (_status(text) case final status?) return _describeStatus(status, strings);
  if (error is TimeoutException ||
      text.contains('timeoutexception') ||
      text.contains('timed out')) {
    return strings.errorTimeout;
  }
  if (_unreachable.any(text.contains)) return strings.errorUnreachable;
  if (error is FormatException) return strings.errorUnreadable;
  return l10n.somethingWentWrongTryAgain;
}

/// What a network failure says of itself: `SocketException`, `HttpException`
/// and `HandshakeException` on the VM, `package:http`'s `ClientException`,
/// and the browser's own words for a failed request.
const _unreachable = [
  'socketexception',
  'clientexception',
  'handshakeexception',
  'httpexception',
  'failed host lookup',
  'connection refused',
  'connection reset',
  'connection closed',
  'network is unreachable',
  'xmlhttprequest error',
  'failed to fetch',
  'networkerror',
];

/// An HTTP status the error's text names: `status 404`, `statusCode: 500`,
/// `HTTP 503`, `status code: 429`.
final _statusPattern = RegExp(
  r'(?:status(?:\s*code)?|http)\D{0,3}([1-5]\d\d)\b',
);

int? _status(String text) {
  final match = _statusPattern.firstMatch(text);
  final status = match == null ? null : int.parse(match.group(1)!);
  return status != null && status >= 400 ? status : null;
}

/// A status in words. Only the ones a retry can cure — a timeout, a rate
/// limit, a server fault — say to try again.
String _describeStatus(int status, DisplayMessages strings) => switch (status) {
  401 => strings.errorUnauthorized,
  402 => strings.errorPaymentRequired,
  403 => strings.errorForbidden,
  404 => strings.errorNotFound,
  408 || 504 => strings.errorTimeout,
  409 => strings.errorConflict,
  413 => strings.errorTooLarge,
  429 => strings.errorRateLimited,
  >= 500 => strings.errorServer,
  _ => strings.errorRequestFailed,
};

/// How the admin words failures, for everything below it: each widget that
/// shows an error puts it through [ErrorTextScope.describe], which asks the
/// nearest scope and falls back to [describeError]. An app provides one to
/// word its own backend's errors, and can defer to [describeError] for the
/// rest.
class ErrorTextScope extends InheritedWidget {
  /// Words an error for everything below; passed as `describe`.
  final String Function(Object error) _describe;

  const ErrorTextScope({
    super.key,
    required this._describe,
    required super.child,
  });

  /// [error] in words, from the nearest scope or [describeError]. Call it
  /// where [context] is mounted — in `build`, ideally, with the raw error
  /// kept in state — so a change of scope rewords it. In a debug build the
  /// raw error is logged, once per error, so it is still to be found.
  static String describe(BuildContext context, Object error) {
    if (kDebugMode && !identical(error, _lastLogged)) {
      _lastLogged = error;
      debugPrint('ErrorTextScope: $error');
    }
    final scope = context.dependOnInheritedWidgetOfExactType<ErrorTextScope>();
    if (scope != null) return scope._describe(error);
    return describeError(error, AdminLocalizations.of(context));
  }

  static Object? _lastLogged;

  @override
  bool updateShouldNotify(ErrorTextScope old) => _describe != old._describe;
}
