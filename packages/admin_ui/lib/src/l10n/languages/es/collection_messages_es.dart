import '../../sections/collection_messages.dart';

/// Spanish [CollectionMessages].
class CollectionMessagesEs extends CollectionMessages {
  const CollectionMessagesEs([super.localeName = 'es']);

  @override
  String get nothingHereYet => 'Aún no hay nada aquí';

  @override
  String get noResultsMessage =>
      'Nada coincide con la búsqueda o los filtros actuales.';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String get sortAscending => 'Orden ascendente';

  @override
  String get sortDescending => 'Orden descendente';

  @override
  String get clearSort => 'Quitar orden';

  @override
  String get pinColumn => 'Fijar columna';

  @override
  String get unpinColumn => 'Dejar de fijar columna';

  @override
  String get resetWidth => 'Restablecer ancho';

  @override
  String get hideColumn => 'Ocultar columna';

  @override
  String get manageColumns => 'Administrar columnas…';

  @override
  String get columnOptions => 'Opciones de columna';

  @override
  String columnOptionsFor(String column) => 'Opciones de la columna $column';

  @override
  String notSorted(String column) => '$column, sin ordenar';

  @override
  String sortedAscending(String column) => '$column, orden ascendente';

  @override
  String sortedDescending(String column) => '$column, orden descendente';

  @override
  String selectRow(int row) => 'Seleccionar fila ${number(row)}';

  @override
  String get selectAllOnPage => 'Seleccionar todo en la página';

  @override
  String selectCard(int card) => 'Seleccionar tarjeta ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / página';

  @override
  String get clear => 'Borrar';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Ningún elemento seleccionado',
    one: '${number(total)} seleccionado',
    other: 'Los ${number(total)} están seleccionados',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Todos los resultados: $selection');

  @override
  String selectAllCount(int total) => 'Seleccionar todo (${number(total)})';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get any => 'Cualquiera';

  @override
  String get from => 'Desde';

  @override
  String get to => 'Hasta';

  @override
  String get min => 'Mín.';

  @override
  String get max => 'Máx.';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get containsPlaceholder => 'Contiene…';

  @override
  String clearFilter(String field) => 'Borrar el filtro de $field';

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
    (final from?, null) => 'Desde el $from',
    (null, final to?) => 'Hasta el $to',
    (null, null) => '',
  };

  /// Comillas angulares, with no space inside.
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
  String get columns => 'Columnas';

  /// A column is feminine.
  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} oculta)',
    other: '$label (${number(hidden)} ocultas)',
  );

  @override
  String get findColumn => 'Buscar columna';

  @override
  String get showAll => 'Mostrar todas';

  @override
  String get hideAll => 'Ocultar todas';

  @override
  String get noMatchingColumns => 'Ninguna columna coincide';

  @override
  String get locked => 'Bloqueada';

  @override
  String get moveLeft => 'Mover a la izquierda';

  @override
  String get moveRight => 'Mover a la derecha';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get duplicate => 'Duplicar';

  /// A view is feminine.
  @override
  String get setAsDefault => 'Establecer como predeterminada';

  @override
  String get moreViews => 'Más vistas';

  @override
  String get saveAsNewView => 'Guardar como nueva vista';

  @override
  String get defaultView => 'Predeterminada';

  @override
  String viewOptions(String view) => 'Opciones de la vista $view';

  @override
  String copyOf(String name) => 'Copia de $name';

  @override
  String get allViews => 'Todos';

  @override
  String currentView(String view) => 'Vista: $view';

  @override
  String get saveViewTitle => 'Guardar vista';

  @override
  String get saveViewDescription =>
      'Guarda los filtros y el orden actuales para tenerlos a un clic.';

  @override
  String get renameViewTitle => 'Cambiar nombre de la vista';

  @override
  String get viewName => 'Nombre';

  @override
  String get viewNameRequired => 'Asigna un nombre a la vista.';

  @override
  String get viewScope => 'Quién la ve';

  @override
  String get personalView => 'Personal';

  @override
  String get personalViewDescription => 'Solo tú la ves';

  @override
  String get sharedView => 'Compartida';

  @override
  String get sharedViewDescription => 'Todo el equipo la ve';

  @override
  String get dropHere => 'Suelta aquí';

  @override
  String get noItems => 'Sin elementos';

  @override
  String moveTo(String column) => 'Mover a $column';

  @override
  String get moveCard => 'Mover a…';

  @override
  String matchedIn(String field) => 'Coincidencia: $field';
}
