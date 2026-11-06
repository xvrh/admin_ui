/// @docImport 'collection.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../common/ui/delayed_loading.dart';
import '../common/ui/error_state.dart';
import '../common/ui/error_text.dart';
import '../common/ui/spinner.dart';
import '../l10n/admin_ui_localizations.dart';
import 'async_value_controller.dart';

/// Draws an [AsyncValueController]'s value with [builder], and its load
/// states the way a [Collection] draws its rows':
///
/// - Until the first value lands, [placeholder]; by default a
///   [LoadingPanel], once the load has run 150ms.
/// - A refresh keeps the value on screen, with a progress bar along its top
///   edge once it runs past 150ms. A background refresh shows none.
/// - A failed load shows an [ErrorState] in place of the value, with the
///   error put in words by [ErrorTextScope.describe] and a Retry, so a
///   value that failed to refresh does not pass for current.
///
/// It passes its constraints to [builder]'s widget as they are.
class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValueController<T> controller;

  /// Builds the loaded value.
  final Widget Function(BuildContext context, T value) builder;

  /// Shown from the first frame until the first value lands: give it the
  /// value's size, as a skeleton has, so nothing moves when the value
  /// lands. When null, a [LoadingPanel] shows once the load has run 150ms,
  /// so a quick one never flashes a spinner.
  final Widget? placeholder;

  /// Builds the error body from the thrown error and a retry callback.
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;

  const AsyncValueBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        if (c.error case final error?) {
          return errorBuilder?.call(error, c.refresh) ??
              ErrorState(
                title: context.adminL10n.couldNotLoad,
                message: ErrorTextScope.describe(context, error),
                onRetry: c.refresh,
              );
        }
        return DelayedLoading(
          loading: c.loading,
          builder: (context, show) {
            if (!c.hasValue) {
              return placeholder ??
                  (show ? const LoadingPanel() : const SizedBox.shrink());
            }
            return Stack(
              fit: StackFit.passthrough,
              children: [
                builder(context, c.value as T),
                if (show)
                  const PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    child: TopProgressBar(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
