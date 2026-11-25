import '../../sections/fields_messages.dart';

/// German [FieldsMessages].
class FieldsMessagesDe extends FieldsMessages {
  const FieldsMessagesDe([super.localeName = 'de']);

  /// German quotation marks: low opening, high closing.
  @override
  String quoted(String text) => '„$text“';

  @override
  String get filterOrAdd => 'Filtern oder hinzufügen…';

  @override
  String maxSelected(int max) => 'Maximum von ${number(max)} erreicht';

  @override
  String createOption(String value) => '${quoted(value)} erstellen';

  @override
  String get onLabel => 'Ein';

  @override
  String get offLabel => 'Aus';

  @override
  String get selectDate => 'Datum auswählen…';

  @override
  String get selectDateTime => 'Datum und Uhrzeit auswählen…';

  @override
  String get selectTime => 'Uhrzeit auswählen…';

  @override
  String get clearDate => 'Datum löschen';

  @override
  String get year => 'Jahr';

  @override
  String get month => 'Monat';

  @override
  String get day => 'Tag';

  @override
  String get hour => 'Stunde';

  @override
  String get minute => 'Minute';

  /// Tag, Monat, Jahr, as in TT.MM.JJJJ; hours and minutes as in hh:mm.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'JJJJ', month: 'MM', day: 'TT', hour: 'hh', minute: 'mm');

  @override
  String numberLike(String example) => 'Zahl im Format $example eingeben';

  @override
  String numberBetween(String min, String max) =>
      'Zahl von $min bis $max eingeben';

  @override
  String numberAtLeast(String min) => 'Mindestens $min eingeben';

  @override
  String numberAtMost(String max) => 'Höchstens $max eingeben';

  @override
  String get decrease => 'Verringern';

  @override
  String get increase => 'Erhöhen';

  @override
  String get pickColor => 'Farbe auswählen…';

  @override
  String get hexDigitsError => '3 oder 6 Hexadezimalziffern eingeben';

  @override
  String get setColor => 'Festlegen';

  @override
  String get validJson => 'Gültiges JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      'Zeile ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formatieren';

  @override
  String get plainText => 'Nur Text';

  @override
  String get addTag => 'Tag hinzufügen…';

  @override
  String get noTags => 'Keine Tags';

  @override
  String get noEntries => 'Keine Einträge';

  @override
  String duplicateKey(String key) =>
      'Doppelter Schlüssel ${quoted(key)} – die untere Zeile hat Vorrang';

  @override
  String get duplicateKeys =>
      'Doppelte Schlüssel – die untere Zeile hat Vorrang';

  @override
  String get removeRow => 'Zeile entfernen';

  @override
  String get noMedia => 'Keine Mediendateien';

  @override
  String retryItem(String name) => '$name erneut hochladen';

  @override
  String cancelUpload(String name) => 'Upload von $name abbrechen';

  @override
  String get cover => 'Titelbild';

  @override
  String get processing => 'Wird verarbeitet…';

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get addFile => 'Datei hinzufügen';

  @override
  String get noReference => 'Keine Verknüpfung';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get replaceReference => 'Ersetzen';

  @override
  String get typeToSearch => 'Suchbegriff eingeben…';

  @override
  String removeItemAt(int position) => 'Element ${number(position)} entfernen';

  @override
  String get noItemsYet => 'Noch keine Elemente.';

  @override
  String get help => 'Hilfe';

  @override
  String helpFor(String field) => 'Hilfe zu $field';

  @override
  String get versionHistory => 'Versionsverlauf';

  @override
  String get pendingEdit => 'Ausstehende Änderung';

  @override
  String get baseline => 'Veröffentlicht';

  @override
  String editedDetail(String detail) => 'Bearbeitet · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Kommentare',
    one: '${number(count)} Kommentar',
    other: '${number(count)} Kommentare',
  );

  @override
  String commentsHeading(int count) => 'Kommentare · ${number(count)}';

  @override
  String get resolve => 'Auflösen';

  @override
  String get replyPlaceholder => 'Antworten…';

  @override
  String get sendReply => 'Antwort senden';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Feld kommentieren',
    one: '${number(openThreads)} offene Diskussion',
    other: '${number(openThreads)} offene Diskussionen',
  );

  @override
  String get openThread => 'Diskussion öffnen';

  @override
  String get translationSource => 'Quelle';

  @override
  String get translationUpToDate => 'Aktuell';

  @override
  String get translationNeedsReview => 'Zu prüfen';

  @override
  String get translationOutdated => 'Veraltet';

  @override
  String get translationMissing => 'Fehlt';

  @override
  String get retranslate => 'Neu übersetzen';

  @override
  String retranslateLanguage(String language) => '$language neu übersetzen';

  @override
  String get sourceChanged =>
      'Die Quelle wurde seit dieser Übersetzung geändert';

  @override
  String sourceIn(String language) => 'Quelle auf $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Sprachen';

  @override
  String get languageMenuHint =>
      'Antippen zum Wechseln · Anhaken für den direkten Vergleich.';

  @override
  String compareLanguage(String language) => 'Mit $language vergleichen';

  @override
  String switchToLanguage(String language) => 'Zu $language wechseln';

  @override
  String get editing => 'in Bearbeitung';

  @override
  String get inherited => 'Übernommen';

  @override
  String get custom => 'Angepasst';

  @override
  String inheritedDescription(String source) =>
      '$source übernehmen – wird automatisch aktualisiert';

  /// Leads with the noun, so that its gender asks for no article.
  @override
  String customDescription(String? noun) =>
      '${noun ?? 'Wert'} selbst festlegen';

  @override
  String get valueRequired => 'Pflichtfeld';

  /// Zeichen is the same in the singular and the plural.
  @override
  String tooShort(int min) =>
      plural(min, other: 'Mindestens ${number(min)} Zeichen eingeben');

  /// Zeichen is the same in the singular and the plural.
  @override
  String tooLong(int max) =>
      plural(max, other: 'Höchstens ${number(max)} Zeichen eingeben');

  @override
  String get invalidEmail => 'Gültige E-Mail-Adresse eingeben';

  @override
  String get invalidUrl => 'Gültige Webadresse eingeben';

  @override
  String get invalidFormat => 'Wert im erwarteten Format eingeben';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Mindestens ${number(count)} Element hinzufügen',
    other: 'Mindestens ${number(count)} Elemente hinzufügen',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Auf höchstens ${number(count)} Element reduzieren',
    other: 'Auf höchstens ${number(count)} Elemente reduzieren',
  );

  @override
  String get checking => 'Wird geprüft…';

  @override
  String get optionalMarker => '(optional)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} Feld muss korrigiert werden',
    other: '${number(count)} Felder müssen korrigiert werden',
  );

  @override
  String jumpToField(String label) => 'Zum Feld $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Weiter';

  @override
  String get wizardBack => 'Zurück';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: '${number(count)} Feld korrigieren, um fortzufahren',
    other: '${number(count)} Felder korrigieren, um fortzufahren',
  );
}
