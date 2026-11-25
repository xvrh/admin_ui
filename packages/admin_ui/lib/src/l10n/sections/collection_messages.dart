import '../messages.dart';

/// Strings for the collection kit: the table, toolbar, filters, pager and
/// views.
///
/// Every language's class extends this one directly: [CollectionMessagesEn] here,
/// the others in `lib/src/l10n/languages/`. A member added here without
/// its text in every language fails to compile, so add a message to
/// every language in the same edit.
abstract class CollectionMessages extends AdminMessages {
  const CollectionMessages(super.localeName);

  // ── table and cards ──

  /// The title of an empty collection that no filter narrowed.
  String get nothingHereYet;

  /// Under "No results": a search or a filter left nothing.
  String get noResultsMessage;

  /// Clears the search and every filter of a collection.
  String get clearFilters;

  /// A column menu entry.
  String get sortAscending;

  /// A column menu entry.
  String get sortDescending;

  /// A column menu entry that returns the rows to their unsorted order.
  String get clearSort;

  /// A column menu entry that freezes the column at the table's start.
  String get pinColumn;

  /// A column menu entry that lets a pinned column scroll again.
  String get unpinColumn;

  /// A column menu entry that returns a resized column to its width.
  String get resetWidth;

  /// A column menu entry.
  String get hideColumn;

  /// A column menu entry that opens the column chooser, with an ellipsis.
  String get manageColumns;

  /// The accessible action that opens a column's menu.
  String get columnOptions;

  /// The accessible name of [column]'s menu button.
  String columnOptionsFor(String column);

  /// A sortable column header as read aloud, while another column sorts.
  String notSorted(String column);

  /// A column header as read aloud, while it sorts ascending.
  String sortedAscending(String column);

  /// A column header as read aloud, while it sorts descending.
  String sortedDescending(String column);

  /// The accessible name of the checkbox of the [row]th row, from 1.
  String selectRow(int row);

  /// The accessible name of the header checkbox.
  String get selectAllOnPage;

  /// The accessible name of the checkbox of the [card]th card, from 1.
  String selectCard(int card);

  /// A page size choice: "25 / page".
  String perPage(int size);

  // ── selection bar ──

  /// Clears the selection; short, beside the count.
  String get clear;

  /// Every one of the [total] rows a query matches is selected.
  String allSelected(int total);

  /// [selection], an app's own "{total} selected" label such as "137
  /// products selected", said of every row the query matches.
  String allOf(int total, String selection);

  /// Selects every one of the [total] rows the query matches.
  String selectAllCount(int total);

  // ── filters ──

  /// A yes/no filter's yes.
  String get yes;

  /// A yes/no filter's no.
  String get no;

  /// A date range bound left open.
  String get any;

  /// The label of a date range's first day.
  String get from;

  /// The label of a date range's last day.
  String get to;

  /// The placeholder of a number range's lower bound.
  String get min;

  /// The placeholder of a number range's upper bound.
  String get max;

  /// Clears every filter.
  String get clearAll;

  /// The placeholder of a text filter.
  String get containsPlaceholder;

  /// The accessible name of the × that clears [field]'s filter.
  String clearFilter(String field);

  /// What a filter pill puts between its field and its value.
  String get valueSeparator;

  /// A filter pill as read aloud: [field] and its [value].
  String filterValue(String field, String value);

  /// A number range, either bound of which may be open (null), both
  /// already formatted.
  String numberRange(String? min, String? max);

  /// A date range, either bound of which may be open (null), both
  /// already formatted.
  String dateRange(String? from, String? to);

  /// A typed search term, quoted.
  String quoted(String text);

  /// The chosen [labels] of an options filter, at least one: all of them
  /// up to two, else the first and how many more.
  String optionsSummary(List<String> labels);

  // ── column chooser ──

  /// The column chooser's title and its button.
  String get columns;

  /// The column chooser button's [label] while [hidden] columns are hidden.
  String withHidden(String label, int hidden);

  /// The placeholder of the column chooser's search box.
  String get findColumn;

  /// Shows every listed column.
  String get showAll;

  /// Hides every listed column that can be hidden.
  String get hideAll;

  /// The column chooser's search found nothing.
  String get noMatchingColumns;

  /// The accessible name of the lock on a column that can't be hidden.
  String get locked;

  // ── saved views ──

  /// Moves a view tab one place to the left, as drawn.
  String get moveLeft;

  /// Moves a view tab one place to the right, as drawn.
  String get moveRight;

  /// A view menu entry.
  String get rename;

  /// A view menu entry.
  String get duplicate;

  /// A view menu entry that makes the view open first.
  String get setAsDefault;

  /// The overflow menu of the view tabs.
  String get moreViews;

  /// The accessible name of the + that saves the current query as a view.
  String get saveAsNewView;

