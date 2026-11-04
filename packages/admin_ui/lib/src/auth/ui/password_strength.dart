import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// A coarse password-strength rating. Presentational only — a nudge toward a
/// stronger password, never an authority on what the server will accept.
enum PasswordStrength { weak, fair, good, strong }

/// Scores [password] from length and character variety. Below [minLength] is
/// always [PasswordStrength.weak]; otherwise each of {lower, upper, digit,
/// symbol} present and a length bonus build the rating up.
PasswordStrength passwordStrength(String password, {int minLength = 8}) {
  if (password.isEmpty || password.length < minLength) {
    return PasswordStrength.weak;
  }
  var score = 0;
  if (password.contains(RegExp(r'[a-z]'))) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
  if (password.length >= minLength + 4) score++;
  return switch (score) {
    <= 1 => PasswordStrength.weak,
    2 => PasswordStrength.fair,
    3 => PasswordStrength.good,
    _ => PasswordStrength.strong,
  };
}

/// A four-segment bar plus a label, filling and colouring by [passwordStrength].
/// The segments are rounded as the theme's small parts are (square in
/// Carbon), at most to a pill.
///
/// The colours are a fixed status ramp that never follows the brand — red,
/// amber, a lighter green, green — so the scale reads the same way under any
/// primary. The label, in the app's language, takes the width of the
/// longest one, so the bar never changes length as the rating does and no
/// translation is cut short.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final int minLength;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.minLength = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strength = passwordStrength(password, minLength: minLength);
    final filled = strength.index + 1;
    final (accent, text) = switch (strength) {
      PasswordStrength.weak => (colors.danger, colors.dangerText),
      PasswordStrength.fair => (colors.warning, colors.warningText),
      PasswordStrength.good => (
        Color.alphaBlend(
          // token-literal: the meter step between fair and strong
          colors.success.withValues(alpha: 0.55),
          colors.surface,
        ),
        colors.successText,
      ),
      PasswordStrength.strong => (colors.success, colors.successText),
    };
    final style = context.type.fieldMessage;
    final shell = context.adminL10n.shell;
    final labels = {
      PasswordStrength.weak: shell.strengthWeak,
      PasswordStrength.fair: shell.strengthFair,
      PasswordStrength.good: shell.strengthGood,
      PasswordStrength.strong: shell.strengthStrong,
    };

    final corner = math.min(context.radii.radiusSmall, _segment / 2);
    return Row(
      children: [
        for (var i = 0; i < PasswordStrength.values.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.xs),
          Expanded(
            child: Container(
              height: _segment,
              decoration: BoxDecoration(
                color: i < filled ? accent : colors.border,
                borderRadius: BorderRadius.circular(corner),
              ),
            ),
          ),
        ],
        const Gap(AdminSpacing.md),
        Stack(
          alignment: AlignmentDirectional.centerEnd,
          children: [
            for (final MapEntry(key: step, value: label) in labels.entries)
              Visibility(
                visible: step == strength,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(label, style: style.copyWith(color: text)),
              ),
          ],
        ),
      ],
    );
  }
}

/// A segment's thickness.
const _segment = 4.0;
