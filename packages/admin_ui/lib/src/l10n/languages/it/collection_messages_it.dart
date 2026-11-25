import '../../sections/collection_messages.dart';

/// Italian [CollectionMessages].
class CollectionMessagesIt extends CollectionMessages {
  const CollectionMessagesIt([super.localeName = 'it']);

  @override
  String get nothingHereYet => 'Non c’è ancora nulla';

  @override
  String get noResultsMessage =>
      'Nessun elemento corrisponde alla ricerca o ai filtri attuali.';

  @override
  String get clearFilters => 'Cancella filtri';

  @override
  String get sortAscending => 'Ordine crescente';

  @override
  String get sortDescending => 'Ordine decrescente';

  @override
  String get clearSort => 'Rimuovi ordinamento';

  @override
  String get pinColumn => 'Fissa colonna';

  @override
  String get unpinColumn => 'Sgancia colonna';

  @override
  String get resetWidth => 'Reimposta larghezza';

  @override
  String get hideColumn => 'Nascondi colonna';

  @override
  String get manageColumns => 'Gestisci colonne…';

  @override
  String get columnOptions => 'Opzioni colonna';

  @override
  String columnOptionsFor(String column) => 'Opzioni della colonna $column';

  /// A column is feminine.
  @override
  String notSorted(String column) => '$column, non ordinata';

  @override
  String sortedAscending(String column) => '$column, ordine crescente';

  @override
  String sortedDescending(String column) => '$column, ordine decrescente';

  @override
  String selectRow(int row) => 'Seleziona riga ${number(row)}';

  @override
  String get selectAllOnPage => 'Seleziona tutto nella pagina';

  @override
  String selectCard(int card) => 'Seleziona scheda ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} per pagina';

  @override
  String get clear => 'Deseleziona';

  /// "Tutti e", as Italian writes before a number with no noun after it.
  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nessuna selezione',
    one: '${number(total)} selezionato',
    other: 'Tutti e ${number(total)} selezionati',
  );

  /// "Tutti" cannot go before [selection], whose number would need an
  /// article of its own.
  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Tutti i risultati: $selection');

  @override
  String selectAllCount(int total) => 'Seleziona tutti (${number(total)})';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get any => 'Qualsiasi';

  @override
  String get from => 'Dal';

  @override
  String get to => 'Al';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get containsPlaceholder => 'Contiene…';

  @override
  String clearFilter(String field) => 'Cancella filtro $field';

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

  /// "Da" and "Fino a" without an article, which a date such as 8 June
  /// would elide.
  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'Da $from',
    (null, final to?) => 'Fino a $to',
    (null, null) => '',
  };

  /// Caporali, with no space inside.
  @override
  String quoted(String text) => '«$text»';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Colonne';

  /// A column is feminine.
  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} nascosta)',
    other: '$label (${number(hidden)} nascoste)',
  );

  @override
  String get findColumn => 'Trova una colonna';

  /// Columns are feminine.
  @override
  String get showAll => 'Mostra tutte';

  /// Columns are feminine.
  @override
  String get hideAll => 'Nascondi tutte';

  @override
  String get noMatchingColumns => 'Nessuna colonna corrispondente';

  /// A column is feminine.
  @override
  String get locked => 'Bloccata';

  @override
  String get moveLeft => 'Sposta a sinistra';

  @override
  String get moveRight => 'Sposta a destra';

  @override
  String get rename => 'Rinomina';

  @override
  String get duplicate => 'Duplica';

  /// A view is feminine.
  @override
  String get setAsDefault => 'Imposta come predefinita';

  @override
  String get moreViews => 'Altre viste';

  @override
  String get saveAsNewView => 'Salva come nuova vista';

  /// A view is feminine.
  @override
  String get defaultView => 'Predefinita';

  @override
  String viewOptions(String view) => 'Opzioni della vista $view';

  @override
  String copyOf(String name) => 'Copia di $name';

  /// Every row: the items, masculine.
  @override
  String get allViews => 'Tutti';

  @override
  String currentView(String view) => 'Vista: $view';

  @override
  String get saveViewTitle => 'Salva vista';

  @override
  String get saveViewDescription =>
      'Tiene a portata di clic i filtri e l’ordinamento attuali.';

  @override
  String get renameViewTitle => 'Rinomina vista';

  @override
  String get viewName => 'Nome';

  @override
  String get viewNameRequired => 'Assegna un nome alla vista.';

  @override
  String get viewScope => 'Chi può vederla';

  @override
  String get personalView => 'Personale';

  @override
  String get personalViewDescription => 'Solo tu puoi vederla';

  /// A view is feminine.
  @override
  String get sharedView => 'Condivisa';

  @override
  String get sharedViewDescription => 'Tutto il team può vederla';

  @override
  String get dropHere => 'Rilascia qui';

  @override
  String get noItems => 'Nessun elemento';

  @override
  String moveTo(String column) => 'Sposta in $column';

  @override
  String get moveCard => 'Sposta in…';

  @override
  String matchedIn(String field) => 'Corrispondenza: $field';
}
