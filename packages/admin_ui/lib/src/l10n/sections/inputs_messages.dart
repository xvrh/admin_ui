import '../../theme/table_metrics.dart';
import '../messages.dart';

/// Strings for the inputs, menus, pickers and overlays in common/ui, and
/// the shell's appearance picker.
///
/// Every language's class extends this one directly: [InputsMessagesEn] here,
/// the others in `lib/src/l10n/languages/`. A member added here without
/// its text in every language fails to compile, so add a message to
/// every language in the same edit.
abstract class InputsMessages extends AdminMessages {
  const InputsMessages(super.localeName);

  // Dialogs and actions.

  /// The confirm button of a confirmation dialog.
  String get confirm;

  /// A copy button's confirmation, and what a screen reader hears after it.
  String get copied;

  /// A copy button's report that the clipboard refused the text.
  String get copyFailed;

  /// Takes back what was just done, as a toast's action after a delete.
  String get undo;

  /// Expands text or a list shown clipped, such as a long message.
  String get showMore;

  /// Clips again what [showMore] expanded.
  String get showLess;

  // Text inputs.

  /// The reveal toggle of a password field while the password is hidden.
  String get showPassword;

  /// The reveal toggle of a password field while the password shows.
  String get hidePassword;

  /// The clear button of a search field.
  String get clearSearch;

  // Selects and listboxes.

  /// A combobox's search failed; shown beside a retry.
  String get couldNotLoadResults;

  /// A highlighted option as a screen reader hears it: its [label] and its
  /// [position] among [count] options, "France, 3 of 12".
  String optionOf(String label, int position, int count);

  // Date-range picker.

  /// The accessible name of the trigger, read before its span.
  String get dateRange;

  /// The clear button of the trigger.
  String get clearDates;

  /// A span of two formatted dates, both included: "Jun 1 – Jun 15".
  String dateSpan(String start, String end);

  /// The preset ending today that spans [count] days.
  String lastDays(int count);

  /// The preset from the first of this month to today.
  String get thisMonth;

  /// The preset covering the whole previous month.
  String get lastMonth;

  /// The preset from January 1st to today.
  String get yearToDate;

  // Command palette.

  /// The palette's query placeholder.
  String get searchOrJumpTo;

  /// The section of recently used items, shown on an empty query.
  String get recent;

  /// The preview pane with nothing selected.
  String get selectAResult;

  /// Where a content hit matched: [place] is a part of the record, such as
  /// "Body" or a language.
  String matchedIn(String place);

  /// [matchedIn] for a hit that names no part.
  String get matchedInContent;

  /// Enter's effect on a selected command.
  String get run;

  /// Enter's effect on a selected piece of content.
  String get open;

  /// The palette before anything is typed.
  String get typeToSearch;

  /// The palette when [query] matched nothing.
  String noResultsFor(String query);

  /// How many results a query found, announced once it settles.
  String resultCount(int count);

  /// The footer hint for the arrow keys.
  String get navigateHint;

  /// The footer hint for Enter.
  String get selectHint;

  /// The footer hint for Escape.
  String get closeHint;

  /// The up and down arrow keys, spoken.
  String get keysUpDown;

  /// The Enter key, spoken.
  String get keyEnter;

  /// The Escape key, spoken.
  String get keyEscape;

  /// The palette group the current form's fields are listed under.
  String get fieldsGroup;

  // Notification center.

  /// The inbox's title and the bell's accessible name.
  String get notifications;

  /// The inbox with nothing in it.
  String get allCaughtUp;

  /// Marks every notification as read.
  String get markAllRead;

  /// Spoken with a notification that has not been read yet.
  String get unread;

  /// The inbox's filter tab that shows every notification, beside [unread].
  String get allNotifications;

  /// Marks one notification as read.
  String get markAsRead;

  /// Marks one read notification as unread again.
  String get markAsUnread;

  /// The inbox's footer link to the page with every notification.
  String get viewAll;

  /// The inbox's notifications failed to load; shown beside a retry.
  String get couldNotLoadNotifications;

  /// The bell's accessible name with [count] unread notifications; [title]
  /// is the inbox's title.
  String unreadCount(String title, int count);

  // Appearance picker.

  /// The theme picker's label. The themes' names are names, the same in
  /// every language.
  String get appearanceTheme;

  /// The label of the choice between [modeLight], [modeDark] and
  /// [modeSystem].
  String get appearanceMode;

  /// Always light.
  String get modeLight;

  /// Always dark.
  String get modeDark;

  /// Light or dark as the device is set.
  String get modeSystem;

  /// The accent swatches' label.
  String get accentColour;

  /// The swatch that keeps the theme's own primary colour.
  String get themeAccent;

  /// An accent's name, as its swatch is announced and captioned: those of
  /// `adminAccents` ("Crimson", "Violet", "Teal", "Amber") in this language,
  /// any other [name] as it is.
  String accentName(String name);

  /// The label of the choice of [TableDensity].
  String get tableDensity;

  /// A [TableDensity]'s name.
  String densityName(TableDensity density);
}

/// English [InputsMessages]. Subclass it to override a few strings.
class InputsMessagesEn extends InputsMessages {
  const InputsMessagesEn([super.localeName = 'en']);

  @override
  String get confirm => 'Confirm';

  @override
  String get copied => 'Copied';

  @override
  String get copyFailed => 'Copy failed';

  @override
  String get undo => 'Undo';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get couldNotLoadResults => 'Couldn’t load results';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} of ${number(count)}';

  @override
  String get dateRange => 'Date range';

  @override
  String get clearDates => 'Clear dates';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) =>
      plural(count, one: 'Last day', other: 'Last ${number(count)} days');

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get yearToDate => 'Year to date';

  @override
  String get searchOrJumpTo => 'Search or jump to…';

  @override
  String get recent => 'Recent';

  @override
  String get selectAResult => 'Select a result';

  @override
  String matchedIn(String place) => 'Matched in $place';

  @override
  String get matchedInContent => 'Matched in content';

  @override
  String get run => 'Run';

  @override
  String get open => 'Open';

  @override
  String get typeToSearch => 'Type to search';

  @override
  String noResultsFor(String query) => 'No results for “$query”';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'No results',
    one: '${number(count)} result',
    other: '${number(count)} results',
  );

  @override
  String get navigateHint => 'navigate';

  @override
  String get selectHint => 'select';

  @override
  String get closeHint => 'close';

  @override
  String get keysUpDown => 'Up and down arrows';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyEscape => 'Escape';

  @override
  String get fieldsGroup => 'Fields';

  @override
  String get notifications => 'Notifications';

  @override
  String get allCaughtUp => 'You’re all caught up';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get unread => 'Unread';

  @override
  String get allNotifications => 'All';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get viewAll => 'View all';

  @override
  String get couldNotLoadNotifications => 'Couldn’t load notifications';

  @override
  String unreadCount(String title, int count) =>
      '$title, ${number(count)} unread';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceMode => 'Mode';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeSystem => 'System';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get themeAccent => 'Theme colour';

  @override
  String accentName(String name) => name;

  @override
  String get tableDensity => 'Table density';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compact',
    TableDensity.standard => 'Standard',
    TableDensity.comfortable => 'Comfortable',
  };
}
