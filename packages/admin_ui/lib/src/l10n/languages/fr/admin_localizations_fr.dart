import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_fr.dart';
import 'collection_messages_fr.dart';
import 'display_messages_fr.dart';
import 'fields_messages_fr.dart';
import 'inputs_messages_fr.dart';
import 'shell_messages_fr.dart';

/// French [AdminLocalizations].
class AdminLocalizationsFr extends AdminLocalizations {
  const AdminLocalizationsFr([super.localeName = 'fr']);

  @override
  InputsMessages get inputs => const InputsMessagesFr();

  @override
  DisplayMessages get display => const DisplayMessagesFr();

  @override
  CollectionMessages get collection => const CollectionMessagesFr();

  @override
  FieldsMessages get fields => const FieldsMessagesFr();

  @override
  ShellMessages get shell => const ShellMessagesFr();

  @override
  AssetsMessages get assets => const AssetsMessagesFr();

  @override
  String get apply => 'Appliquer';

  @override
  String get retry => 'Réessayer';

  @override
  String get remove => 'Retirer';

  @override
  String removeItem(String name) => 'Retirer $name';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get loading => 'Chargement…';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get edited => 'Modifié';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noMatches => 'Aucune correspondance';

  @override
  String get couldNotLoad => 'Chargement impossible';

  @override
  String get searchFailed => 'Échec de la recherche';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get searching => 'Recherche…';

  @override
  String get somethingWentWrong => 'Une erreur s’est produite';

  @override
  String get somethingWentWrongTryAgain =>
      'Une erreur s’est produite. Réessayez.';

  @override
  String get notAllowed => 'Vous n’avez pas accès à ceci';

  @override
  String get notAllowedAskAdministrator =>
      'Demandez-le à un administrateur si vous en avez besoin.';

  @override
  String get goBack => 'Retour';

  @override
  String get moreActions => 'Plus d’actions';

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get moveUp => 'Déplacer vers le haut';

  @override
  String get moveDown => 'Déplacer vers le bas';

  @override
  String get selectPlaceholder => 'Sélectionner…';

  @override
  String get filterPlaceholder => 'Filtrer…';

  @override
  String get searchPlaceholder => 'Rechercher…';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get addRow => 'Ajouter une ligne';

  @override
  String get keyLabel => 'Clé';

  @override
  String get valueLabel => 'Valeur';

  @override
  String get linkPlaceholder => 'Lier…';

  @override
  String get restoreLiveVersion => 'Rétablir la version en ligne de ce champ';

  @override
  String get assetNotFound => 'Média introuvable';

  @override
  String get assetPreview => 'Aperçu du média';

  @override
  String get uploadFailed => 'Échec de l’envoi';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Glissez-déposez un fichier ou ',
      (false, true) => 'Glissez-déposez des fichiers ou ',
      (true, false) => 'Glissez-déposez une image ou ',
      (true, true) => 'Glissez-déposez des images ou ',
    },
    link: 'parcourez',
    after: '',
  );

  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Aucune sélection',
    one: '${number(count)} sélectionné',
    other: '${number(count)} sélectionnés',
  );

  @override
  String countOf(int count, int total) =>
      '${number(count)} sur ${number(total)}';

  /// French writes octets, with a no-break space before the unit.
  @override
  String byteSize(String amount, int power) =>
      '$amount\u00A0${const ['o', 'ko', 'Mo', 'Go', 'To'][power]}';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get copy => 'Copier';

  @override
  String get close => 'Fermer';

  @override
  String get clear => 'Effacer le texte';

  @override
  String get search => 'Rechercher';

  @override
  String get more => 'Plus';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get rowsPerPage => 'Lignes par page :';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first – $last sur $total';

  @override
  String get previousPage => 'Page précédente';

  @override
  String get nextPage => 'Page suivante';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String rangeStartDate(String date) => 'Date de début : $date';

  @override
  String rangeEndDate(String date) => 'Date de fin : $date';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get selectDateRange => 'Sélectionner une plage';

  @override
  String get navigationMenu => 'Menu de navigation';

  @override
  String get expand => 'Développer';

  @override
  String get collapse => 'Réduire';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Maj';

  @override
  String get keyboardKeyMeta => 'Méta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Retour arrière';

  @override
  String get keyboardKeyDelete => 'Suppr';

  @override
  String get keyboardKeyEnd => 'Fin';

  @override
  String get keyboardKeyEscape => 'Échap';

  @override
  String get keyboardKeyHome => 'Accueil';

  @override
  String get keyboardKeyInsert => 'Insérer';

  @override
  String get keyboardKeyPageDown => 'PgSuiv';

  @override
  String get keyboardKeyPageUp => 'PgPréc';

  @override
  String get keyboardKeySpace => 'Espace';

  @override
  String get keyboardKeyCapsLock => 'Verr Maj';

  @override
  String get keyboardKeyPrintScreen => 'Impr. écran';

  @override
  String get keyboardKeyScrollLock => 'Arrêt défil';

  @override
  String get keyboardKeyNumLock => 'Verr Num';

  @override
  String get keyboardKeyFn => 'Fn';
}
