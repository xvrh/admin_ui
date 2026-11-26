import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The shared chrome for every auth screen: a centred, width-capped card on a
/// full-bleed background, or with [framed] false the same column on the
/// background itself. All of sign-in, set-password and change-password drop
/// their form into [child] so the branding and layout live in one place.
///
/// Pure presentation — branding comes in as slots ([logo], [title], [footer]) so
/// each project skins it without the library knowing the product.
class AuthScaffold extends StatelessWidget {
  /// Brand mark above the title — a logo image, wordmark, or any widget.
  final Widget? logo;

  final String title;
  final String? subtitle;

  /// The form (e.g. [SignInForm]).
  final Widget child;

  /// Below the card — legal links, an environment badge, a "back to sign in"
  /// link, etc.
  final Widget? footer;

  /// Card width. The card never grows past this on wide screens.
  final double maxWidth;

  /// Whether the header and the form sit in a card. Unframed, they sit on
  /// the page's background, with no fill, border, shadow or inner padding,
  /// and the title is the page's ([AdminTypography.pageTitle]) rather than
  /// a card's heading.
  final bool framed;

  /// How the [logo], [title] and [subtitle] line up across the card — all
  /// three together, so the header reads along one axis:
  /// [CrossAxisAlignment.center] (the default) or [CrossAxisAlignment.start].
  final CrossAxisAlignment align;

  const AuthScaffold({
    super.key,
    this.logo,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.maxWidth = 380,
    this.align = CrossAxisAlignment.center,
    this.framed = true,
  }) : assert(
         align == CrossAxisAlignment.start ||
             align == CrossAxisAlignment.center,
         'AuthScaffold.align is start or center',
       );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = this.subtitle;
    final footer = this.footer;
    final centered = align == CrossAxisAlignment.center;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: framed
                      ? BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(
                            context.radii.radiusLarge,
                          ),
                          border: Border.all(color: colors.border),
                          boxShadow: context.elevation.md,
                        )
                      : null,
                  padding: framed
                      ? const EdgeInsets.all(AdminSpacing.xxl)
                      : EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (logo != null) ...[
                        Align(
                          alignment: centered
                              ? AlignmentDirectional.center
                              : AlignmentDirectional.centerStart,
                          child: logo,
                        ),
                        const Gap(AdminSpacing.xl),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: framed
                              ? context.type.heading
                              : context.type.pageTitle,
                          textAlign: textAlign,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const Gap(AdminSpacing.xs),
                        Text(
                          subtitle,
                          style: context.type.bodyMuted,
                          textAlign: textAlign,
                        ),
                      ],
                      const Gap(AdminSpacing.xl),
                      child,
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const Gap(AdminSpacing.xl),
                  DefaultTextStyle.merge(
                    style: context.type.caption,
                    textAlign: TextAlign.center,
                    child: footer,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
