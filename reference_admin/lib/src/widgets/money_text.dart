import 'package:admin_ui/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/money.dart';

/// An amount in euros, in the page's locale, with tabular figures so a
/// column of them lines up.
class MoneyText extends StatelessWidget {
  final int cents;
  final TextStyle? style;

  const MoneyText(this.cents, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.type.body;
    return Text(
      formatMoney(context, cents),
      style: base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
