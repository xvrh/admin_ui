import 'package:admin_ui/shell.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';

/// The placeholder a work package replaces with its screen: the page's
/// title over an empty state, so every route opens and lays out from day one.
class PageStub extends StatelessWidget {
  final String title;
  final IconData icon;

  const PageStub({
    super.key,
    required this.title,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      body: EmptyState(
        key: ShellKeys.stub,
        icon: icon,
        title: context.strings.shell.stubMessage,
      ),
    );
  }
}
