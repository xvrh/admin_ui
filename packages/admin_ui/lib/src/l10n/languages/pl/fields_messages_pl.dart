import '../../sections/fields_messages.dart';

/// Polish [FieldsMessages].
class FieldsMessagesPl extends FieldsMessages {
  const FieldsMessagesPl([super.localeName = 'pl']);

  /// Low-high quotation marks, as Polish sets them.
  @override
  String quoted(String text) => '„$text”';

  @override
  String get filterOrAdd => 'Filtruj lub dodaj…';

  @override
  String maxSelected(int max) => 'Osiągnięto limit: ${number(max)}';

  @override
  String createOption(String value) => 'Utwórz ${quoted(value)}';

  @override
  String get onLabel => 'Włączone';

  @override
  String get offLabel => 'Wyłączone';

  @override
  String get selectDate => 'Wybierz datę…';

  @override
  String get selectDateTime => 'Wybierz datę i godzinę…';

  @override
  String get selectTime => 'Wybierz godzinę…';

  @override
  String get clearDate => 'Wyczyść datę';

  @override
  String get year => 'Rok';

  @override
  String get month => 'Miesiąc';

  @override
  String get day => 'Dzień';

  @override
  String get hour => 'Godzina';

  @override
  String get minute => 'Minuta';

  /// Rok, miesiąc, dzień, godzina, minuta.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'RRRR', month: 'MM', day: 'DD', hour: 'GG', minute: 'MM');

  @override
  String numberLike(String example) => 'Wpisz liczbę, np. $example';

  @override
  String numberBetween(String min, String max) =>
      'Wpisz liczbę od $min do $max';

  @override
  String numberAtLeast(String min) => 'Wpisz co najmniej $min';

  @override
  String numberAtMost(String max) => 'Wpisz co najwyżej $max';

  @override
  String get decrease => 'Zmniejsz';

  @override
  String get increase => 'Zwiększ';

  @override
  String get pickColor => 'Wybierz kolor…';

  @override
  String get hexDigitsError => 'Wpisz 3 lub 6 cyfr szesnastkowych';

  @override
  String get setColor => 'Ustaw';

  @override
  String get validJson => 'Prawidłowy JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      'Wiersz ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Formatuj';

  @override
  String get plainText => 'Zwykły tekst';

  @override
  String get addTag => 'Dodaj tag…';

  @override
  String get noTags => 'Brak tagów';

  @override
  String get noEntries => 'Brak wpisów';

  @override
  String duplicateKey(String key) =>
      'Powtórzony klucz ${quoted(key)} — obowiązuje niższy wiersz';

  @override
  String get duplicateKeys => 'Powtórzone klucze — obowiązuje niższy wiersz';

  @override
  String get removeRow => 'Usuń wiersz';

  @override
  String get noMedia => 'Brak zasobów';

  @override
  String retryItem(String name) => 'Ponów przesyłanie: $name';

  @override
  String cancelUpload(String name) => 'Anuluj przesyłanie: $name';

  @override
  String get cover => 'Okładka';

  @override
  String get processing => 'Przetwarzanie…';

  @override
  String get addImage => 'Dodaj obraz';

  @override
  String get addFile => 'Dodaj plik';

  @override
  String get noReference => 'Brak powiązania';

  /// A record is masculine.
  @override
  String get unavailable => 'Niedostępny';

  @override
  String get replaceReference => 'Zamień';

  @override
  String get typeToSearch => 'Wpisz, aby wyszukać…';

  @override
  String removeItemAt(int position) => 'Usuń element ${number(position)}';

  @override
  String get noItemsYet => 'Nie ma jeszcze elementów.';

  @override
  String get help => 'Pomoc';

  @override
  String helpFor(String field) => 'Pomoc: $field';

  @override
  String get versionHistory => 'Historia wersji';

  @override
  String get pendingEdit => 'Oczekująca zmiana';

  /// The published version, and a version is feminine.
  @override
  String get baseline => 'Opublikowana';

  @override
  String editedDetail(String detail) => 'Edytowano · $detail';

  @override
  String comments(int count) => plural(
    count,
    zero: 'Komentarze',
    one: '${number(count)} komentarz',
    few: '${number(count)} komentarze',
    many: '${number(count)} komentarzy',
    other: '${number(count)} komentarza',
  );

  @override
  String commentsHeading(int count) => 'Komentarze · ${number(count)}';

  @override
  String get resolve => 'Rozwiąż';

  @override
  String get replyPlaceholder => 'Odpowiedz…';

