import '../messages.dart';

/// Strings for the field bodies, the language lanes and their translation
/// status words, and the comments capability.
///
/// [FieldsMessagesEn], [FieldsMessagesFr] and [FieldsMessagesAr] each
/// extend this class directly, so a member added here without its French or
/// Arabic text fails to compile. Add a message to all three in the same edit.
abstract class FieldsMessages extends AdminMessages {
  const FieldsMessages(super.localeName);

  /// [text] in the language's quotation marks: “text” in English, « text »
  /// in French.
  String quoted(String text);

  /// The filter box of a select that also accepts new values.
  String get filterOrAdd;

  /// The footer of a multi-select holding its [max] selections.
  String maxSelected(int max);

  /// The row that adds a typed value to a multi-select; [value] comes
  /// [quoted].
  String createOption(String value);

  /// The state word of a switch that is on.
  String get onLabel;

  /// The state word of a switch that is off.
  String get offLabel;

  /// The placeholder of an empty date field.
  String get selectDate;

  /// The placeholder of an empty date-and-time field.
  String get selectDateTime;

  /// The placeholder of an empty time field.
  String get selectTime;

  /// Empties a date field.
  String get clearDate;

  /// The accessible name of a date editor's year cell.
  String get year;

  /// The accessible name of a date editor's month cell.
  String get month;

  /// The accessible name of a date editor's day cell.
  String get day;

  /// The accessible name of a time editor's hour cell.
  String get hour;

  /// The accessible name of a time editor's minute cell.
  String get minute;

  /// The placeholders of a date editor's year, month and day cells and a
  /// time editor's hour and minute cells, which the legend under them
  /// repeats: YYYY, MM, DD, HH and MM in English. A masked date field lays
  /// them over its digits when each is as long as its part, four characters
  /// for the year and two for the others.
  ({String year, String month, String day, String hour, String minute})
  get dateTokens;

  /// A number field holds text that is not a number in the app's notation;
  /// [example] is one that is, such as "1,234.5".
  String numberLike(String example);

  /// A number field's value is out of its range; [min] and [max] come
  /// formatted, with any prefix and unit.
  String numberBetween(String min, String max);

  /// A number field's value is below [min], its only bound.
  String numberAtLeast(String min);

  /// A number field's value is above [max], its only bound.
  String numberAtMost(String max);

  /// The stepper button that lowers a number by one step.
  String get decrease;

  /// The stepper button that raises a number by one step.
  String get increase;

  /// The placeholder of an empty color field.
  String get pickColor;

  /// A typed hex color that is not one.
  String get hexDigitsError;

  /// Applies the typed hex color.
  String get setColor;

  /// The footer of a code field holding valid JSON.
  String get validJson;

  /// Where a code field's JSON stops parsing: [detail] is the parser's own
  /// description.
  String jsonError(int line, int column, String detail);

  /// Re-indents a code field's JSON.
  String get formatJson;

  /// The language of a code field that highlights nothing.
  String get plainText;

  /// The placeholder of a tags field's input.
  String get addTag;

  /// A read-only tags field with no tags.
  String get noTags;

  /// A read-only key-value field with no pairs.
  String get noEntries;

  /// Two rows share [key], so the lower one's value is kept.
  String duplicateKey(String key);

  /// More than one key is shared between rows.
  String get duplicateKeys;

  /// Removes a key-value row whose key is still empty.
  String get removeRow;

  /// A read-only media field with no items.
  String get noMedia;

  /// Uploads the failed file [name] again.
  String retryItem(String name);

  /// Stops the upload of [name] under way.
  String cancelUpload(String name);

  /// The badge on a gallery's first image.
  String get cover;

  /// A file uploaded and still being processed, with a trailing ellipsis.
  String get processing;

  /// The add tile of an image field.
  String get addImage;

  /// The add tile of a file field.
  String get addFile;

  /// A read-only reference field linking nothing.
  String get noReference;

  /// A linked record that no longer exists.
  String get unavailable;

  /// The prompt of a reference picker before anything is typed.
  String get typeToSearch;

  /// Removes the repeater item at [position], counted from 1.
  String removeItemAt(int position);

  /// An empty repeater.
  String get noItemsYet;

  /// The help button of a field.
  String get help;

  /// The help button of the field labelled [field].
  String helpFor(String field);

  /// A field's history button, and the heading of its popover.
  String get versionHistory;

  /// The heading of a field's pending change, in sentence case.
  String get pendingEdit;

