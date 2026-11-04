/// Why a [ShopApi] call failed. Screens switch on the case; the frame's
/// `ErrorTextScope` words every case in the app's language.
///
/// @docImport 'shop_api.dart';
library;

sealed class ShopError implements Exception {
  const ShopError();

  const factory ShopError.network() = NetworkError;
  const factory ShopError.offline() = OfflineError;
  const factory ShopError.validation(Map<String, String> fields) =
      ValidationError;
  const factory ShopError.conflict() = ConflictError;
  const factory ShopError.forbidden() = ForbiddenError;
  const factory ShopError.notFound() = NotFoundError;
  const factory ShopError.expired() = ExpiredError;
  const factory ShopError.server() = ServerError;

  /// The HTTP status a real server would answer with, for the call log.
  int get status;
}

/// The request never reached the shop.
final class NetworkError extends ShopError {
  const NetworkError();
  @override
  int get status => 0;
  @override
  String toString() => 'ShopError.network';
}

/// The device is offline: every call fails until it is back.
final class OfflineError extends ShopError {
  const OfflineError();
  @override
  int get status => 0;
  @override
  String toString() => 'ShopError.offline';
}

/// The server refused some fields. [fields] maps a field name the call took
/// (`amount`, `sku`, `email`) to a machine code the screen words itself
/// (see `ValidationCodes`).
final class ValidationError extends ShopError {
  final Map<String, String> fields;
  const ValidationError(this.fields);
  @override
  int get status => 422;
  @override
  String toString() => 'ShopError.validation($fields)';
}

/// The record changed since it was read.
final class ConflictError extends ShopError {
  const ConflictError();
  @override
  int get status => 409;
  @override
  String toString() => 'ShopError.conflict';
}

/// The signed-in role may not do this.
final class ForbiddenError extends ShopError {
  const ForbiddenError();
  @override
  int get status => 403;
  @override
  String toString() => 'ShopError.forbidden';
}

final class NotFoundError extends ShopError {
  const NotFoundError();
  @override
  int get status => 404;
  @override
  String toString() => 'ShopError.notFound';
}

/// A link or invitation that is no longer valid.
final class ExpiredError extends ShopError {
  const ExpiredError();
  @override
  int get status => 410;
  @override
  String toString() => 'ShopError.expired';
}

final class ServerError extends ShopError {
  const ServerError();
  @override
  int get status => 500;
  @override
  String toString() => 'ShopError.server';
}

/// The codes a [ValidationError] carries per field.
abstract final class ValidationCodes {
  static const tooHigh = 'too_high';
  static const taken = 'taken';
  static const duplicate = 'duplicate';
  static const invalid = 'invalid';
  static const wrongPassword = 'wrong_password';
  static const locked = 'locked';
  static const tooWeak = 'too_weak';

  /// An order cannot go from its status to the one asked.
  static const notAllowed = 'not_allowed';
}
