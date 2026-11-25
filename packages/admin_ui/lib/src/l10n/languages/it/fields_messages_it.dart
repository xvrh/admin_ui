import '../../sections/fields_messages.dart';

/// Italian [FieldsMessages].
class FieldsMessagesIt extends FieldsMessages {
  const FieldsMessagesIt([super.localeName = 'it']);

  /// Caporali, with no space inside.
  @override
  String quoted(String text) => '«$text»';

  @override
  String get filterOrAdd => 'Filtra o aggiungi…';

  @override
  String maxSelected(int max) => 'Limite di ${number(max)} raggiunto';

  @override
  String createOption(String value) => 'Crea ${quoted(value)}';

  @override
  String get onLabel => 'Attivato';

  @override
  String get offLabel => 'Disattivato';

  @override
  String get selectDate => 'Seleziona data…';

  @override
  String get selectDateTime => 'Seleziona data e ora…';

  @override
  String get selectTime => 'Seleziona ora…';

  @override
  String get clearDate => 'Cancella data';

  @override
  String get year => 'Anno';

  @override
  String get month => 'Mese';

  @override
  String get day => 'Giorno';

  @override
  String get hour => 'Ora';

  @override
  String get minute => 'Minuto';

  /// Giorno, mese, anno; ore and minuti as HH:MM.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'AAAA', month: 'MM', day: 'GG', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) =>
      'Inserisci un numero nel formato $example';

  @override
  String numberBetween(String min, String max) =>
      'Inserisci un numero compreso tra $min e $max';

  @override
  String numberAtLeast(String min) => 'Inserisci almeno $min';

  @override
  String numberAtMost(String max) => 'Inserisci al massimo $max';

  @override
  String get decrease => 'Diminuisci';

  @override
  String get increase => 'Aumenta';

  @override
  String get pickColor => 'Scegli un colore…';

  @override
  String get hexDigitsError => 'Inserisci 3 o 6 cifre esadecimali';

  @override
  String get setColor => 'Imposta';

  @override
  String get validJson => 'JSON valido';

  @override
  String jsonError(int line, int column, String detail) =>
      'Riga ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formatta';

  @override
  String get plainText => 'Testo normale';

  @override
  String get addTag => 'Aggiungi un tag…';

  @override
  String get noTags => 'Nessun tag';

  @override
  String get noEntries => 'Nessuna voce';

  @override
  String duplicateKey(String key) =>
      'Chiave ${quoted(key)} duplicata — prevale la riga più in basso';

  @override
  String get duplicateKeys => 'Chiavi duplicate — prevale la riga più in basso';

  @override
  String get removeRow => 'Rimuovi riga';

  @override
  String get noMedia => 'Nessuna risorsa';

  @override
  String retryItem(String name) => 'Riprova $name';

  @override
  String cancelUpload(String name) => 'Annulla caricamento di $name';

  @override
  String get cover => 'Copertina';

  @override
  String get processing => 'Elaborazione…';

  @override
  String get addImage => 'Aggiungi immagine';

  @override
  String get addFile => 'Aggiungi file';

  @override
  String get noReference => 'Nessun riferimento';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get replaceReference => 'Sostituisci';

  @override
  String get typeToSearch => 'Digita per cercare…';

  @override
  String removeItemAt(int position) => 'Rimuovi elemento ${number(position)}';

  @override
  String get noItemsYet => 'Ancora nessun elemento.';

  @override
  String get help => 'Aiuto';

  @override
  String helpFor(String field) => 'Aiuto per $field';

  @override
  String get versionHistory => 'Cronologia versioni';

  @override
  String get pendingEdit => 'Modifica in sospeso';

  /// The live value, valore, is masculine.
  @override
  String get baseline => 'Pubblicato';

  @override
  String editedDetail(String detail) => 'Modificato · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Commenti',
    one: '${number(count)} commento',
    other: '${number(count)} commenti',
  );

  @override
  String commentsHeading(int count) => 'Commenti · ${number(count)}';

  @override
  String get resolve => 'Risolvi';

  @override
  String get replyPlaceholder => 'Rispondi…';

  @override
  String get sendReply => 'Invia risposta';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Commenta questo campo',
    one: '${number(openThreads)} discussione aperta',
    other: '${number(openThreads)} discussioni aperte',
  );

  @override
  String get openThread => 'Apri discussione';

  @override
  String get translationSource => 'Originale';

  /// A translation is feminine.
  @override
  String get translationUpToDate => 'Aggiornata';

  @override
  String get translationNeedsReview => 'Da revisionare';

  /// A translation is feminine.
  @override
  String get translationOutdated => 'Obsoleta';

  @override
  String get translationMissing => 'Mancante';

  @override
  String get retranslate => 'Ritraduci';

  @override
  String retranslateLanguage(String language) => 'Ritraduci in $language';

  @override
  String get sourceChanged => 'L’originale è cambiato dopo la traduzione';

  @override
  String sourceIn(String language) => 'Originale in $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Lingue';

  @override
  String get languageMenuHint =>
      'Tocca per cambiare · spunta per confrontare fianco a fianco.';

  @override
  String compareLanguage(String language) => 'Confronta con $language';

  @override
  String switchToLanguage(String language) => 'Passa a $language';

  @override
  String get editing => 'in modifica';

  @override
  String get inherited => 'Ereditato';

  @override
  String get custom => 'Personalizzato';

  @override
  String inheritedDescription(String source) =>
      'Segue $source — si aggiorna automaticamente';

  @override
  String customDescription(String? noun) =>
      'Imposta il tuo ${noun ?? 'valore'}';

  @override
  String get valueRequired => 'Obbligatorio';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Inserisci almeno ${number(min)} carattere',
    other: 'Inserisci almeno ${number(min)} caratteri',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Inserisci al massimo ${number(max)} carattere',
    other: 'Inserisci al massimo ${number(max)} caratteri',
  );

  @override
  String get invalidEmail => 'Inserisci un indirizzo email valido';

  @override
  String get invalidUrl => 'Inserisci un indirizzo web valido';

  @override
  String get invalidFormat => 'Inserisci un valore nel formato previsto';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Aggiungi almeno ${number(count)} elemento',
    other: 'Aggiungi almeno ${number(count)} elementi',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Mantieni al massimo ${number(count)} elemento',
    other: 'Mantieni al massimo ${number(count)} elementi',
  );

  /// "Verifica…" alone would read as a button.
  @override
  String get checking => 'Verifica in corso…';

  @override
  String get optionalMarker => '(facoltativo)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} campo da correggere',
    other: '${number(count)} campi da correggere',
  );

  @override
  String jumpToField(String label) => 'Vai a $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Avanti';

  @override
  String get wizardBack => 'Indietro';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Correggi ${number(count)} campo per continuare',
    other: 'Correggi ${number(count)} campi per continuare',
  );
}
