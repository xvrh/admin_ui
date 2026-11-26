import '../../sections/collection_messages.dart';

/// Polish [CollectionMessages].
class CollectionMessagesPl extends CollectionMessages {
  const CollectionMessagesPl([super.localeName = 'pl']);

  @override
  String get nothingHereYet => 'Nic tu jeszcze nie ma';

  @override
  String get noResultsMessage =>
      'Nic nie pasuje do bieżącego wyszukiwania lub filtrów.';

  @override
  String get clearFilters => 'Wyczyść filtry';

  @override
  String get sortAscending => 'Sortuj rosnąco';

  @override
  String get sortDescending => 'Sortuj malejąco';

  @override
  String get clearSort => 'Wyczyść sortowanie';

  @override
  String get pinColumn => 'Przypnij kolumnę';

  @override
  String get unpinColumn => 'Odepnij kolumnę';

  @override
  String get resetWidth => 'Resetuj szerokość';

  @override
  String get hideColumn => 'Ukryj kolumnę';

  @override
  String get manageColumns => 'Zarządzaj kolumnami…';

  @override
  String get columnOptions => 'Opcje kolumny';

  @override
  String columnOptionsFor(String column) => 'Opcje kolumny $column';

  /// A column is feminine.
  @override
  String notSorted(String column) => '$column, nieposortowana';

  @override
  String sortedAscending(String column) => '$column, sortowanie rosnące';

  @override
  String sortedDescending(String column) => '$column, sortowanie malejące';

  @override
  String selectRow(int row) => 'Zaznacz wiersz ${number(row)}';

  @override
  String get selectAllOnPage => 'Zaznacz wszystko na stronie';

  @override
  String selectCard(int card) => 'Zaznacz kartę ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} na stronę';

  @override
  String get clear => 'Wyczyść';

  /// Impersonal, so the count agrees with no noun.
  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nic nie zaznaczono',
    one: 'Zaznaczono: ${number(total)}',
    other: 'Zaznaczono wszystkie: ${number(total)}',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Wszystkie wyniki: $selection');

  @override
  String selectAllCount(int total) => 'Zaznacz wszystkie (${number(total)})';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  /// A date is feminine.
  @override
  String get any => 'Dowolna';

  @override
  String get from => 'Od';

  @override
  String get to => 'Do';

  @override
  String get min => 'Od';

  @override
  String get max => 'Do';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get containsPlaceholder => 'Zawiera…';

  @override
  String clearFilter(String field) => 'Wyczyść filtr $field';

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
    (final from?, null) => 'Od $from',
    (null, final to?) => 'Do $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '„$text”';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Kolumny';

  /// A column is feminine.
  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} ukryta)',
    few: '$label (${number(hidden)} ukryte)',
    many: '$label (${number(hidden)} ukrytych)',
    other: '$label (${number(hidden)} ukrytej)',
  );

  @override
  String get findColumn => 'Znajdź kolumnę';

  @override
  String get showAll => 'Pokaż wszystkie';

  @override
  String get hideAll => 'Ukryj wszystkie';

  @override
  String get noMatchingColumns => 'Brak pasujących kolumn';

  @override
  String get locked => 'Zablokowana';

  @override
  String get moveLeft => 'Przenieś w lewo';

  @override
  String get moveRight => 'Przenieś w prawo';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get duplicate => 'Duplikuj';

  /// A view is masculine.
  @override
  String get setAsDefault => 'Ustaw jako domyślny';

  @override
  String get moreViews => 'Więcej widoków';

  @override
  String get saveAsNewView => 'Zapisz jako nowy widok';

  @override
  String get defaultView => 'Domyślny';

  @override
  String viewOptions(String view) => 'Opcje widoku $view';

  @override
  String copyOf(String name) => '$name (kopia)';

  @override
  String get allViews => 'Wszystkie';

  @override
  String currentView(String view) => 'Widok: $view';

  @override
  String get saveViewTitle => 'Zapisz widok';

  @override
  String get saveViewDescription =>
      'Bieżące filtry i sortowanie będą dostępne jednym kliknięciem.';

  @override
  String get renameViewTitle => 'Zmień nazwę widoku';

  @override
  String get viewName => 'Nazwa';

  @override
  String get viewNameRequired => 'Podaj nazwę widoku.';

  @override
  String get viewScope => 'Widoczność';

  @override
  String get personalView => 'Osobisty';

  @override
  String get personalViewDescription => 'Widoczny tylko dla autora';

  @override
  String get sharedView => 'Udostępniony';

  @override
  String get sharedViewDescription => 'Widoczny dla całego zespołu';

  @override
  String get dropHere => 'Upuść tutaj';

  @override
  String get noItems => 'Brak elementów';

  @override
  String moveTo(String column) => 'Przenieś do kolumny $column';

  @override
  String get moveCard => 'Przenieś do…';

  @override
  String matchedIn(String field) => 'Znaleziono w: $field';
}
