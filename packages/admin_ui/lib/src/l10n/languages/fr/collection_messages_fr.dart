import '../../sections/collection_messages.dart';

/// French [CollectionMessages].
class CollectionMessagesFr extends CollectionMessages {
  const CollectionMessagesFr([super.localeName = 'fr']);

  @override
  String get nothingHereYet => 'Rien pour l’instant';

  @override
  String get noResultsMessage =>
      'Rien ne correspond à la recherche ou aux filtres actuels.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get sortAscending => 'Tri croissant';

  @override
  String get sortDescending => 'Tri décroissant';

  @override
  String get clearSort => 'Annuler le tri';

  @override
  String get pinColumn => 'Épingler la colonne';

  @override
  String get unpinColumn => 'Détacher la colonne';

  @override
  String get resetWidth => 'Rétablir la largeur';

  @override
  String get hideColumn => 'Masquer la colonne';

  @override
  String get manageColumns => 'Gérer les colonnes…';

  @override
  String get columnOptions => 'Options de colonne';

  @override
  String columnOptionsFor(String column) => 'Options de la colonne $column';

  @override
  String notSorted(String column) => '$column, non trié';

  @override
  String sortedAscending(String column) => '$column, tri croissant';

  @override
  String sortedDescending(String column) => '$column, tri décroissant';

  @override
  String selectRow(int row) => 'Sélectionner la ligne ${number(row)}';

  @override
  String get selectAllOnPage => 'Tout sélectionner sur la page';

  @override
  String selectCard(int card) => 'Sélectionner la carte ${number(card)}';

  @override
  String perPage(int size) => '${number(size)} / page';

  @override
  String get clear => 'Effacer';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Aucune sélection',
    one: '${number(total)} sélectionné',
    other: 'Les ${number(total)} sont sélectionnés',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Tous les résultats : $selection');

  @override
  String selectAllCount(int total) => 'Tout sélectionner (${number(total)})';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get any => 'Indifférent';

  @override
  String get from => 'Début';

  @override
  String get to => 'Fin';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get containsPlaceholder => 'Contient…';

  @override
  String clearFilter(String field) => 'Effacer le filtre $field';

  /// French sets a no-break space before the colon.
  @override
  String get valueSeparator => ' : ';

  @override
  String filterValue(String field, String value) => '$field : $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => 'À partir du $from',
    (null, final to?) => 'Jusqu’au $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '« $text »';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Colonnes';

  @override
  String withHidden(String label, int hidden) => plural(
    hidden,
    one: '$label (${number(hidden)} masquée)',
    other: '$label (${number(hidden)} masquées)',
  );

  @override
  String get findColumn => 'Rechercher une colonne';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get hideAll => 'Tout masquer';

  @override
  String get noMatchingColumns => 'Aucune colonne correspondante';

  @override
  String get locked => 'Verrouillée';

  @override
  String get moveLeft => 'Déplacer vers la gauche';

  @override
  String get moveRight => 'Déplacer vers la droite';

  @override
  String get rename => 'Renommer';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get setAsDefault => 'Définir par défaut';

  @override
  String get moreViews => 'Plus de vues';

  @override
  String get saveAsNewView => 'Enregistrer comme nouvelle vue';

  @override
  String get defaultView => 'Par défaut';

  @override
  String viewOptions(String view) => 'Options de la vue $view';

  @override
  String copyOf(String name) => '$name (copie)';

  @override
  String get allViews => 'Tout';

  @override
  String currentView(String view) => 'Vue : $view';

  @override
  String get saveViewTitle => 'Enregistrer la vue';

  @override
  String get saveViewDescription =>
      'Garde les filtres et le tri actuels à un clic.';

  @override
  String get renameViewTitle => 'Renommer la vue';

  @override
  String get viewName => 'Nom';

  @override
  String get viewNameRequired => 'Donnez un nom à la vue.';

  @override
  String get viewScope => 'Qui la voit';

  @override
  String get personalView => 'Personnelle';

  @override
  String get personalViewDescription => 'Vous seul la voyez';

  @override
  String get sharedView => 'Partagée';

  @override
  String get sharedViewDescription => 'Toute l’équipe la voit';

  @override
  String get dropHere => 'Déposer ici';

  @override
  String get noItems => 'Aucun élément';

  @override
  String moveTo(String column) => 'Déplacer vers $column';

  @override
  String get moveCard => 'Déplacer vers…';

  @override
  String matchedIn(String field) => 'Correspondance : $field';
}
