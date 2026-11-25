import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// French [InputsMessages].
class InputsMessagesFr extends InputsMessages {
  const InputsMessagesFr([super.localeName = 'fr']);

  @override
  String get confirm => 'Confirmer';

  @override
  String get copied => 'Copié';

  @override
  String get copyFailed => 'Échec de la copie';

  @override
  String get undo => 'Annuler';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get couldNotLoadResults => 'Impossible de charger les résultats';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} sur ${number(count)}';

  @override
  String get dateRange => 'Période';

  @override
  String get clearDates => 'Effacer les dates';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) => plural(
    count,
    one: 'Dernier jour',
    other: '${number(count)} derniers jours',
  );

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get lastMonth => 'Le mois dernier';

  @override
  String get yearToDate => 'Année en cours';

  @override
  String get searchOrJumpTo => 'Rechercher ou aller à…';

  @override
  String get recent => 'Récents';

  @override
  String get selectAResult => 'Sélectionnez un résultat';

  @override
  String matchedIn(String place) => 'Trouvé dans $place';

  @override
  String get matchedInContent => 'Trouvé dans le contenu';

  @override
  String get run => 'Exécuter';

  @override
  String get open => 'Ouvrir';

  @override
  String get typeToSearch => 'Tapez pour rechercher';

  @override
  String noResultsFor(String query) => 'Aucun résultat pour « $query »';

  @override
  String resultCount(int count) => plural(
    count,
    zero: 'Aucun résultat',
    one: '${number(count)} résultat',
    other: '${number(count)} résultats',
  );

  @override
  String get navigateHint => 'naviguer';

  @override
  String get selectHint => 'sélectionner';

  @override
  String get closeHint => 'fermer';

  @override
  String get keysUpDown => 'Flèches haut et bas';

  @override
  String get keyEnter => 'Entrée';

  @override
  String get keyEscape => 'Échap';

  @override
  String get fieldsGroup => 'Champs';

  @override
  String get notifications => 'Notifications';

  @override
  String get allCaughtUp => 'Vous êtes à jour';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  /// A notification is feminine.
  @override
  String get unread => 'Non lue';

  /// Notifications are feminine.
  @override
  String get allNotifications => 'Toutes';

  /// A notification is feminine.
  @override
  String get markAsRead => 'Marquer comme lue';

  /// A notification is feminine.
  @override
  String get markAsUnread => 'Marquer comme non lue';

  @override
  String get viewAll => 'Tout afficher';

  @override
  String get couldNotLoadNotifications =>
      'Impossible de charger les notifications';

  /// The default title, notifications, is feminine.
  @override
  String unreadCount(String title, int count) => plural(
    count,
    one: '$title, ${number(count)} non lue',
    other: '$title, ${number(count)} non lues',
  );

  @override
  String get appearanceTheme => 'Thème';

  @override
  String get appearanceMode => 'Mode';

  @override
  String get modeLight => 'Clair';

  @override
  String get modeDark => 'Sombre';

  @override
  String get modeSystem => 'Système';

  @override
  String get accentColour => 'Couleur d’accent';

  @override
  String get themeAccent => 'Couleur du thème';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Cramoisi',
    'Violet' => 'Violet',
    'Teal' => 'Sarcelle',
    'Amber' => 'Ambre',
    _ => name,
  };

  @override
  String get tableDensity => 'Densité des tableaux';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Compacte',
    TableDensity.standard => 'Standard',
    TableDensity.comfortable => 'Confortable',
  };
}