  /// The baseline value of a field, beside its edited one in the history
  /// popup.
  String get baseline;

  /// A field's edited marker with what changed, such as the languages.
  String editedDetail(String detail);

  /// A field's comments button: "Comments" with none.
  String comments(int count);

  /// The heading of a field's comment thread.
  String commentsHeading(int count);

  /// Marks a comment thread as resolved.
  String get resolve;

  /// The placeholder of a thread's reply box, with a trailing ellipsis.
  String get replyPlaceholder;

  /// Sends the reply typed into a thread.
  String get sendReply;

  /// A field's comment button: an invitation to comment with no open
  /// threads, otherwise how many are open.
  String commentOnField(int openThreads);

  /// Opens the comment thread of a text range.
  String get openThread;

  // Language lanes.

  /// The language the others are translated from.
  String get translationSource;

  /// A translation that matches its current source.
  String get translationUpToDate;

  /// A translation no one has vouched for yet.
  String get translationNeedsReview;

  /// A translation whose source changed after it was made.
  String get translationOutdated;

  /// A translation that does not exist yet.
  String get translationMissing;

  /// Machine-translates an outdated target again.
  String get retranslate;

  /// [retranslate] into the language named [language].
  String retranslateLanguage(String language);

  /// An outdated translation: its source was edited after it was made.
  String get sourceChanged;

  /// The accessible name of a source lane written in [language].
  String sourceIn(String language);

  /// The accessible name of the lane of [field] in [language].
  String fieldInLanguage(String field, String language);

  /// The accessible name of the language switcher.
  String get languages;

  /// How the language switcher's rows and checkboxes work.
  String get languageMenuHint;

  /// Shows the language named [language] beside the others.
  String compareLanguage(String language);

  /// Makes the language named [language] the one being edited.
  String switchToLanguage(String language);

  /// Marks the language being edited in the switcher, in lower case.
  String get editing;

  /// A lane that mirrors its source.
  String get inherited;

  /// A lane with a value of its own.
  String get custom;

  /// What choosing [inherited] does: the lane follows [source].
  String inheritedDescription(String source);

  /// What choosing [custom] does. [noun] names the value, such as "slug";
  /// null says "value".
  String customDescription(String? noun);

  // Validation.

  /// A required field left empty.
  String get valueRequired;

  /// A text shorter than its [min] characters.
  String tooShort(int min);

  /// A text longer than its [max] characters.
  String tooLong(int max);

  /// A text that is not an email address.
  String get invalidEmail;

  /// A text that is not a web address.
  String get invalidUrl;

  /// A text that does not match the pattern it is checked against.
  String get invalidFormat;

  /// A number below [min], its only bound; [min] comes formatted. Worded as
  /// [numberAtLeast], so a number field says the same whichever checked it.
  String tooSmall(String min);

  /// A number above [max], its only bound; [max] comes formatted. Worded as
  /// [numberAtMost].
  String tooLarge(String max);

  /// A list holding fewer than [count] items: rows of a repeater, tags,
  /// choices.
  String addAtLeast(int count);

  /// A list holding more than [count] items.
  String keepAtMost(int count);

  // Forms.

  /// A field whose value is being checked (by a server, say), with a
  /// trailing ellipsis.
  String get checking;

  /// Follows the label of a field that is not required, in the themes that
  /// mark the optional fields rather than the required ones; its own
  /// punctuation included.
  String get optionalMarker;

  /// The heading of a form's list of the [count] fields that need fixing.
  String validationSummaryTitle(int count);

  /// A link in that list that takes focus to the field labelled [label].
  String jumpToField(String label);

  /// A field's name and its message, in that list: "Email: Enter a valid
  /// email address".
  String fieldMessage(String label, String message);

  /// Moves a multi-step form to its next step.
  String get wizardNext;

  /// Moves a multi-step form back to its previous step.
  String get wizardBack;

  /// Why a multi-step form does not move on: [count] fields of the step need
  /// fixing first.
  String wizardStepBlocked(int count);
}

/// English [FieldsMessages]. Subclass it to override a few strings.
class FieldsMessagesEn extends FieldsMessages {
  const FieldsMessagesEn([super.localeName = 'en']);

  @override
  String quoted(String text) => '“$text”';

  @override
  String get filterOrAdd => 'Filter or add…';

  @override
  String maxSelected(int max) => 'Max ${number(max)} reached';

