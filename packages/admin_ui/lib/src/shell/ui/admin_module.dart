import 'package:flutter/widgets.dart';

/// A self-contained admin vertical contributed by a feature module (background
/// jobs, a stock-image provider, …). The app collects modules into one list and
/// the shell turns each into a sidebar entry + a route + (optionally) the
/// [extensions] it contributes, such as media providers — so activating a
/// module is one list entry rather than edits spread across nav, router and
/// scope wiring.
///
/// The app constructs each module and supplies its client (see the per-module
/// `*Module(...)` factories). A module's client is therefore the app's to wire;
/// a provider module whose client is only used internally — its config screen
/// and the [extensions] it contributes — needs no slot on the app's generated
/// client at all.
class AdminModule {
  /// Route key under the dashboard router, e.g. `'jobs'`.
  final String route;

  /// Sidebar grouping header; entries sharing a section coalesce under it.
  final String? navSection;
  final String navLabel;
  final IconData navIcon;

  /// Built lazily for [route]; closes over the module's client.
  final WidgetBuilder builder;

  /// When false the module is fully suppressed — nav entry, route and
  /// [extensions] all drop out (e.g. gated to admins).
  final bool enabled;

  /// What the module contributes to the rest of the admin, of any type: an
  /// `ExternalAssetProvider` for the media picker, say. The app collects
  /// each kind it knows from its enabled modules with [extensionsOf], and
  /// ignores the rest.
  final List<Object> extensions;

  const AdminModule({
    required this.route,
    required this.navLabel,
    required this.navIcon,
    required this.builder,
    this.navSection,
    this.enabled = true,
    this.extensions = const [],
  });

  /// The [extensions] that are a [T], in order:
  /// `extensionsOf<ExternalAssetProvider>()` for the module's media
  /// providers.
  Iterable<T> extensionsOf<T>() => extensions.whereType<T>();
}
