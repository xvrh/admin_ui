/// @docImport '../admin_ui_localizations.dart';
library;

import '../messages.dart';

/// Strings for the layout, data display, feedback, history, tree-editor and
/// insert-picker widgets.
///
/// Every language's class extends this one directly: [DisplayMessagesEn] here,
/// the others in `lib/src/l10n/languages/`. A member added here without
/// its text in every language fails to compile, so add a message to
/// every language in the same edit.
abstract class DisplayMessages extends AdminMessages {
  const DisplayMessages(super.localeName);

  /// [parts] read as one phrase, for an accessible name built from pieces:
  /// "Revenue: $48.2k, up 12%, vs last month".
  String joinParts(List<String> parts);

  // Loading and errors.

  /// The accessible name of a spinner or a progress bar with no text of its
  /// own; [AdminLocalizations.loading] without its ellipsis.
  String get loadingLabel;

  /// A request that ran out of time.
  String get errorTimeout;

  /// A server that could not be reached at all.
  String get errorUnreachable;

  /// A response that came back but could not be parsed.
  String get errorUnreadable;

  /// HTTP 401.
  String get errorUnauthorized;

  /// HTTP 402.
  String get errorPaymentRequired;

  /// HTTP 403.
  String get errorForbidden;

  /// HTTP 404.
  String get errorNotFound;

  /// HTTP 409.
  String get errorConflict;

  /// HTTP 413.
  String get errorTooLarge;

  /// HTTP 429.
  String get errorRateLimited;

  /// HTTP 5xx.
  String get errorServer;

  /// Any other HTTP 4xx.
  String get errorRequestFailed;

  // Breadcrumbs and pagination.

  /// The name of the breadcrumb navigation landmark.
  String get breadcrumb;

  /// The accessible name of the last crumb, the page the reader is on.
  String currentPage(String label);

  /// The caret beside a crumb that lists its sibling pages.
  String get switchPage;

  /// The `…` that stands for [count] collapsed crumbs.
  String showMore(int count);

  /// A page number's accessible name.
  String pageNumber(int page);

  // JSON viewer.

  /// An object's member count, as its folded summary: "3 keys".
  String jsonKeys(int count);

  /// An array's element count, as its folded summary: "3 items".
  String jsonItems(int count);

  String get expandAll;

  String get collapseAll;

  String get copyJson;

  /// A JSON row's action that copies the row's value.
  String get copyValue;

  /// A JSON row's action that copies the row's path, `$.customer.email`.
  String get copyPath;

  /// A source that failed to parse; [detail] is the parser's own message.
  String invalidJson(String detail);

  // Log view.

  /// A log with no lines yet.
  String get logEmpty;

  // Zoom view.

  /// The accessible name of a zoom view, where the app gives none.
  String get zoomArea;

  /// How to zoom and pan a zoom view, read after its name.
  String get zoomAreaHint;

  String get zoomIn;

  String get zoomOut;

  /// Zooms a zoom view out until all of its content shows.
  String get zoomToFit;

  // Upload.

  /// Every upload in the queue finished: "Upload complete" for one file.
  String uploadDone(int total);

  /// A queue still running or with failures: "Uploaded 2 of 5 · 1 failed".
  String uploadProgress(int done, int total, int failed);

  /// Drops every finished and failed row from the queue.
  String get clearCompleted;

  /// A file waiting for its turn.
  String get queued;

  String get retryUpload;

  String get removeFile;

  String get cancelUpload;

  // Charts and stats.

  /// A chart card with nothing to plot.
  String get chartEmpty;

  /// The low end of a heat grid's legend, before its lightest fill.
  String get heatLess;

  /// The high end of a heat grid's legend, after its fullest fill.
  String get heatMore;

  /// A stat tile's name and value: "Revenue: $48.2k".
  String statValue(String label, String value);

  /// A rising trend, spoken: "up 12%".
  String trendUp(String delta);

  /// A falling trend, spoken: "down 0.4%".
  String trendDown(String delta);

  // Dashboard.

  String get needsAttention;

  String get recentActivity;

  String get contentMix;

  /// The noun under a donut's total, which is shown on its own line above
  /// it: "items".
  String itemsUnit(int count);

  /// The attention row when nothing needs attention.
  String get allCaughtUp;

  String get noRecentActivity;

  String get noRecentActivityHint;

  /// An attention tile read as one phrase: "7 drafts to publish, across
  /// pages". [label] is the caller's own noun phrase for [count] things.
  String attentionItem(int count, String label, String? caption);

  // Steps.

  /// A step's position and title: "Step 1 of 4: Account".
  String stepOf(int step, int total, String title);

  String get stepCompleted;

  String get stepCurrent;

  String get stepUpcoming;

  String get stepError;

  // Tree editor.

