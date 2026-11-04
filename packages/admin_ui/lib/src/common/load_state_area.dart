import 'package:flutter/widgets.dart';

/// A load state (loading, error, empty) standing in for a panel's scrolling
/// body: [child] inside [padding], centred in all the room the panel gives the
/// body, and scrolling rather than overflowing where it is taller than that
/// room, as under a large text size.
///
/// The room is the minimum, so give [child] none of its own (`minHeight: 0`
/// on an `EmptyState`, `ErrorState` or `LoadingPanel`).
class LoadStateArea extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const LoadStateArea({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final body = Padding(padding: padding, child: child);
        if (!box.hasBoundedHeight) return body;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: body,
          ),
        );
      },
    );
  }
}
