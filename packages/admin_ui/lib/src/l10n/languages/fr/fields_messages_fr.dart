import '../../sections/fields_messages.dart';

/// French [FieldsMessages].
class FieldsMessagesFr extends FieldsMessages {
  const FieldsMessagesFr([super.localeName = 'fr']);

  /// Guillemets, with a no-break space inside each.
  @override
  String quoted(String text) => '« $text »';

  @override
  String get filterOrAdd => 'Filtrer ou ajouter…';

  @override
  String maxSelected(int max) => 'Limite de ${number(max)} atteinte';

  @override
  String createOption(String value) => 'Créer ${quoted(value)}';

  @override
  String get onLabel => 'Activé';

  @override
  String get offLabel => 'Désactivé';

  @override
  String get selectDate => 'Choisir une date…';

  @override
  String get selectDateTime => 'Choisir une date et une heure…';

  @override
  String get selectTime => 'Choisir une heure…';

  @override
  String get clearDate => 'Effacer la date';

  @override
  String get year => 'Année';

  @override
  String get month => 'Mois';

  @override
  String get day => 'Jour';

  @override
  String get hour => 'Heure';

  @override
  String get minute => 'Minute';

  /// Jour, mois, année, heure, minute.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'AAAA', month: 'MM', day: 'JJ', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) => 'Saisissez un nombre comme $example';

  @override
  String numberBetween(String min, String max) =>
      'Saisissez un nombre entre $min et $max';

  @override
  String numberAtLeast(String min) => 'Saisissez $min ou plus';

  @override
  String numberAtMost(String max) => 'Saisissez $max ou moins';

  @override
  String get decrease => 'Diminuer';

  @override
  String get increase => 'Augmenter';

  @override
  String get pickColor => 'Choisir une couleur…';

  @override
  String get hexDigitsError => 'Saisissez 3 ou 6 chiffres hexadécimaux';

  @override
  String get setColor => 'Définir';

  @override
  String get validJson => 'JSON valide';

  @override
  String jsonError(int line, int column, String detail) =>
      'Ligne ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formater';

  @override
  String get plainText => 'Texte brut';

  @override
  String get addTag => 'Ajouter une étiquette…';

  @override
  String get noTags => 'Aucune étiquette';

  @override
  String get noEntries => 'Aucune entrée';

  @override
  String duplicateKey(String key) =>
      'Clé ${quoted(key)} en double : la dernière ligne l’emporte';

  @override
  String get duplicateKeys => 'Clés en double : la dernière ligne l’emporte';

  @override
  String get removeRow => 'Retirer la ligne';

  @override
  String get noMedia => 'Aucun média';

  @override
  String retryItem(String name) => 'Réessayer $name';

  @override
  String cancelUpload(String name) => 'Annuler l’envoi de $name';

  @override
  String get cover => 'Couverture';

  @override
  String get processing => 'Traitement…';

  @override
  String get addImage => 'Ajouter une image';

  @override
  String get addFile => 'Ajouter un fichier';

  @override
  String get noReference => 'Aucune référence';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get replaceReference => 'Remplacer';

  @override
  String get typeToSearch => 'Tapez pour rechercher…';

  @override
  String removeItemAt(int position) => 'Retirer l’élément ${number(position)}';

  @override
  String get noItemsYet => 'Aucun élément pour l’instant.';

  @override
  String get help => 'Aide';

  @override
  String helpFor(String field) => 'Aide : $field';

  @override
  String get versionHistory => 'Historique des versions';

  @override
  String get pendingEdit => 'Modification en attente';

  @override
  String get baseline => 'En ligne';

  @override
  String editedDetail(String detail) => 'Modifié · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Commentaires',
    one: '${number(count)} commentaire',
    other: '${number(count)} commentaires',
  );

  @override
  String commentsHeading(int count) => 'Commentaires · ${number(count)}';

  @override
  String get resolve => 'Résoudre';

  @override
  String get replyPlaceholder => 'Répondre…';

  @override
  String get sendReply => 'Envoyer la réponse';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Commenter ce champ',
    one: '${number(openThreads)} discussion ouverte',
    other: '${number(openThreads)} discussions ouvertes',
  );

  @override
  String get openThread => 'Ouvrir la discussion';

  @override
  String get translationSource => 'Source';

  @override
  String get translationUpToDate => 'À jour';

  @override
  String get translationNeedsReview => 'À relire';

  @override
  String get translationOutdated => 'Obsolète';

  @override
  String get translationMissing => 'Manquante';

  @override
  String get retranslate => 'Retraduire';

  @override
  String retranslateLanguage(String language) => 'Retraduire en $language';

  @override
  String get sourceChanged => 'La source a changé depuis cette traduction';

  @override
  String sourceIn(String language) => 'Source en $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Langues';

  @override
  String get languageMenuHint =>
      'Touchez pour changer · cochez pour comparer côte à côte.';

  @override
  String compareLanguage(String language) => 'Comparer : $language';

  @override
  String switchToLanguage(String language) => 'Passer en $language';

  @override
  String get editing => 'en cours';

  @override
  String get inherited => 'Hérité';

  @override
  String get custom => 'Personnalisé';

  @override
  String inheritedDescription(String source) =>
      'Suit la source ($source) — mis à jour automatiquement';

  @override
  String customDescription(String? noun) =>
      'Définir votre propre ${noun ?? 'valeur'}';

  @override
  String get valueRequired => 'Obligatoire';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Saisissez au moins ${number(min)} caractère',
    other: 'Saisissez au moins ${number(min)} caractères',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Saisissez au plus ${number(max)} caractère',
    other: 'Saisissez au plus ${number(max)} caractères',
  );

  @override
  String get invalidEmail => 'Saisissez une adresse e-mail valide';

  @override
  String get invalidUrl => 'Saisissez une adresse web valide';

  @override
  String get invalidFormat => 'Saisissez une valeur au format attendu';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Ajoutez au moins ${number(count)} élément',
    other: 'Ajoutez au moins ${number(count)} éléments',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Gardez au plus ${number(count)} élément',
    other: 'Gardez au plus ${number(count)} éléments',
  );

  @override
  String get checking => 'Vérification…';

  @override
  String get optionalMarker => '(facultatif)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} champ à corriger',
    other: '${number(count)} champs à corriger',
  );

  @override
  String jumpToField(String label) => 'Aller au champ $label';

  @override
  String fieldMessage(String label, String message) => '$label\u00A0: $message';

  @override
  String get wizardNext => 'Suivant';

  @override
  String get wizardBack => 'Précédent';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Corrigez ${number(count)} champ pour continuer',
    other: 'Corrigez ${number(count)} champs pour continuer',
  );
}