  /// Adds an entry at the root of the tree.
  String get addItem;

  /// An entry with an empty title.
  String get untitled;

  /// The tag of a header entry, which groups its children and points nowhere
  /// itself.
  String get treeHeader;

  String get indent;

  String get outdent;

  String get addChild;

  /// Hides an entry from what the tree publishes.
  String get hideEntry;

  /// Shows a hidden entry again.
  String get showEntry;

  /// Announced after a keyboard move, as focus stays on the row.
  String movedUp(String title);

  String movedDown(String title);

  String indented(String title);

  String outdented(String title);

  /// Announced after a keyboard or menu move in a tree whose rows the app
  /// draws, as focus stays on the row.
  String get rowMovedUp;

  String get rowMovedDown;

  String get rowIndented;

  String get rowOutdented;

  // Split view.

  /// The accessible name of a split view's divider, a slider whose value is
  /// the share one pane takes.
  String get resizePanes;

  /// Moves a divider between side-by-side panes a step to the left.
  String get moveLeft;

  /// Moves a divider between side-by-side panes a step to the right.
  String get moveRight;

  // Insert picker.

  /// Shows the preview of the highlighted entry.
  String get preview;

  /// The heading of the preview pane, in upper case where the script has
  /// one.
  String get previewHeading;

  /// [previewHeading] for an entry that has no preview.
  String get noPreviewHeading;

  /// Why an entry inserted inline has no preview.
  String get insertsInline;

  /// A search that found nothing; [query] comes quoted.
  String nothingMatches(String query);

  /// The accessible name of the list of entries to insert.
  String get choices;

  // History.

  String get diffAdded;

  String get diffRemoved;

  String get diffChanged;

  String get diffMoved;

  String get diffUnchanged;

  /// A count chip's accessible name: "2 added".
  String addedCount(int count);

  String removedCount(int count);

  String changedCount(int count);

  String movedCount(int count);

  /// The older side of a comparison, set in capitals by the widget.
  String get before;

  /// The newer side of a comparison, set in capitals by the widget.
  String get after;

  /// Who made a version, and when: "Marina Cole · 2 hours ago".
  String authorAndTime(String author, String time);

  /// Where a moved block or record sat, and sits now, 1-based.
  String movedFromTo(int from, int to);

  /// A diff's single-column layout.
  String get unified;

  /// A diff's before | after layout.
  String get split;

  String get noChanges;

  String get versionsIdentical;

  String get noFieldChanges;

  String get noBlockChanges;

  /// The accessible name of a dash standing for no content.
  String get empty;

  /// A word diff's inserted run, spoken, with the pause before the next run.
  String inserted(String text);

  /// A word diff's deleted run, spoken, with the pause before the next run.
  String deleted(String text);

  /// The quiet revert action of a diff.
  String get restore;

  String get restoreThisVersion;

  String get restoreThisField;

  String get restoreThisItem;

  String get restoreLiveBlock;

  /// A field's lane that is not per language.
  String get sharedLane;

  String get versionCurrent;

  String get versionPublished;

  String get versionRestored;

  String get versionArchived;

  /// An archived version by its number: "v3".
  String versionNumber(int version);

  // Mentions.

  /// The accessible name of a mention field's suggestion list.
  String get mentionSuggestions;

  /// Announced as a mention field's suggestions open or change: "3 people
  /// to mention". Never 0, which is `AdminLocalizations.noMatches`.
  String mentionMatches(int count);
}

