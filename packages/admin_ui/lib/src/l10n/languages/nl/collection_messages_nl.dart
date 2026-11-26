import '../../sections/collection_messages.dart';

/// Dutch [CollectionMessages].
class CollectionMessagesNl extends CollectionMessages {
  const CollectionMessagesNl([super.localeName = 'nl']);

  @override
  String get nothingHereYet => 'Nog niets hier';

  @override
  String get noResultsMessage =>
      'Niets komt overeen met de huidige zoekopdracht of filters.';

  @override
  String get clearFilters => 'Filters wissen';

  @override
  String get sortAscending => 'Oplopend sorteren';

  @override
  String get sortDescending => 'Aflopend sorteren';

  @override
  String get clearSort => 'Sortering wissen';

  @override
  String get pinColumn => 'Kolom vastzetten';

  @override
  String get unpinColumn => 'Kolom losmaken';

  @override
  String get resetWidth => 'Breedte resetten';

  @override
  String get hideColumn => 'Kolom verbergen';

  @override
  String get manageColumns => 'Kolommen beheren…';

  @override
  String get columnOptions => 'Kolomopties';

  @override
  String columnOptionsFor(String column) => 'Kolomopties voor $column';

  @override
  String notSorted(String column) => '$column, niet gesorteerd';

  @override
  String sortedAscending(String column) => '$column, oplopend gesorteerd';

  @override
  String sortedDescending(String column) => '$column, aflopend gesorteerd';

  @override
  String selectRow(int row) => 'Rij ${number(row)} selecteren';

  @override
  String get selectAllOnPage => 'Alles op pagina selecteren';

  @override
  String selectCard(int card) => 'Kaart ${number(card)} selecteren';

  @override
  String perPage(int size) => '${number(size)} / pagina';

  @override
  String get clear => 'Wissen';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Niets geselecteerd',
    one: '${number(total)} geselecteerd',
    other: 'Alle ${number(total)} geselecteerd',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Alle $selection');

  @override
  String selectAllCount(int total) => 'Alle ${number(total)} selecteren';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

  @override
  String get any => 'Onbeperkt';

  @override
  String get from => 'Van';

  /// Tot en met: the last day is included.
  @override
  String get to => 'Tot en met';

  @override
  String get min => 'Min.';

  @override
  String get max => 'Max.';

  @override
  String get clearAll => 'Alles wissen';

  @override
  String get containsPlaceholder => 'Bevat…';

  @override
  String clearFilter(String field) => 'Filter voor $field wissen';

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
    (final from?, null) => 'Vanaf $from',
    (null, final to?) => 'Tot en met $to',
    (null, null) => '',
  };

  /// Dutch's single quotation marks.
  @override
  String quoted(String text) => '‘$text’';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Kolommen';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)} verborgen)';

  @override
  String get findColumn => 'Kolom zoeken';

  @override
  String get showAll => 'Alles tonen';

  @override
  String get hideAll => 'Alles verbergen';

  @override
  String get noMatchingColumns => 'Geen overeenkomende kolommen';

  @override
  String get locked => 'Vergrendeld';

  @override
  String get moveLeft => 'Naar links verplaatsen';

  @override
  String get moveRight => 'Naar rechts verplaatsen';

  @override
  String get rename => 'Naam wijzigen';

  @override
  String get duplicate => 'Dupliceren';

  @override
  String get setAsDefault => 'Als standaard instellen';

  @override
  String get moreViews => 'Meer weergaven';

  @override
  String get saveAsNewView => 'Huidige opslaan als nieuwe weergave';

  @override
  String get defaultView => 'Standaard';

  @override
  String viewOptions(String view) => 'Opties voor $view';

  @override
  String copyOf(String name) => '$name (kopie)';

  @override
  String get allViews => 'Alle';

  @override
  String currentView(String view) => 'Weergave: $view';

  @override
  String get saveViewTitle => 'Weergave opslaan';

  @override
  String get saveViewDescription =>
      'Zet de huidige filters en sortering op één klik afstand.';

  @override
  String get renameViewTitle => 'Naam van weergave wijzigen';

  @override
  String get viewName => 'Naam';

  @override
  String get viewNameRequired => 'Geef de weergave een naam.';

  @override
  String get viewScope => 'Zichtbaar voor';

  @override
  String get personalView => 'Persoonlijk';

  @override
  String get personalViewDescription => 'Alleen zichtbaar voor jou';

  @override
  String get sharedView => 'Gedeeld';

  @override
  String get sharedViewDescription => 'Zichtbaar voor iedereen in het team';

  @override
  String get dropHere => 'Hier neerzetten';

  @override
  String get noItems => 'Geen items';

  @override
  String moveTo(String column) => 'Verplaatsen naar $column';

  @override
  String get moveCard => 'Verplaatsen naar…';

  @override
  String matchedIn(String field) => 'Overeenkomst: $field';
}