  @override
  String createOption(String value) => 'Create ${quoted(value)}';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get selectDate => 'Select date…';

  @override
  String get selectDateTime => 'Select date & time…';

  @override
  String get selectTime => 'Select time…';

  @override
  String get clearDate => 'Clear date';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get day => 'Day';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'YYYY', month: 'MM', day: 'DD', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) => 'Enter a number like $example';

  @override
  String numberBetween(String min, String max) =>
      'Enter a number from $min to $max';

  @override
  String numberAtLeast(String min) => 'Enter $min or more';

  @override
  String numberAtMost(String max) => 'Enter $max or less';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get pickColor => 'Pick a color…';

  @override
  String get hexDigitsError => 'Enter 3 or 6 hex digits';

  @override
  String get setColor => 'Set';

  @override
  String get validJson => 'Valid JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      'Line ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Format';

  @override
  String get plainText => 'Plain text';

  @override
  String get addTag => 'Add a tag…';

  @override
  String get noTags => 'No tags';

  @override
  String get noEntries => 'No entries';

  @override
  String duplicateKey(String key) =>
      'Duplicate key ${quoted(key)} — the lower row wins';

  @override
  String get duplicateKeys => 'Duplicate keys — the lower row wins';

  @override
  String get removeRow => 'Remove row';

  @override
  String get noMedia => 'No media';

  @override
  String retryItem(String name) => 'Retry $name';

  @override
  String cancelUpload(String name) => 'Cancel upload of $name';

  @override
  String get cover => 'Cover';

  @override
  String get processing => 'Processing…';

  @override
  String get addImage => 'Add image';

  @override
  String get addFile => 'Add file';

  @override
  String get noReference => 'No reference';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get typeToSearch => 'Type to search…';

  @override
  String removeItemAt(int position) => 'Remove item ${number(position)}';

  @override
  String get noItemsYet => 'No items yet.';

  @override
  String get help => 'Help';

  @override
  String helpFor(String field) => 'Help for $field';

  @override
  String get versionHistory => 'Version history';

  @override
  String get pendingEdit => 'Pending edit';

  @override
  String get baseline => 'Live';

  @override
  String editedDetail(String detail) => 'Edited · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Comments',
    one: '${number(count)} comment',
    other: '${number(count)} comments',
  );

  @override
  String commentsHeading(int count) => 'Comments · ${number(count)}';

  @override
  String get resolve => 'Resolve';

  @override
  String get replyPlaceholder => 'Reply…';

  @override
  String get sendReply => 'Send reply';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Comment on this field',
    one: '${number(openThreads)} open thread',
    other: '${number(openThreads)} open threads',
  );

  @override
  String get openThread => 'Open thread';

  @override
  String get translationSource => 'Source';

  @override
  String get translationUpToDate => 'Up to date';

  @override
  String get translationNeedsReview => 'Needs review';

  @override
  String get translationOutdated => 'Outdated';

  @override
  String get translationMissing => 'Missing';

  @override
  String get retranslate => 'Re-translate';

  @override
  String retranslateLanguage(String language) => 'Re-translate $language';

  @override
  String get sourceChanged => 'Source changed since this was translated';

  @override
  String sourceIn(String language) => '$language source';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Languages';

  @override
  String get languageMenuHint =>
      'Tap to switch · check to compare side by side.';

  @override
  String compareLanguage(String language) => 'Compare $language';

  @override
  String switchToLanguage(String language) => 'Switch to $language';

  @override
  String get editing => 'editing';

  @override
  String get inherited => 'Inherited';

  @override
  String get custom => 'Custom';

  @override
  String inheritedDescription(String source) =>
      'Mirror $source — updates automatically';

  @override
  String customDescription(String? noun) => 'Set your own ${noun ?? 'value'}';

  @override
  String get valueRequired => 'Required';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Enter at least ${number(min)} character',
    other: 'Enter at least ${number(min)} characters',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Enter at most ${number(max)} character',
    other: 'Enter at most ${number(max)} characters',
  );

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get invalidUrl => 'Enter a valid web address';

  @override
  String get invalidFormat => 'Enter a value in the expected format';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Add at least ${number(count)} item',
    other: 'Add at least ${number(count)} items',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Keep at most ${number(count)} item',
    other: 'Keep at most ${number(count)} items',
  );

  @override
  String get checking => 'Checking…';

  @override
  String get optionalMarker => '(optional)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} field needs fixing',
    other: '${number(count)} fields need fixing',
  );

  @override
  String jumpToField(String label) => 'Go to $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Next';

  @override
  String get wizardBack => 'Back';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Fix ${number(count)} field to continue',
    other: 'Fix ${number(count)} fields to continue',
  );
}

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