/// English [DisplayMessages]. Subclass it to override a few strings.
class DisplayMessagesEn extends DisplayMessages {
  const DisplayMessagesEn([super.localeName = 'en']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Loading';

  @override
  String get errorTimeout => 'The server took too long to respond. Try again.';

  @override
  String get errorUnreachable =>
      'Can’t reach the server. Check your connection and try again.';

  @override
  String get errorUnreadable =>
      'The server’s response couldn’t be read. Try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Sign in and try again.';

  @override
  String get errorPaymentRequired => 'That needs a paid plan or more credit.';

  @override
  String get errorForbidden => 'You don’t have permission to do that.';

  @override
  String get errorNotFound =>
      'It couldn’t be found. It may have been moved or deleted.';

  @override
  String get errorConflict =>
      'It was changed somewhere else. Reload and try again.';

  @override
  String get errorTooLarge => 'That’s too large for the server to accept.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorServer =>
      'The server ran into a problem. Try again in a moment.';

  @override
  String get errorRequestFailed => 'The server couldn’t complete the request.';

  @override
  String get breadcrumb => 'Breadcrumb';

  @override
  String currentPage(String label) => '$label, current page';

  @override
  String get switchPage => 'Switch page';

  @override
  String showMore(int count) =>
      plural(count, other: 'Show ${number(count)} more');

  @override
  String pageNumber(int page) => 'Page ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} key',
    other: '${number(count)} keys',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} item',
    other: '${number(count)} items',
  );

  @override
  String get expandAll => 'Expand all';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get copyValue => 'Copy value';

  @override
  String get copyPath => 'Copy path';

  @override
  String invalidJson(String detail) => 'Invalid JSON — $detail';

  @override
  String get logEmpty => 'No output yet';

  @override
  String get zoomArea => 'Zoomable view';

  @override
  String get zoomAreaHint =>
      'Scroll to zoom, drag to pan; + and − zoom, 0 fits, arrow keys pan.';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomToFit => 'Zoom to fit';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Upload complete',
    other: 'All ${number(total)} uploaded',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? 'Uploaded ${number(done)} of ${number(total)}'
      : 'Uploaded ${number(done)} of ${number(total)} · '
            '${number(failed)} failed';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get queued => 'Queued';

  @override
  String get retryUpload => 'Retry upload';

  @override
  String get removeFile => 'Remove file';

  @override
  String get cancelUpload => 'Cancel upload';

  @override
  String get chartEmpty => 'No data for this period';

  @override
  String get heatLess => 'Less';

  @override
  String get heatMore => 'More';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'up $delta';

  @override
  String trendDown(String delta) => 'down $delta';

  @override
  String get needsAttention => 'Needs your attention';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get contentMix => 'Content mix';

  @override
  String itemsUnit(int count) => plural(count, one: 'item', other: 'items');

  @override
  String get allCaughtUp => "You're all caught up — nothing needs attention.";

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get noRecentActivityHint =>
      'Edits, publishes and uploads will show up here.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Step ${number(step)} of ${number(total)}: $title';

  @override
  String get stepCompleted => 'completed';

  @override
  String get stepCurrent => 'current';

  @override
  String get stepUpcoming => 'upcoming';

  @override
  String get stepError => 'error';

  @override
  String get addItem => 'Add item';

  @override
  String get untitled => 'Untitled';

  @override
  String get treeHeader => 'Group';

  @override
  String get indent => 'Indent';

  @override
  String get outdent => 'Outdent';

  @override
  String get addChild => 'Add child';

  @override
  String get hideEntry => 'Hide';

  @override
  String get showEntry => 'Show';

  @override
  String movedUp(String title) => '$title moved up';

  @override
  String movedDown(String title) => '$title moved down';

  @override
  String indented(String title) => '$title indented';

  @override
  String outdented(String title) => '$title outdented';

  @override
  String get rowMovedUp => 'Moved up';

  @override
  String get rowMovedDown => 'Moved down';

  @override
  String get rowIndented => 'Indented';

  @override
  String get rowOutdented => 'Outdented';

  @override
  String get resizePanes => 'Resize panes';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get preview => 'Preview';

  @override
  String get previewHeading => 'PREVIEW';

  @override
  String get noPreviewHeading => 'NO PREVIEW';

  @override
  String get insertsInline => 'Inserts inline — no preview needed.';

  @override
  String nothingMatches(String query) => 'Nothing matches “$query”';

  @override
  String get choices => 'Choices';

  @override
  String get diffAdded => 'Added';

  @override
  String get diffRemoved => 'Removed';

  @override
  String get diffChanged => 'Changed';

  @override
  String get diffMoved => 'Moved';

  @override
  String get diffUnchanged => 'Unchanged';

  @override
  String addedCount(int count) => '${number(count)} added';

  @override
  String removedCount(int count) => '${number(count)} removed';

  @override
  String changedCount(int count) => '${number(count)} changed';

  @override
  String movedCount(int count) => '${number(count)} moved';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'from position ${number(from)} to ${number(to)}';

  @override
  String get unified => 'Unified';

  @override
  String get split => 'Split';

  @override
  String get noChanges => 'No changes';

  @override
  String get versionsIdentical => 'These two versions are identical.';

  @override
  String get noFieldChanges => 'No field changes.';

  @override
  String get noBlockChanges => 'No block changes.';

  @override
  String get empty => 'Empty';

  @override
  String inserted(String text) => 'inserted: $text, ';

  @override
  String deleted(String text) => 'deleted: $text, ';

  @override
  String get restore => 'Restore';

  @override
  String get restoreThisVersion => 'Restore this version';

  @override
  String get restoreThisField => 'Restore this field';

  @override
  String get restoreThisItem => 'Restore this item';

  @override
  String get restoreLiveBlock => 'Restore the live version of this block';

  @override
  String get sharedLane => 'Shared';

  @override
  String get versionCurrent => 'Current';

  @override
  String get versionPublished => 'Published';

  @override
  String get versionRestored => 'Restored';

  @override
  String get versionArchived => 'Archived';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'People to mention';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '1 person to mention',
    other: '${number(count)} people to mention',
  );
}
