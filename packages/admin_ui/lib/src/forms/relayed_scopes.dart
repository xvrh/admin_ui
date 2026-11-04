import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';

import '../assets/asset_source.dart';
import '../assets/external_provider.dart';
import '../common/ui/field_presence.dart';
import '../i18n/lang_scope.dart';
import 'field_binder.dart';

/// The scopes an asset sheet or dialog reads, as the context that opened it
/// sees them, read without depending on them.
@internal
class OpenerScopes {
  final BuildContext context;
  final AssetSourceScope? source;
  final ExternalProviderScope? providers;
  final LangScope? lang;
  final FieldPresenceScope? presence;
  final FieldBinderScope? binder;

  const OpenerScopes._(
    this.context, {
    required this.source,
    required this.providers,
    required this.lang,
    required this.presence,
    required this.binder,
  });

  factory OpenerScopes.of(BuildContext context) => OpenerScopes._(
    context,
    source: context.getInheritedWidgetOfExactType<AssetSourceScope>(),
    providers: context.getInheritedWidgetOfExactType<ExternalProviderScope>(),
    lang: context.getInheritedWidgetOfExactType<LangScope>(),
    presence: context.getInheritedWidgetOfExactType<FieldPresenceScope>(),
    binder: context.getInheritedWidgetOfExactType<FieldBinderScope>(),
  );

  /// These scopes read again from the opening context, while it is mounted.
  OpenerScopes reread() => context.mounted ? OpenerScopes.of(context) : this;
}

/// Provides [opener]'s scopes to [child], each one the anchor it is shown on
/// does not already provide. A scope the anchor provides as the opener does
/// (the anchor mounted below it) stays live and is left alone. A language
/// shown or hidden in [child] goes to the opener's [LangScope], which is
/// then read back.
///
/// Used by `showAssetDetail` and `showAssetEditor`, so an editor opened from
/// the detail sheet finds the same scopes the sheet did.
@internal
class RelayedScopes extends StatefulWidget {
  final OpenerScopes opener;
  final Widget child;

  const RelayedScopes({super.key, required this.opener, required this.child});

  @override
  State<RelayedScopes> createState() => _RelayedScopesState();
}

class _RelayedScopesState extends State<RelayedScopes> {
  late OpenerScopes _scopes = widget.opener;

  /// Which scopes the anchor shares with the opener, decided on open.
  late final bool _sharesSource, _sharesProviders, _sharesLang;
  late final bool _sharesPresence, _sharesBinder;

  @override
  void initState() {
    super.initState();
    final o = widget.opener;
    _sharesSource = _shares(o.source);
    _sharesProviders = _shares(o.providers);
    _sharesLang = _shares(o.lang);
    _sharesPresence = _shares(o.presence);
    _sharesBinder = _shares(o.binder);
  }

  bool _shares<T extends InheritedWidget>(T? scope) =>
      identical(context.getInheritedWidgetOfExactType<T>(), scope);

  /// The page's handler rebuilds its scope; this reads it back after the
  /// frame that does.
  void _onVisibleLocalesChanged(LangScope lang, Set<String> visible) {
    lang.onVisibleLocalesChanged(visible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _scopes = _scopes.reread());
    });
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    final s = _scopes;
    if (s.binder case final binder? when !_sharesBinder) {
      child = FieldBinderScope(binder: binder.binder, child: child);
    }
    if (s.presence case final presence? when !_sharesPresence) {
      child = FieldPresenceScope(channel: presence.channel, child: child);
    }
    if (s.lang case final lang? when !_sharesLang) {
      child = LangScope(
        locales: lang.locales,
        visibleLocales: lang.visibleLocales,
        sourceLocale: lang.sourceLocale,
        activeLocale: lang.activeLocale,
        onVisibleLocalesChanged: (visible) =>
            _onVisibleLocalesChanged(lang, visible),
        child: child,
      );
    }
    if (s.providers case final providers? when !_sharesProviders) {
      child = ExternalProviderScope(
        providers: providers.providers,
        child: child,
      );
    }
    if (s.source case final source? when !_sharesSource) {
      child = AssetSourceScope(source: source.source, child: child);
    }
    return child;
  }
}