  /// The accessible name of the default view's star.
  String get defaultView;

  /// The accessible name of [view]'s menu.
  String viewOptions(String view);

  /// The name of a duplicated view called [name].
  String copyOf(String name);

  /// The saved-views tab that applies no view: every row.
  String get allViews;

  /// The accessible name of the compact saved-views menu, which shows the
  /// active [view].
  String currentView(String view);

  /// The title of the dialog that names a new view.
  String get saveViewTitle;

  /// Under [saveViewTitle]: what a view keeps.
  String get saveViewDescription;

  /// The title of the dialog that renames a view.
  String get renameViewTitle;

  /// The label of a view's name field.
  String get viewName;

  /// The error of a view's name field left empty.
  String get viewNameRequired;

  /// The label of the choice of who sees a view.
  String get viewScope;

  /// A view only its author sees.
  String get personalView;

  /// Under [personalView].
  String get personalViewDescription;

  /// A view the whole team sees.
  String get sharedView;

  /// Under [sharedView].
  String get sharedViewDescription;

  // ── kanban and search ──

  /// An empty kanban column while a card is dragged.
  String get dropHere;

  /// An empty kanban column.
  String get noItems;

  /// The accessible action that moves a card to [column].
  String moveTo(String column);

  /// The accessible name and tooltip of the menu on a kanban card that
  /// moves it to another column.
  String get moveCard;

  /// A search match found in [field], a field's label as the form shows
  /// it, capitalised or not: "Matched: Name".
  String matchedIn(String field);
}

/// English [CollectionMessages]. Subclass it to override a few strings.
class CollectionMessagesEn extends CollectionMessages {
  const CollectionMessagesEn([super.localeName = 'en']);

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get noResultsMessage =>
      'Nothing matches the current search or filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get sortAscending => 'Sort ascending';

  @override
  String get sortDescending => 'Sort descending';

  @override
  String get clearSort => 'Clear sort';

  @override
  String get pinColumn => 'Pin column';

  @override
  String get unpinColumn => 'Unpin column';

  @override
  String get resetWidth => 'Reset width';

  @override
  String get hideColumn => 'Hide column';

  @override
  String get manageColumns => 'Manage columns…';

  @override
  String get columnOptions => 'Column options';

  @override
  String columnOptionsFor(String column) => 'Column options for $column';

  @override
  String notSorted(String column) => '$column, not sorted';

  @override
  String sortedAscending(String column) => '$column, sorted ascending';

  @override
  String sortedDescending(String column) => '$column, sorted descending';

  @override
  String selectRow(int row) => 'Select row ${number(row)}';

  @override
  String get selectAllOnPage => 'Select all on page';

  @override
  String selectCard(int card) => 'Select card ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / page';

  @override
  String get clear => 'Clear';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nothing selected',
    one: '${number(total)} selected',
    other: 'All ${number(total)} selected',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'All $selection');

  @override
  String selectAllCount(int total) => 'Select all ${number(total)}';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get any => 'Any';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get clearAll => 'Clear all';

  @override
  String get containsPlaceholder => 'Contains…';

  @override
  String clearFilter(String field) => 'Clear $field filter';

  @override
  String get valueSeparator => ': ';

  @override
  String filterValue(String field, String value) => '$field: $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'From $from',
    (null, final to?) => 'Until $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '“$text”';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Columns';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)} hidden)';

  @override
  String get findColumn => 'Find a column';

  @override
  String get showAll => 'Show all';

  @override
  String get hideAll => 'Hide all';

  @override
  String get noMatchingColumns => 'No matching columns';

  @override
  String get locked => 'Locked';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get rename => 'Rename';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get moreViews => 'More views';

  @override
  String get saveAsNewView => 'Save current as a new view';

  @override
  String get defaultView => 'Default';

  @override
  String viewOptions(String view) => '$view options';

  @override
  String copyOf(String name) => '$name copy';

  @override
  String get allViews => 'All';

  @override
  String currentView(String view) => 'View: $view';

  @override
  String get saveViewTitle => 'Save view';

  @override
  String get saveViewDescription =>
      'Keeps the current filters and sort one click away.';

  @override
  String get renameViewTitle => 'Rename view';

  @override
  String get viewName => 'Name';

  @override
  String get viewNameRequired => 'Give the view a name.';

  @override
  String get viewScope => 'Who sees it';

  @override
  String get personalView => 'Personal';

  @override
  String get personalViewDescription => 'Only you see it';

  @override
  String get sharedView => 'Shared';

  @override
  String get sharedViewDescription => 'Everyone on the team sees it';

  @override
  String get dropHere => 'Drop here';

  @override
  String get noItems => 'No items';

  @override
  String moveTo(String column) => 'Move to $column';

  @override
  String get moveCard => 'Move to…';

  @override
  String matchedIn(String field) => 'Matched: $field';
}