  @override
  String get sendReply => 'Wyślij odpowiedź';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Skomentuj to pole',
    one: '${number(openThreads)} otwarty wątek',
    few: '${number(openThreads)} otwarte wątki',
    many: '${number(openThreads)} otwartych wątków',
    other: '${number(openThreads)} otwartego wątku',
  );

  @override
  String get openThread => 'Otwórz wątek';

  @override
  String get translationSource => 'Źródło';

  /// A translation is neuter.
  @override
  String get translationUpToDate => 'Aktualne';

  @override
  String get translationNeedsReview => 'Do sprawdzenia';

  @override
  String get translationOutdated => 'Nieaktualne';

  @override
  String get translationMissing => 'Brak';

  @override
  String get retranslate => 'Przetłumacz ponownie';

  /// Language names are adjectives, the same after na as on their own.
  @override
  String retranslateLanguage(String language) =>
      'Przetłumacz ponownie na $language';

  @override
  String get sourceChanged => 'Źródło zmieniło się od czasu tłumaczenia';

  @override
  String sourceIn(String language) => 'Źródło: $language';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Języki';

  @override
  String get languageMenuHint =>
      'Dotknij, aby przełączyć · zaznacz, aby porównać obok siebie.';

  @override
  String compareLanguage(String language) => 'Porównaj: $language';

  @override
  String switchToLanguage(String language) => 'Przełącz na $language';

  /// A language is masculine.
  @override
  String get editing => 'edytowany';

  /// A value is feminine.
  @override
  String get inherited => 'Dziedziczona';

  @override
  String get custom => 'Własna';

  @override
  String inheritedDescription(String source) =>
      'Jak w źródle ($source) — aktualizuje się automatycznie';

  /// The noun stands after a colon, where it keeps the form the app gives.
  @override
  String customDescription(String? noun) =>
      noun == null ? 'Ustaw własną wartość' : 'Ustaw własną wartość: $noun';

  @override
  String get valueRequired => 'Wymagane';

  @override
  String tooShort(int min) => plural(
    min,
    one: 'Wpisz co najmniej ${number(min)} znak',
    few: 'Wpisz co najmniej ${number(min)} znaki',
    many: 'Wpisz co najmniej ${number(min)} znaków',
    other: 'Wpisz co najmniej ${number(min)} znaku',
  );

  @override
  String tooLong(int max) => plural(
    max,
    one: 'Wpisz co najwyżej ${number(max)} znak',
    few: 'Wpisz co najwyżej ${number(max)} znaki',
    many: 'Wpisz co najwyżej ${number(max)} znaków',
    other: 'Wpisz co najwyżej ${number(max)} znaku',
  );

  @override
  String get invalidEmail => 'Wpisz prawidłowy adres e-mail';

  @override
  String get invalidUrl => 'Wpisz prawidłowy adres internetowy';

  @override
  String get invalidFormat => 'Wpisz wartość w oczekiwanym formacie';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) => plural(
    count,
    one: 'Dodaj co najmniej ${number(count)} element',
    few: 'Dodaj co najmniej ${number(count)} elementy',
    many: 'Dodaj co najmniej ${number(count)} elementów',
    other: 'Dodaj co najmniej ${number(count)} elementu',
  );

  @override
  String keepAtMost(int count) => plural(
    count,
    one: 'Pozostaw co najwyżej ${number(count)} element',
    few: 'Pozostaw co najwyżej ${number(count)} elementy',
    many: 'Pozostaw co najwyżej ${number(count)} elementów',
    other: 'Pozostaw co najwyżej ${number(count)} elementu',
  );

  @override
  String get checking => 'Sprawdzanie…';

  @override
  String get optionalMarker => '(opcjonalnie)';

  @override
  String validationSummaryTitle(int count) => plural(
    count,
    one: '${number(count)} pole wymaga poprawy',
    few: '${number(count)} pola wymagają poprawy',
    many: '${number(count)} pól wymaga poprawy',
    other: '${number(count)} pola wymaga poprawy',
  );

  @override
  String jumpToField(String label) => 'Przejdź do pola $label';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'Dalej';

  @override
  String get wizardBack => 'Wstecz';

  @override
  String wizardStepBlocked(int count) => plural(
    count,
    one: 'Popraw ${number(count)} pole, aby kontynuować',
    few: 'Popraw ${number(count)} pola, aby kontynuować',
    many: 'Popraw ${number(count)} pól, aby kontynuować',
    other: 'Popraw ${number(count)} pola, aby kontynuować',
  );
}
