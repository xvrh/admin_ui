import '../../sections/assets_messages.dart';

/// Dutch [AssetsMessages].
class AssetsMessagesNl extends AssetsMessages {
  const AssetsMessagesNl([super.localeName = 'nl']);

  @override
  String get assets => 'Mediabestanden';

  @override
  String get loadingAssets => 'Mediabestanden laden…';

  @override
  String get couldNotLoadAssets => 'Kan mediabestanden niet laden';

  @override
  String get noMatchingAssets => 'Geen overeenkomende mediabestanden';

  @override
  String get noMatchingAssetsHint =>
      'Probeer een andere zoekopdracht of een ander filter.';

  @override
  String get noAssetsYet => 'Nog geen mediabestanden';

  @override
  String get noAssetsYetHint =>
      'Upload afbeeldingen en bestanden om de bibliotheek te vullen.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} mediabestand',
    other: '${number(count)} mediabestanden',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} van ${assetCount(total)}';

  @override
  String get searchAssets => 'Mediabestanden zoeken';

  @override
  String get filterByType => 'Filteren op type';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Alle typen';

  @override
  String get typeImages => 'Afbeeldingen';

  @override
  String get typeVideos => 'Video’s';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Documenten';

  @override
  String get typeOther => 'Overig';

  @override
  String get kindImage => 'Afbeelding';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Document';

  @override
  String get kindOther => 'Overig';

  @override
  String get view => 'Weergave';

  @override
  String get gridView => 'Rasterweergave';

  @override
  String get listView => 'Lijstweergave';

  @override
  String get libraryTab => 'Bibliotheek';

  @override
  String get uploadTab => 'Uploaden';

  @override
  String get pickerTitle => 'Media kiezen';

  @override
  String get select => 'Selecteren';

  @override
  String get loadingMore => 'Meer laden…';

  @override
  String get dropToUpload => 'Neerzetten om te uploaden';

  @override
  String couldNotLoadMore(String reason) => 'Meer laden mislukt. $reason';

  @override
  String get uploadIncomplete =>
      'De upload is niet voltooid. Probeer het opnieuw.';

  @override
  String get asset => 'Mediabestand';

  @override
  String get type => 'Type';

  @override
  String get size => 'Grootte';

  @override
  String get dimensions => 'Afmetingen';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Alternatieve tekst';

  @override
  String get defaultAltText => 'Standaard alternatieve tekst';

  @override
  String get defaultAltTextHelp =>
      'Wordt overal gebruikt waar dit mediabestand verschijnt, tenzij die '
      'plek een eigen tekst heeft.';

  @override
  String get saveAltText => 'Alternatieve tekst opslaan';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'URL kopiëren';

  @override
  String get aspectFree => 'Vrij';

  @override
  String get imageUnavailable => 'Afbeelding niet beschikbaar';

  @override
  String get cropArea => 'Bijsnijgebied van afbeelding';

  @override
  String get cropAreaHint =>
      'Sleep de grepen om bij te snijden. Pijltoetsen verschuiven; houd Shift '
      'ingedrukt voor grotere stappen.';

  @override
  String get positionArea => 'Positiegebied van afbeelding';

  @override
  String get positionAreaHint =>
      'Sleep om te verplaatsen, scrol om te zoomen; pijltoetsen verschuiven.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Rechtzetten';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Linksom draaien';

  @override
  String get rotateRight => 'Rechtsom draaien';

  @override
  String get flipHorizontal => 'Horizontaal spiegelen';

  @override
  String get flipVertical => 'Verticaal spiegelen';

  @override
  String get useImage => 'Afbeelding gebruiken';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'De licentie voegt de afbeelding toe aan de bibliotheek en kost '
        '1 download',
    other:
        'De licentie voegt de afbeelding toe aan de bibliotheek en kost '
        '${number(downloads)} downloads',
  );

  @override
  String get selectImageToLicense =>
      'Selecteer een afbeelding voor een licentie';

  @override
  String get findStockImages => 'Stockafbeeldingen zoeken';

  @override
  String get noResultsHint =>
      'Probeer een andere zoekopdracht of verruim de filters.';

  @override
  String stockSearchPrompt(String provider) =>
      'Typ om miljoenen afbeeldingen op $provider te doorzoeken.';

  @override
  String providerResults(String provider) => 'Resultaten van $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} resultaat',
    other: '${number(count)} resultaten',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} van ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'Zoeken op $provider';

  @override
  String get orientation => 'Oriëntatie';

  @override
  String get anyOrientation => 'Alle oriëntaties';

  @override
  String get horizontal => 'Liggend';

  @override
  String get vertical => 'Staand';

  @override
  String get square => 'Vierkant';

  @override
  String get imageType => 'Type afbeelding';

  @override
  String get anyType => 'Alle typen';

  @override
  String get photos => 'Foto’s';

  @override
  String get illustrations => 'Illustraties';

  @override
  String get vectors => 'Vectorafbeeldingen';

  @override
  String licenseFrom(String provider) => 'Licentie via $provider';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Voegt de afbeelding toe aan de bibliotheek en kost 1 download van '
        'het $provider-abonnement.',
    other:
        'Voegt de afbeelding toe aan de bibliotheek en kost '
        '${number(downloads)} downloads van het $provider-abonnement.',
  );

  @override
  String get couldNotLicense => 'Kan geen licentie nemen voor deze afbeelding';

  @override
  String get licenseAndAdd => 'Licentie nemen en toevoegen';

  @override
  String get couldNotLoadSizes => 'Kan de formaten niet laden';

  @override
  String editItem(String name) => '$name bewerken';

  @override
  String get done => 'Klaar';

  @override
  String get couldNotLoadPreview => 'Kan het voorbeeld niet laden';

  @override
  String get uploading => 'Uploaden';

  @override
  String get replace => 'Vervangen';

  @override
  String get choose => 'Kiezen';

  @override
  String get editCrop => 'Bijsnijden bewerken';

  @override
  String get cropAndFocalPoint => 'Bijsnijden en focuspunt';

  @override
  String get imagesOnly => 'Alleen afbeeldingen';

  @override
  String get typeText => 'Tekst';

  /// A compound with a hyphen: Application-bestanden.
  @override
  String familyFiles(String family) => family.isEmpty
      ? 'Bestanden'
      : '${family[0].toUpperCase()}${family.substring(1)}-bestanden';

  @override
  String upTo(String size) => 'max. $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Kan $names niet toevoegen: het is geen afbeelding.',
    other: 'Kan $names niet toevoegen: het zijn geen afbeeldingen.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'Kan $names niet toevoegen: dit bestandstype wordt niet ondersteund.',
    other:
        'Kan $names niet toevoegen: deze bestandstypen worden niet '
        'ondersteund.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Kan $names niet toevoegen: het is groter dan $limit.',
    other: 'Kan $names niet toevoegen: ze zijn groter dan $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Kan $names niet toevoegen: het is een map.',
    other: 'Kan $names niet toevoegen: het zijn mappen.',
  );

  @override
  String refusedMixed(String items) => 'Kan $items niet toevoegen.';

  @override
  String refusedItemNotImage(String name) => '$name (geen afbeelding)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (bestandstype niet ondersteund)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (groter dan $limit)';

  @override
  String refusedItemFolder(String name) => '$name (een map)';
}
