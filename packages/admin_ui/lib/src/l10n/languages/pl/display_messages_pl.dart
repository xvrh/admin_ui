import '../../sections/display_messages.dart';

/// Polish [DisplayMessages].
class DisplayMessagesPl extends DisplayMessages {
  const DisplayMessagesPl([super.localeName = 'pl']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Ładowanie';

  @override
  String get errorTimeout =>
      'Serwer zbyt długo nie odpowiadał. Spróbuj ponownie.';

  @override
  String get errorUnreachable =>
      'Nie można połączyć się z serwerem. Sprawdź połączenie i spróbuj '
      'ponownie.';

  @override
  String get errorUnreadable =>
      'Nie udało się odczytać odpowiedzi serwera. Spróbuj ponownie.';

  @override
  String get errorUnauthorized =>
      'Sesja wygasła. Zaloguj się i spróbuj ponownie.';

  @override
  String get errorPaymentRequired =>
      'Ta operacja wymaga płatnego planu lub dodatkowych środków.';

  @override
  String get errorForbidden => 'Brak uprawnień do wykonania tej operacji.';

  @override
  String get errorNotFound =>
      'Nie znaleziono. Element mógł zostać przeniesiony lub usunięty.';

  @override
  String get errorConflict =>
      'Element został zmieniony w innym miejscu. Odśwież i spróbuj ponownie.';

  @override
  String get errorTooLarge =>
      'Przekroczono maksymalny rozmiar akceptowany przez serwer.';

  @override
  String get errorRateLimited =>
      'Zbyt wiele żądań. Odczekaj chwilę i spróbuj ponownie.';

  @override
  String get errorServer =>
      'Wystąpił problem z serwerem. Spróbuj ponownie za chwilę.';

  @override
  String get errorRequestFailed => 'Serwer nie mógł zrealizować żądania.';

  @override
  String get breadcrumb => 'Ścieżka nawigacji';

  @override
  String currentPage(String label) => '$label, bieżąca strona';

  @override
  String get switchPage => 'Przełącz stronę';

  @override
  String showMore(int count) =>
      plural(count, other: 'Pokaż jeszcze ${number(count)}');

  @override
  String pageNumber(int page) => 'Strona ${number(page)}';

  @override
  String jsonKeys(int count) => plural(
    count,
    one: '${number(count)} klucz',
    few: '${number(count)} klucze',
    many: '${number(count)} kluczy',
    other: '${number(count)} klucza',
  );

  @override
  String jsonItems(int count) => plural(
    count,
    one: '${number(count)} element',
    few: '${number(count)} elementy',
    many: '${number(count)} elementów',
    other: '${number(count)} elementu',
  );

  @override
  String get expandAll => 'Rozwiń wszystko';

  @override
  String get collapseAll => 'Zwiń wszystko';

  @override
  String get copyJson => 'Kopiuj JSON';

  @override
  String get copyValue => 'Kopiuj wartość';

  @override
  String get copyPath => 'Kopiuj ścieżkę';

  @override
  String invalidJson(String detail) => 'Nieprawidłowy JSON — $detail';

  @override
  String get logEmpty => 'Brak danych wyjściowych';

  @override
  String get zoomArea => 'Obszar powiększania';

  @override
  String get zoomAreaHint =>
      'Przewiń, aby powiększyć, przeciągnij, aby przesunąć; + i − zmieniają '
      'powiększenie, 0 dopasowuje, strzałki przesuwają.';

  @override
  String get zoomIn => 'Powiększ';

  @override
  String get zoomOut => 'Pomniejsz';

  @override
  String get zoomToFit => 'Dopasuj do widoku';

  @override
  String get qrCode => 'Kod QR';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Przesyłanie zakończone',
    few: 'Przesłano wszystkie ${number(total)} pliki',
    many: 'Przesłano wszystkie ${number(total)} plików',
    other: 'Przesłano ${number(total)} pliku',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? 'Przesłano ${number(done)} z ${number(total)}'
      : plural(
          failed,
          one:
              'Przesłano ${number(done)} z ${number(total)} · '
              '${number(failed)} błąd',
          few:
              'Przesłano ${number(done)} z ${number(total)} · '
              '${number(failed)} błędy',
          many:
              'Przesłano ${number(done)} z ${number(total)} · '
              '${number(failed)} błędów',
          other:
              'Przesłano ${number(done)} z ${number(total)} · '
              '${number(failed)} błędu',
        );

  @override
  String get clearCompleted => 'Wyczyść zakończone';

  @override
  String get queued => 'W kolejce';

  @override
  String get retryUpload => 'Ponów przesyłanie';

  @override
  String get removeFile => 'Usuń plik';

  @override
  String get cancelUpload => 'Anuluj przesyłanie';

  @override
  String get chartEmpty => 'Brak danych za ten okres';

  @override
  String get heatLess => 'Mniej';

  @override
  String get heatMore => 'Więcej';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => 'wzrost o $delta';

  @override
  String trendDown(String delta) => 'spadek o $delta';

  @override
  String get needsAttention => 'Wymaga uwagi';

  @override
  String get recentActivity => 'Ostatnia aktywność';

  @override
  String get contentMix => 'Podział treści';

  @override
  String itemsUnit(int count) => plural(
    count,
    one: 'element',
    few: 'elementy',
    many: 'elementów',
    other: 'elementu',
  );

  @override
  String get allCaughtUp => 'Wszystko na bieżąco — nic nie wymaga uwagi.';

  @override
  String get noRecentActivity => 'Brak ostatniej aktywności';

  @override
  String get noRecentActivityHint =>
      'Tutaj pojawią się zmiany, publikacje i przesłane pliki.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Krok ${number(step)} z ${number(total)}: $title';

  /// Adjectives agreeing with krok.
  @override
  String get stepCompleted => 'ukończony';

  @override
  String get stepCurrent => 'bieżący';

  @override
  String get stepUpcoming => 'nadchodzący';

  @override
  String get stepError => 'błąd';

  @override
  String get addItem => 'Dodaj element';

  @override
  String get untitled => 'Bez tytułu';

  @override
  String get treeHeader => 'Grupa';

  @override
  String get indent => 'Zwiększ wcięcie';

  @override
  String get outdent => 'Zmniejsz wcięcie';

  @override
  String get addChild => 'Dodaj element podrzędny';

  @override
  String get hideEntry => 'Ukryj';

  @override
  String get showEntry => 'Pokaż';

  /// Impersonal, so the verb agrees with no title.
  @override
  String movedUp(String title) => 'Przeniesiono w górę: $title';

  @override
  String movedDown(String title) => 'Przeniesiono w dół: $title';

  @override
  String indented(String title) => 'Zwiększono wcięcie: $title';

  @override
  String outdented(String title) => 'Zmniejszono wcięcie: $title';

  @override
  String get rowMovedUp => 'Przeniesiono w górę';

  @override
  String get rowMovedDown => 'Przeniesiono w dół';

  @override
  String get rowIndented => 'Zwiększono wcięcie';

  @override
  String get rowOutdented => 'Zmniejszono wcięcie';

  @override
  String get resizePanes => 'Zmień rozmiar paneli';

  @override
  String get moveLeft => 'Przesuń w lewo';

  @override
  String get moveRight => 'Przesuń w prawo';

  @override
  String get preview => 'Podgląd';

  @override
  String get previewHeading => 'PODGLĄD';

  @override
  String get noPreviewHeading => 'BRAK PODGLĄDU';

  @override
  String get insertsInline =>
      'Wstawiany w tekście — podgląd nie jest potrzebny.';

  @override
  String nothingMatches(String query) => 'Nic nie pasuje do „$query”';

  @override
  String get choices => 'Opcje';

  @override
  String get diffAdded => 'Dodano';

  @override
  String get diffRemoved => 'Usunięto';

  @override
  String get diffChanged => 'Zmieniono';

  @override
  String get diffMoved => 'Przeniesiono';

  @override
  String get diffUnchanged => 'Bez zmian';

  /// Impersonal, so the count agrees with no noun.
  @override
  String addedCount(int count) => 'Dodano: ${number(count)}';

  @override
  String removedCount(int count) => 'Usunięto: ${number(count)}';

  @override
  String changedCount(int count) => 'Zmieniono: ${number(count)}';

  @override
  String movedCount(int count) => 'Przeniesiono: ${number(count)}';

  @override
  String get before => 'Przed';

  @override
  String get after => 'Po';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      'z pozycji ${number(from)} na ${number(to)}';

  @override
  String get unified => 'Ujednolicony';

  @override
  String get split => 'Obok siebie';

  @override
  String get noChanges => 'Brak zmian';

  @override
  String get versionsIdentical => 'Te dwie wersje są identyczne.';

  @override
  String get noFieldChanges => 'Brak zmian w polach.';

  @override
  String get noBlockChanges => 'Brak zmian w blokach.';

  @override
  String get empty => 'Puste';

  @override
  String inserted(String text) => 'wstawiono: $text, ';

  @override
  String deleted(String text) => 'usunięto: $text, ';

  @override
  String get restore => 'Przywróć';

  @override
  String get restoreThisVersion => 'Przywróć tę wersję';

  @override
  String get restoreThisField => 'Przywróć to pole';

  @override
  String get restoreThisItem => 'Przywróć ten element';

  @override
  String get restoreLiveBlock => 'Przywróć opublikowaną wersję tego bloku';

  @override
  String get sharedLane => 'Wspólne';

  /// Adjectives agreeing with wersja.
  @override
  String get versionCurrent => 'Bieżąca';

  @override
  String get versionPublished => 'Opublikowana';

  @override
  String get versionRestored => 'Przywrócona';

  @override
  String get versionArchived => 'Zarchiwizowana';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Osoby do oznaczenia';

  @override
  String mentionMatches(int count) => plural(
    count,
    one: '${number(count)} osoba do oznaczenia',
    few: '${number(count)} osoby do oznaczenia',
    many: '${number(count)} osób do oznaczenia',
    other: '${number(count)} osoby do oznaczenia',
  );
}
