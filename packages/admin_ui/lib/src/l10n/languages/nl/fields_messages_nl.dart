import '../../sections/fields_messages.dart';

/// Dutch [FieldsMessages].
class FieldsMessagesNl extends FieldsMessages {
  const FieldsMessagesNl([super.localeName = 'nl']);

  /// Dutch's single quotation marks.
  @override
  String quoted(String text) => '‘$text’';

  @override
  String get filterOrAdd => 'Filteren of toevoegen…';

  @override
  String maxSelected(int max) => 'Maximum van ${number(max)} bereikt';

  @override
  String createOption(String value) => '${quoted(value)} aanmaken';

  @override
  String get onLabel => 'Aan';

  @override
  String get offLabel => 'Uit';

  @override
  String get selectDate => 'Datum selecteren…';

  @override
  String get selectDateTime => 'Datum en tijd selecteren…';

  @override
  String get selectTime => 'Tijd selecteren…';

  @override
  String get clearDate => 'Datum wissen';

  @override
  String get year => 'Jaar';

  @override
  String get month => 'Maand';

  @override
  String get day => 'Dag';

  @override
  String get hour => 'Uur';

  @override
  String get minute => 'Minuut';

  /// Dag, maand, jaar, uur, minuut, in lower case as Dutch forms and
  /// Material's own date input write them: dd-mm-jjjj, uu:mm.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'jjjj', month: 'mm', day: 'dd', hour: 'uu', minute: 'mm');

  @override
  String numberLike(String example) => 'Geef een getal op, zoals $example';

  @override
  String numberBetween(String min, String max) =>
      'Geef een getal op tussen $min en $max';

  @override
  String numberAtLeast(String min) => 'Geef minimaal $min op';

  @override
  String numberAtMost(String max) => 'Geef maximaal $max op';

  @override
  String get decrease => 'Verlagen';

  @override
  String get increase => 'Verhogen';

  @override
  String get pickColor => 'Kleur kiezen…';

  @override
  String get hexDigitsError => 'Geef 3 of 6 hexadecimale cijfers op';

  @override
  String get setColor => 'Instellen';

  @override
  String get validJson => 'Geldige JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      'Regel ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Opmaken';

  @override
  String get plainText => 'Platte tekst';

  @override
  String get addTag => 'Tag toevoegen…';

  @override
  String get noTags => 'Geen tags';

  @override
  String get noEntries => 'Geen items';

  @override
  String duplicateKey(String key) =>
      'Dubbele sleutel ${quoted(key)} — de onderste rij geldt';

  @override
  String get duplicateKeys => 'Dubbele sleutels — de onderste rij geldt';

  @override
  String get removeRow => 'Rij weghalen';

  @override
  String get noMedia => 'Geen media';

  @override
  String retryItem(String name) => '$name opnieuw proberen';

  @override
  String cancelUpload(String name) => 'Upload van $name annuleren';

  @override
  String get cover => 'Omslag';

  @override
  String get processing => 'Verwerken…';

  @override
  String get addImage => 'Afbeelding toevoegen';

  @override
  String get addFile => 'Bestand toevoegen';

  @override
  String get noReference => 'Geen koppeling';

  @override
  String get unavailable => 'Niet beschikbaar';

  @override
  String get replaceReference => 'Vervangen';

  @override
  String get typeToSearch => 'Typ om te zoeken…';

  @override
  String removeItemAt(int position) => 'Item ${number(position)} weghalen';

  @override
  String get noItemsYet => 'Nog geen items.';

  @override
  String get help => 'Help';

  @override
  String helpFor(String field) => 'Help bij $field';

  @override
  String get versionHistory => 'Versiegeschiedenis';

  @override
  String get pendingEdit => 'Openstaande wijziging';

  @override
  String get baseline => 'Live';

  @override
  String editedDetail(String detail) => 'Bewerkt · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Opmerkingen',
    one: '${number(count)} opmerking',
    other: '${number(count)} opmerkingen',
  );

  @override
  String commentsHeading(int count) => 'Opmerkingen · ${number(count)}';

  @override
  String get resolve => 'Oplossen';

  @override
  String get replyPlaceholder => 'Reageren…';

  @override
  String get sendReply => 'Reactie verzenden';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Opmerking bij dit veld toevoegen',
    one: '${number(openThreads)} open discussie',
    other: '${number(openThreads)} open discussies',
  );

  @override
  String get openThread => 'Discussie openen';

  @override
  String get translationSource => 'Bron';

  @override
  String get translationUpToDate => 'Actueel';

  @override
  String get translationNeedsReview => 'Controle nodig';

  @override
  String get translationOutdated => 'Verouderd';

  @override
  String get translationMissing => 'Ontbreekt';

  @override
  String get retranslate => 'Opnieuw vertalen';

  /// A language's name takes het: naar het Frans.
  @override
  String retranslateLanguage(String language) =>
      'Opnieuw vertalen naar het $language';

  @override
  String get sourceChanged => 'De bron is gewijzigd sinds deze vertaling';

  @override
  String sourceIn(String language) => 'Bron in het $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Talen';

  @override
  String get languageMenuHint =>
      'Tik om te wisselen · vink aan om naast elkaar te vergelijken.';

  @override
  String compareLanguage(String language) => 'Vergelijken met het $language';

  @override
  String switchToLanguage(String language) =>
      'Overschakelen naar het $language';

  @override
  String get editing => 'in bewerking';

  @override
  String get inherited => 'Overgenomen';

  @override
  String get custom => 'Aangepast';

  @override
  String inheritedDescription(String source) =>
      'Volgt de bron ($source) — wordt automatisch bijgewerkt';

  @override
  String customDescription(String? noun) =>
      'Eigen ${noun ?? 'waarde'} instellen';

  @override
  String get valueRequired => 'Verplicht';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Geef minimaal ${number(min)} teken op',
    other: 'Geef minimaal ${number(min)} tekens op',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Geef maximaal ${number(max)} teken op',
    other: 'Geef maximaal ${number(max)} tekens op',
  );

  @override
  String get invalidEmail => 'Geef een geldig e-mailadres op';

  @override
  String get invalidUrl => 'Geef een geldig webadres op';

  @override
  String get invalidFormat => 'Geef een waarde op in de verwachte indeling';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Voeg minimaal ${number(count)} item toe',
    other: 'Voeg minimaal ${number(count)} items toe',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Houd maximaal ${number(count)} item over',
    other: 'Houd maximaal ${number(count)} items over',
  );

  @override
  String get checking => 'Controleren…';

  @override
  String get optionalMarker => '(optioneel)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} veld moet worden gecorrigeerd',
    other: '${number(count)} velden moeten worden gecorrigeerd',
  );

  @override
  String jumpToField(String label) => 'Ga naar $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Volgende';

  @override
  String get wizardBack => 'Terug';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Corrigeer ${number(count)} veld om door te gaan',
    other: 'Corrigeer ${number(count)} velden om door te gaan',
  );
}
