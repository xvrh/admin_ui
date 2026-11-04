import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'api/shop_api.dart';
import 'l10n/kit_overrides.dart';
import 'l10n/ref_strings.dart';
import 'routing/route_parser.dart';
import 'routing/routes.dart';
import 'services.dart';

/// Potting Shed's back office: the kit's themes and strings, the app's
/// router, and its services above the Navigator.
class ReferenceAdminApp extends StatefulWidget {
  final AppServices services;

  /// The page to open on. Null opens the one the platform names: the
  /// browser's URL on the web, so a deep link or a reload lands on its page.
  final AppRoute? initialRoute;

  const ReferenceAdminApp({
    super.key,
    required this.services,
    this.initialRoute,
  });

  @override
  State<ReferenceAdminApp> createState() => _ReferenceAdminAppState();
}

class _ReferenceAdminAppState extends State<ReferenceAdminApp> {
  late final RouterConfig<AppRoute> _router = RouterConfig(
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri:
            widget.initialRoute?.uri ??
            Uri.parse(
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            ),
      ),
    ),
    routeInformationParser: const AppRouteParser(),
    routerDelegate: widget.services.router,
    backButtonDispatcher: RootBackButtonDispatcher(),
  );

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    final appearance = services.appearance;
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => MaterialApp.router(
        title: 'Potting Shed',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(appearance.lightTokens),
        darkTheme: buildAppTheme(appearance.darkTokens),
        themeMode: appearance.mode,
        locale: appearance.locale,
        supportedLocales: AdminLocalizations.supportedLocales,
        localizationsDelegates: const [
          RefStrings.delegate,
          PottingShedKitStrings.delegate,
          ...AdminLocalizations.localizationsDelegates,
        ],
        routerConfig: _router,
        builder: (context, child) {
          Widget app = AppServicesScope(
            services: services,
            child: ToastScope(
              // FRICTION(F-019): toasts start at the window's top edge, over
              // the shell's top bar and its actions, unless moved down.
              margin: EdgeInsetsDirectional.only(
                top: context.shellStyle.topBarHeight,
              ),
              child: Builder(
                builder: (context) => ErrorTextScope(
                  describe: (error) => error is ShopError
                      ? context.strings.shell.error(error)
                      : describeError(error, context.adminL10n),
                  child: child!,
                ),
              ),
            ),
          );
          if (appearance.reduceMotion) {
            app = MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: app,
            );
          }
          return app;
        },
      ),
    );
  }
}
