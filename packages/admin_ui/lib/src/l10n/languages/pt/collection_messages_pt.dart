import '../../sections/collection_messages.dart';

/// Brazilian Portuguese [CollectionMessages].
class CollectionMessagesPt extends CollectionMessages {
  const CollectionMessagesPt([super.localeName = 'pt']);

  @override
  String get nothingHereYet => 'Nada por aqui ainda';

  @override
  String get noResultsMessage =>
      'Nada corresponde à pesquisa ou aos filtros atuais.';

  @override
  String get clearFilters => 'Limpar filtros';

  @override
  String get sortAscending => 'Ordem crescente';

  @override
  String get sortDescending => 'Ordem decrescente';

  @override
  String get clearSort => 'Limpar ordenação';

  @override
  String get pinColumn => 'Fixar coluna';

  @override
  String get unpinColumn => 'Desafixar coluna';

  @override
  String get resetWidth => 'Redefinir largura';

  @override
  String get hideColumn => 'Ocultar coluna';

  @override
  String get manageColumns => 'Gerenciar colunas…';

  @override
  String get columnOptions => 'Opções da coluna';

  @override
  String columnOptionsFor(String column) => 'Opções da coluna $column';

  @override
  String notSorted(String column) => '$column, sem ordenação';

  @override
  String sortedAscending(String column) => '$column, em ordem crescente';

  @override
  String sortedDescending(String column) => '$column, em ordem decrescente';

  @override
  String selectRow(int row) => 'Selecionar linha ${number(row)}';

  @override
  String get selectAllOnPage => 'Selecionar tudo na página';

  @override
  String selectCard(int card) => 'Selecionar cartão ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} por página';

  @override
  String get clear => 'Limpar';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Nada selecionado',
    one: '${number(total)} selecionado',
    other: 'Todos os ${number(total)} selecionados',
  );

  /// The label agrees with the noun of the app, so Todos stands before a
  /// colon rather than in front of that noun.
  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Todos os resultados: $selection');

  @override
  String selectAllCount(int total) => 'Selecionar tudo (${number(total)})';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get any => 'Qualquer data';

  @override
  String get from => 'De';

  @override
  String get to => 'Até';

  @override
  String get min => 'Mín.';

  @override
  String get max => 'Máx.';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get containsPlaceholder => 'Contém…';

  @override
  String clearFilter(String field) => 'Limpar filtro de $field';

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
    (final from?, null) => 'A partir de $from',
    (null, final to?) => 'Até $to',
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
  String get columns => 'Colunas';

  /// A column is feminine.
  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} oculta)',
    other: '$label (${number(hidden)} ocultas)',
  );

  @override
  String get findColumn => 'Pesquisar coluna';

  /// Columns are feminine.
  @override
  String get showAll => 'Mostrar todas';

  /// Columns are feminine.
  @override
  String get hideAll => 'Ocultar todas';

  @override
  String get noMatchingColumns => 'Nenhuma coluna correspondente';

  /// A column is feminine.
  @override
  String get locked => 'Bloqueada';

  @override
  String get moveLeft => 'Mover para a esquerda';

  @override
  String get moveRight => 'Mover para a direita';

  @override
  String get rename => 'Renomear';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get setAsDefault => 'Definir como padrão';

  @override
  String get moreViews => 'Mais visualizações';

  @override
  String get saveAsNewView => 'Salvar como nova visualização';

  @override
  String get defaultView => 'Padrão';

  @override
  String viewOptions(String view) => 'Opções da visualização $view';

  @override
  String copyOf(String name) => '$name (cópia)';

  @override
  String get allViews => 'Todos';

  @override
  String currentView(String view) => 'Visualização: $view';

  @override
  String get saveViewTitle => 'Salvar visualização';

  @override
  String get saveViewDescription =>
      'Mantém os filtros e a ordenação atuais a um clique de distância.';

  @override
  String get renameViewTitle => 'Renomear visualização';

  @override
  String get viewName => 'Nome';

  @override
  String get viewNameRequired => 'Dê um nome à visualização.';

  @override
  String get viewScope => 'Quem pode ver';

  /// A view is feminine.
  @override
  String get personalView => 'Pessoal';

  @override
  String get personalViewDescription => 'Só você pode ver';

  /// A view is feminine.
  @override
  String get sharedView => 'Compartilhada';

  @override
  String get sharedViewDescription => 'Toda a equipe pode ver';

  @override
  String get dropHere => 'Solte aqui';

  @override
  String get noItems => 'Nenhum item';

  @override
  String moveTo(String column) => 'Mover para $column';

  @override
  String get moveCard => 'Mover para…';

  @override
  String matchedIn(String field) => 'Encontrado em: $field';
}