/// Arabic [FieldsMessages].
class FieldsMessagesAr extends FieldsMessages {
  const FieldsMessagesAr([super.localeName = 'ar']);

  @override
  String quoted(String text) => '”$text“';

  @override
  String get filterOrAdd => 'تصفية أو إضافة…';

  @override
  String maxSelected(int max) => 'بلغت الحد الأقصى (${number(max)})';

  @override
  String createOption(String value) => 'إنشاء ${quoted(value)}';

  @override
  String get onLabel => 'مفعّل';

  @override
  String get offLabel => 'معطّل';

  @override
  String get selectDate => 'اختر تاريخًا…';

  @override
  String get selectDateTime => 'اختر التاريخ والوقت…';

  @override
  String get selectTime => 'اختر وقتًا…';

  @override
  String get clearDate => 'مسح التاريخ';

  @override
  String get year => 'السنة';

  @override
  String get month => 'الشهر';

  @override
  String get day => 'اليوم';

  @override
  String get hour => 'الساعة';

  @override
  String get minute => 'الدقيقة';

  /// The parts' own words: Arabic has no letters to repeat per digit.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'سنة', month: 'شهر', day: 'يوم', hour: 'ساعة', minute: 'دقيقة');

  @override
  String numberLike(String example) => 'أدخل رقمًا مثل $example';

  @override
  String numberBetween(String min, String max) => 'أدخل رقمًا من $min إلى $max';

  @override
  String numberAtLeast(String min) => 'أدخل $min أو أكثر';

  @override
  String numberAtMost(String max) => 'أدخل $max أو أقل';

  @override
  String get decrease => 'إنقاص';

  @override
  String get increase => 'زيادة';

  @override
  String get pickColor => 'اختر لونًا…';

  @override
  String get hexDigitsError => 'أدخل 3 أو 6 أرقام ست عشرية';

  @override
  String get setColor => 'تعيين';

  @override
  String get validJson => 'JSON صالح';

  @override
  String jsonError(int line, int column, String detail) =>
      'السطر ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'تنسيق';

  @override
  String get plainText => 'نص عادي';

  @override
  String get addTag => 'أضف وسمًا…';

  @override
  String get noTags => 'لا توجد وسوم';

  @override
  String get noEntries => 'لا توجد إدخالات';

  @override
  String duplicateKey(String key) =>
      'المفتاح ${quoted(key)} مكرر — يُعتمد الصف الأدنى';

  @override
  String get duplicateKeys => 'مفاتيح مكررة — يُعتمد الصف الأدنى';

  @override
  String get removeRow => 'إزالة الصف';

  @override
  String get noMedia => 'لا توجد وسائط';

  @override
  String retryItem(String name) => 'إعادة محاولة $name';

  @override
  String cancelUpload(String name) => 'إلغاء رفع $name';

  @override
  String get cover => 'الغلاف';

  @override
  String get processing => 'جارٍ المعالجة…';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get addFile => 'إضافة ملف';

  @override
  String get noReference => 'لا يوجد مرجع';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get typeToSearch => 'اكتب للبحث…';

  @override
  String removeItemAt(int position) => 'إزالة العنصر ${number(position)}';

  @override
  String get noItemsYet => 'لا توجد عناصر بعد.';

  @override
  String get help => 'مساعدة';

  @override
  String helpFor(String field) => 'مساعدة بشأن $field';

  @override
  String get versionHistory => 'سجل الإصدارات';

  @override
  String get pendingEdit => 'تعديل معلّق';

  @override
  String get baseline => 'المنشور';

  @override
  String editedDetail(String detail) => 'معدَّل · $detail';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String comments(int count) => plural(
    count,
    zero: 'التعليقات',
    one: 'تعليق واحد',
    two: 'تعليقان',
    few: '${number(count)} تعليقات',
    many: '${number(count)} تعليقًا',
    other: '${number(count)} تعليق',
  );

  @override
  String commentsHeading(int count) => 'التعليقات · ${number(count)}';

  @override
  String get resolve => 'حلّ';

  @override
  String get replyPlaceholder => 'ردّ…';

