import '../../sections/assets_messages.dart';

/// Polish [AssetsMessages].
class AssetsMessagesPl extends AssetsMessages {
  const AssetsMessagesPl([super.localeName = 'pl']);

  @override
  String get assets => 'Zasoby';

  @override
  String get loadingAssets => 'Ładowanie zasobów…';

  @override
  String get couldNotLoadAssets => 'Nie udało się załadować zasobów';

  @override
  String get noMatchingAssets => 'Brak pasujących zasobów';

  @override
  String get noMatchingAssetsHint => 'Spróbuj innego wyszukiwania lub filtra.';

  @override
  String get noAssetsYet => 'Nie ma jeszcze zasobów';

  @override
  String get noAssetsYetHint =>
      'Prześlij obrazy i pliki, aby utworzyć bibliotekę.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} zasób',
    few: '${number(count)} zasoby',
    many: '${number(count)} zasobów',
    other: '${number(count)} zasobu',
  );

  /// After z the noun takes the genitive, which the forms of [assetCount]
  /// are not: 2 z 3 zasobów.
  @override
  String assetsShown(int shown, int total) => plural(
    total,
    one: '${number(shown)} z ${number(total)} zasobu',
    few: '${number(shown)} z ${number(total)} zasobów',
    many: '${number(shown)} z ${number(total)} zasobów',
    other: '${number(shown)} z ${number(total)} zasobu',
  );

  @override
  String get searchAssets => 'Szukaj zasobów';

  @override
  String get filterByType => 'Filtruj według typu';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Wszystkie typy';

  @override
  String get typeImages => 'Obrazy';

  @override
  String get typeVideos => 'Wideo';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Dokumenty';

  @override
  String get typeOther => 'Inne';

  @override
  String get kindImage => 'Obraz';

  @override
  String get kindVideo => 'Wideo';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Dokument';

  /// A type is masculine.
  @override
  String get kindOther => 'Inny';

  @override
  String get view => 'Widok';

  @override
  String get gridView => 'Widok siatki';

  @override
  String get listView => 'Widok listy';

  @override
  String get libraryTab => 'Biblioteka';

  @override
  String get uploadTab => 'Przesyłanie';

  @override
  String get pickerTitle => 'Wybierz zasób';

  @override
  String get select => 'Wybierz';

  @override
  String get loadingMore => 'Ładowanie kolejnych…';

  @override
  String get dropToUpload => 'Upuść, aby przesłać';

  @override
  String couldNotLoadMore(String reason) =>
      'Nie udało się załadować kolejnych. $reason';

  @override
  String get uploadIncomplete =>
      'Przesyłanie nie zostało ukończone. Spróbuj ponownie.';

  @override
  String get asset => 'Zasób';

  @override
  String get type => 'Typ';

  @override
  String get size => 'Rozmiar';

  @override
  String get dimensions => 'Wymiary';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Tekst alternatywny';

  @override
  String get defaultAltText => 'Domyślny tekst alternatywny';

  @override
  String get defaultAltTextHelp =>
      'Używany wszędzie, gdzie pojawia się ten zasób, chyba że zostanie '
      'zastąpiony w miejscu użycia.';

  @override
  String get saveAltText => 'Zapisz tekst alternatywny';

  @override
  String get url => 'Adres URL';

  @override
  String get copyUrl => 'Kopiuj adres URL';

  /// Proportions are plural.
  @override
  String get aspectFree => 'Dowolne';

  @override
  String get imageUnavailable => 'Obraz niedostępny';

  @override
  String get cropArea => 'Obszar kadrowania obrazu';

  @override
  String get cropAreaHint =>
      'Przeciągnij uchwyty, aby wykadrować. Strzałki przesuwają o mały krok; '
      'przytrzymaj Shift, aby przesuwać o większy.';

  @override
  String get positionArea => 'Obszar pozycjonowania obrazu';

  @override
  String get positionAreaHint =>
      'Przeciągnij, aby zmienić położenie, przewiń, aby powiększyć; strzałki '
      'przesuwają o mały krok.';

  @override
  String get zoom => 'Powiększenie';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Wyprostuj';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Obróć w lewo';

  @override
  String get rotateRight => 'Obróć w prawo';

  @override
  String get flipHorizontal => 'Odbij w poziomie';

  @override
  String get flipVertical => 'Odbij w pionie';

  @override
  String get useImage => 'Użyj obrazu';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'Uzyskanie licencji doda obraz do biblioteki i wykorzysta '
        '${number(downloads)} pobranie',
    few:
        'Uzyskanie licencji doda obraz do biblioteki i wykorzysta '
        '${number(downloads)} pobrania',
    many:
        'Uzyskanie licencji doda obraz do biblioteki i wykorzysta '
        '${number(downloads)} pobrań',
    other:
        'Uzyskanie licencji doda obraz do biblioteki i wykorzysta '
        '${number(downloads)} pobrania',
  );

  @override
  String get selectImageToLicense => 'Wybierz obraz, aby uzyskać licencję';

  @override
  String get findStockImages => 'Znajdź obrazy stockowe';

  @override
  String get noResultsHint => 'Spróbuj innego wyszukiwania lub złagodź filtry.';

  @override
  String stockSearchPrompt(String provider) =>
      'Wpisz zapytanie, aby przeszukać miliony obrazów w serwisie $provider.';

  @override
  String providerResults(String provider) => 'Wyniki z serwisu $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} wynik',
    few: '${number(count)} wyniki',
    many: '${number(count)} wyników',
    other: '${number(count)} wyniku',
  );

  /// After z the noun takes the genitive, which the forms of [resultCount]
  /// are not: 2 z 3 wyników.
  @override
  String resultsShown(int shown, int total) => plural(
    total,
    one: '${number(shown)} z ${number(total)} wyniku',
    few: '${number(shown)} z ${number(total)} wyników',
    many: '${number(shown)} z ${number(total)} wyników',
    other: '${number(shown)} z ${number(total)} wyniku',
  );

  @override
  String searchProvider(String provider) => 'Szukaj w serwisie $provider';

  @override
  String get orientation => 'Orientacja';

  @override
  String get anyOrientation => 'Dowolna orientacja';

  /// An orientation is feminine.
  @override
  String get horizontal => 'Pozioma';

  @override
  String get vertical => 'Pionowa';

  @override
  String get square => 'Kwadratowa';

  @override
  String get imageType => 'Typ obrazu';

  @override
  String get anyType => 'Dowolny typ';

  @override
  String get photos => 'Zdjęcia';

  @override
  String get illustrations => 'Ilustracje';

  @override
  String get vectors => 'Grafiki wektorowe';

  @override
  String licenseFrom(String provider) => 'Licencja z serwisu $provider';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Dodaje obraz do biblioteki i wykorzystuje ${number(downloads)} '
        'pobranie z planu $provider.',
    few:
        'Dodaje obraz do biblioteki i wykorzystuje ${number(downloads)} '
        'pobrania z planu $provider.',
    many:
        'Dodaje obraz do biblioteki i wykorzystuje ${number(downloads)} '
        'pobrań z planu $provider.',
    other:
        'Dodaje obraz do biblioteki i wykorzystuje ${number(downloads)} '
        'pobrania z planu $provider.',
  );

  @override
  String get couldNotLicense => 'Nie udało się uzyskać licencji na ten obraz';

  @override
  String get licenseAndAdd => 'Uzyskaj licencję i dodaj';

  @override
  String get couldNotLoadSizes => 'Nie udało się załadować rozmiarów';

  @override
  String editItem(String name) => 'Edytuj: $name';

  @override
  String get done => 'Gotowe';

  @override
  String get couldNotLoadPreview => 'Nie udało się załadować podglądu';

  @override
  String get uploading => 'Przesyłanie';

  @override
  String get replace => 'Zamień';

  @override
  String get choose => 'Wybierz';

  @override
  String get editCrop => 'Edytuj kadrowanie';

  @override
  String get cropAndFocalPoint => 'Kadrowanie i punkt centralny';

  @override
  String get imagesOnly => 'Tylko obrazy';

  @override
  String get typeText => 'Tekst';

  /// The MIME family stays as written, after typu.
  @override
  String familyFiles(String family) =>
      family.isEmpty ? 'Pliki' : 'Pliki typu $family';

  @override
  String upTo(String size) => 'do $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Nie udało się dodać $names: to nie jest obraz.',
    other: 'Nie udało się dodać $names: to nie są obrazy.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'Nie udało się dodać $names: ten typ pliku nie jest obsługiwany.',
    other: 'Nie udało się dodać $names: te typy plików nie są obsługiwane.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Nie udało się dodać $names: plik jest większy niż $limit.',
    other: 'Nie udało się dodać $names: pliki są większe niż $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Nie udało się dodać $names: to folder.',
    other: 'Nie udało się dodać $names: to foldery.',
  );

  @override
  String refusedMixed(String items) => 'Nie udało się dodać: $items.';

  @override
  String refusedItemNotImage(String name) => '$name (nie jest obrazem)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (nieobsługiwany typ pliku)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (większy niż $limit)';

  @override
  String refusedItemFolder(String name) => '$name (folder)';
}
