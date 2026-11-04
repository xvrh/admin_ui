import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../frame/navigation.dart';
import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';
import '../routing/routes.dart';
import '../services.dart';

/// A page the signed-in role may not open.
// FRICTION(F-014): no forbidden-page preset; built from EmptyState.
class ForbiddenPage extends StatelessWidget {
  final Forbidden route;
  const ForbiddenPage(this.route, {super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.shell;
    final asked = route.from.nav;
    // Headed by the page asked for, so the state below says why, once.
    return PageScaffold(
      key: ShellKeys.forbidden,
      title: asked == null ? strings.forbiddenTitle : navLabel(strings, asked),
      body: EmptyState(
        icon: Icons.lock_outline,
        title: strings.forbiddenTitle,
        message: strings.forbiddenMessage,
        action: Button(
          strings.backToDashboard,
          key: ShellKeys.backToDashboard,
          onPressed: () => context.go(const Dashboard()),
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  final NotFound route;
  const NotFoundPage(this.route, {super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.shell;
    // No page header: there is no page, and the state says so once.
    return KeyedSubtree(
      key: ShellKeys.notFound,
      child: EmptyState(
        icon: Icons.travel_explore_outlined,
        title: strings.notFoundTitle,
        message: strings.notFoundMessage(bidiIsolate(route.path)),
        action: Button(
          strings.backToDashboard,
          key: ShellKeys.backToDashboard,
          onPressed: () => context.go(const Dashboard()),
        ),
      ),
    );
  }
}