  @override
  String get sendReply => 'إرسال الرد';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'علّق على هذا الحقل',
    one: 'نقاش مفتوح واحد',
    two: 'نقاشان مفتوحان',
    few: '${number(openThreads)} نقاشات مفتوحة',
    many: '${number(openThreads)} نقاشًا مفتوحًا',
    other: '${number(openThreads)} نقاش مفتوح',
  );

  @override
  String get openThread => 'فتح النقاش';

  @override
  String get translationSource => 'المصدر';

  @override
  String get translationUpToDate => 'محدَّثة';

  @override
  String get translationNeedsReview => 'بحاجة إلى مراجعة';

  @override
  String get translationOutdated => 'قديمة';

  @override
  String get translationMissing => 'ناقصة';

  @override
  String get retranslate => 'إعادة الترجمة';

  @override
  String retranslateLanguage(String language) => 'إعادة الترجمة إلى $language';

  @override
  String get sourceChanged => 'تغيّر المصدر منذ هذه الترجمة';

  @override
  String sourceIn(String language) => 'المصدر باللغة $language';

  @override
  String fieldInLanguage(String field, String language) => '$field، $language';

  @override
  String get languages => 'اللغات';

  @override
  String get languageMenuHint => 'اضغط للتبديل · حدّد للمقارنة جنبًا إلى جنب.';

  @override
  String compareLanguage(String language) => 'مقارنة $language';

  @override
  String switchToLanguage(String language) => 'التبديل إلى $language';

  @override
  String get editing => 'قيد التحرير';

  @override
  String get inherited => 'موروث';

  @override
  String get custom => 'مخصص';

  @override
  String inheritedDescription(String source) =>
      'يطابق المصدر ($source) — يُحدَّث تلقائيًا';

  @override
  String customDescription(String? noun) =>
      noun == null ? 'عيّن قيمة خاصة بك' : 'عيّن $noun بنفسك';

  @override
  String get valueRequired => 'مطلوب';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String tooShort(int min) => plural(
    min,
    one: 'أدخل حرفًا واحدًا على الأقل',
    two: 'أدخل حرفين على الأقل',
    few: 'أدخل ${number(min)} أحرف على الأقل',
    many: 'أدخل ${number(min)} حرفًا على الأقل',
    other: 'أدخل ${number(min)} حرف على الأقل',
  );

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String tooLong(int max) => plural(
    max,
    one: 'أدخل حرفًا واحدًا على الأكثر',
    two: 'أدخل حرفين على الأكثر',
    few: 'أدخل ${number(max)} أحرف على الأكثر',
    many: 'أدخل ${number(max)} حرفًا على الأكثر',
    other: 'أدخل ${number(max)} حرف على الأكثر',
  );

  @override
  String get invalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا';

  @override
  String get invalidUrl => 'أدخل عنوان ويب صالحًا';

  @override
  String get invalidFormat => 'أدخل قيمة بالتنسيق المطلوب';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'أضف عنصرًا واحدًا على الأقل',
    two: 'أضف عنصرين على الأقل',
    few: 'أضف ${number(count)} عناصر على الأقل',
    many: 'أضف ${number(count)} عنصرًا على الأقل',
    other: 'أضف ${number(count)} عنصر على الأقل',
  );

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'لا تتجاوز عنصرًا واحدًا',
    two: 'لا تتجاوز عنصرين',
    few: 'لا تتجاوز ${number(count)} عناصر',
    many: 'لا تتجاوز ${number(count)} عنصرًا',
    other: 'لا تتجاوز ${number(count)} عنصر',
  );

  @override
  String get checking => 'جارٍ التحقق…';

  @override
  String get optionalMarker => '(اختياري)';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: 'حقل واحد بحاجة إلى تصحيح',
    two: 'حقلان بحاجة إلى تصحيح',
    few: '${number(count)} حقول بحاجة إلى تصحيح',
    many: '${number(count)} حقلًا بحاجة إلى تصحيح',
    other: '${number(count)} حقل بحاجة إلى تصحيح',
  );

  @override
  String jumpToField(String label) => 'الانتقال إلى $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'التالي';

  @override
  String get wizardBack => 'السابق';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'صحّح حقلًا واحدًا للمتابعة',
    two: 'صحّح حقلين للمتابعة',
    few: 'صحّح ${number(count)} حقول للمتابعة',
    many: 'صحّح ${number(count)} حقلًا للمتابعة',
    other: 'صحّح ${number(count)} حقل للمتابعة',
  );
}
