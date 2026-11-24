import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A scroll controller whose next position starts at [start], which that
/// position spends: one made later, when a skeleton gives way to rows,
/// starts at the top as before.
///
/// It keeps no offset in a `PageStorage`: a `TableView`'s two axes would
/// share one entry there, and where a view starts is its
/// `CollectionPosition`'s to say.
@internal
class StartScrollController extends ScrollController {
  StartScrollController() : super(keepScrollOffset: false);

  double start = 0;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    final position = ScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: start,
      keepScrollOffset: false,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
    start = 0;
    return position;
  }

  /// Back to the top after this frame: one may be building, which a jump
  /// must not notify.
  void toTopAfterFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasClients && positions.last.pixels != 0) jumpTo(0);
    });
  }

  /// The offset of the position last attached, or 0 with none.
  double get lastPixels => positions.isEmpty ? 0 : positions.last.pixels;
}
