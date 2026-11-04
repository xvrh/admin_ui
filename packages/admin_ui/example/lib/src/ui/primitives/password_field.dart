import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class PasswordFieldDemo extends StatelessWidget {
  @Preview(name: 'Password field', wrapper: adminUiPreview)
  const PasswordFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        const DemoVariant(
          'Focused, labelled (lock glyph, reveal toggle)',
          PasswordField(label: 'Password', autofocus: true),
        ),
        const DemoVariant(
          'With a description',
          PasswordField(
            label: 'New password',
            description: 'At least 8 characters.',
            autofillHints: [AutofillHints.newPassword],
          ),
        ),
        const DemoVariant(
          'Sizes — small, medium, large',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(value: 'small', size: ControlSize.small),
              Gap(AdminSpacing.md),
              PasswordField(value: 'medium'),
              Gap(AdminSpacing.md),
              PasswordField(value: 'large', size: ControlSize.large),
            ],
          ),
        ),
        const DemoVariant(
          'No leading glyph, no label',
          PasswordField(icon: null, hint: 'Paste a token'),
        ),
        const DemoVariant(
          'Invalid',
          PasswordField(
            label: 'Password',
            value: 'short',
            errorText: 'Use at least 8 characters.',
          ),
        ),
        const DemoVariant(
          'Read-only — can still be revealed',
          PasswordField(
            label: 'Signing key',
            value: 'k3y-demo',
            readOnly: true,
          ),
        ),
        const DemoVariant(
          'Disabled',
          PasswordField(label: 'Password', value: 'locked', enabled: false),
        ),
        DemoVariant(
          'Live — echoes the value',
          LiveValue<String>(
            initial: '',
            builder: (value, onChanged) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  label: 'Password',
                  onChanged: onChanged,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const Gap(AdminSpacing.md),
                Text(
                  value.isEmpty ? '(empty)' : 'You typed ${value.length} chars',
                  style: context.type.bodyMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
