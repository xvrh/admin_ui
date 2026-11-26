import '../../sections/collection_messages.dart';

/// German [CollectionMessages].
class CollectionMessagesDe extends CollectionMessages {
  const CollectionMessagesDe([super.localeName = 'de']);

  @override
  String get nothingHereYet => 'Noch nichts vorhanden';

  @override
  String get noResultsMessage =>
      'Für die aktuelle Suche oder die aktiven Filter gibt es keine Treffer.';

  @override
  String get clearFilters => 'Filter zurücksetzen';

  @override
  String get sortAscending => 'Aufsteigend sortieren';

  @override
  String get sortDescending => 'Absteigend sortieren';

  @override
  String get clearSort => 'Sortierung aufheben';

  @override
  String get pinColumn => 'Spalte fixieren';

  @override
  String get unpinColumn => 'Fixierung aufheben';

  @override
  String get resetWidth => 'Breite zurücksetzen';

  @override
  String get hideColumn => 'Spalte ausblenden';

  @override
  String get manageColumns => 'Spalten verwalten…';

  @override
  String get columnOptions => 'Spaltenoptionen';

  @override
  String columnOptionsFor(String column) => 'Spaltenoptionen für $column';

  @override
  String notSorted(String column) => '$column, nicht sortiert';

  @override
  String sortedAscending(String column) => '$column, aufsteigend sortiert';

  @override
  String sortedDescending(String column) => '$column, absteigend sortiert';

  @override
  String selectRow(int row) => 'Zeile ${number(row)} auswählen';

  @override
  String get selectAllOnPage => 'Alle auf dieser Seite auswählen';

  @override
  String selectCard(int card) => 'Karte ${number(card)} auswählen';

  @override
  String perPage(int size) => '${number(size)} pro Seite';

  /// Clears the selection: „Löschen“ would read as deleting the rows.
  @override
  String get clear => 'Aufheben';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nichts ausgewählt',
    one: '${number(total)} ausgewählt',
    other: 'Alle ${number(total)} ausgewählt',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Alle $selection');

  @override
  String selectAllCount(int total) => 'Alle ${number(total)} auswählen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get any => 'Beliebig';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get min => 'Min.';

  @override
  String get max => 'Max.';

  @override
  String get clearAll => 'Alle entfernen';

  @override
  String get containsPlaceholder => 'Enthält…';

  @override
  String clearFilter(String field) => 'Filter „$field“ entfernen';

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
    (final from?, null) => 'Ab $from',
    (null, final to?) => 'Bis $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '„$text“';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Spalten';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)} ausgeblendet)';

  @override
  String get findColumn => 'Spalte suchen';

  @override
  String get showAll => 'Alle einblenden';

  @override
  String get hideAll => 'Alle ausblenden';

  @override
  String get noMatchingColumns => 'Keine passenden Spalten';

  @override
  String get locked => 'Gesperrt';

  @override
  String get moveLeft => 'Nach links verschieben';

  @override
  String get moveRight => 'Nach rechts verschieben';

  @override
  String get rename => 'Umbenennen';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get setAsDefault => 'Als Standard festlegen';

  @override
  String get moreViews => 'Weitere Ansichten';

  @override
  String get saveAsNewView => 'Als neue Ansicht speichern';

  @override
  String get defaultView => 'Standard';

  @override
  String viewOptions(String view) => 'Ansichtsoptionen für $view';

  @override
  String copyOf(String name) => '$name (Kopie)';

  @override
  String get allViews => 'Alle';

  @override
  String currentView(String view) => 'Ansicht: $view';

  @override
  String get saveViewTitle => 'Ansicht speichern';

  @override
  String get saveViewDescription =>
      'Hält die aktuellen Filter und die Sortierung mit einem Klick bereit.';

  @override
  String get renameViewTitle => 'Ansicht umbenennen';

  @override
  String get viewName => 'Name';

  @override
  String get viewNameRequired => 'Namen für die Ansicht eingeben.';

  @override
  String get viewScope => 'Sichtbar für';

  @override
  String get personalView => 'Persönlich';

  @override
  String get personalViewDescription => 'Nur für Sie sichtbar';

  @override
  String get sharedView => 'Geteilt';

  @override
  String get sharedViewDescription => 'Für das ganze Team sichtbar';

  @override
  String get dropHere => 'Hier ablegen';

  @override
  String get noItems => 'Keine Elemente';

  @override
  String moveTo(String column) => 'Nach $column verschieben';

  @override
  String get moveCard => 'Verschieben nach…';

  @override
  String matchedIn(String field) => 'Treffer: $field';
}
