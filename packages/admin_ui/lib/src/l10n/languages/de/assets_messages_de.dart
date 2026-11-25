import '../../sections/assets_messages.dart';

/// German [AssetsMessages].
class AssetsMessagesDe extends AssetsMessages {
  const AssetsMessagesDe([super.localeName = 'de']);

  @override
  String get assets => 'Mediendateien';

  @override
  String get loadingAssets => 'Mediendateien werden geladen…';

  @override
  String get couldNotLoadAssets => 'Mediendateien konnten nicht geladen werden';

  @override
  String get noMatchingAssets => 'Keine passenden Mediendateien';

  @override
  String get noMatchingAssetsHint =>
      'Versuchen Sie eine andere Suche oder einen anderen Filter.';

  @override
  String get noAssetsYet => 'Noch keine Mediendateien';

  @override
  String get noAssetsYetHint =>
      'Laden Sie Bilder und Dateien hoch, um Ihre Mediathek aufzubauen.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} Mediendatei',
    other: '${number(count)} Mediendateien',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} von ${assetCount(total)}';

  @override
  String get searchAssets => 'Mediendateien durchsuchen';

  @override
  String get filterByType => 'Nach Typ filtern';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Alle Typen';

  @override
  String get typeImages => 'Bilder';

  @override
  String get typeVideos => 'Videos';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Dokumente';

  @override
  String get typeOther => 'Sonstige';

  @override
  String get kindImage => 'Bild';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Dokument';

  @override
  String get kindOther => 'Sonstiges';

  @override
  String get view => 'Darstellung';

  @override
  String get gridView => 'Rasteransicht';

  @override
  String get listView => 'Listenansicht';

  @override
  String get libraryTab => 'Mediathek';

  @override
  String get uploadTab => 'Hochladen';

  @override
  String get pickerTitle => 'Mediendatei auswählen';

  @override
  String get select => 'Auswählen';

  @override
  String get loadingMore => 'Weitere werden geladen…';

  @override
  String get dropToUpload => 'Zum Hochladen ablegen';

  @override
  String couldNotLoadMore(String reason) =>
      'Weitere konnten nicht geladen werden. $reason';

  @override
  String get uploadIncomplete =>
      'Der Upload wurde nicht abgeschlossen. Versuchen Sie es erneut.';

  @override
  String get asset => 'Mediendatei';

  @override
  String get type => 'Typ';

  @override
  String get size => 'Größe';

  @override
  String get dimensions => 'Abmessungen';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Alternativtext';

  @override
  String get defaultAltText => 'Standard-Alternativtext';

  @override
  String get defaultAltTextHelp =>
      'Wird überall verwendet, wo diese Mediendatei erscheint, sofern er dort '
      'nicht überschrieben wird.';

  @override
  String get saveAltText => 'Alternativtext speichern';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'URL kopieren';

  @override
  String get aspectFree => 'Frei';

  @override
  String get imageUnavailable => 'Bild nicht verfügbar';

  @override
  String get cropArea => 'Zuschnittbereich des Bilds';

  @override
  String get cropAreaHint =>
      'Zum Zuschneiden die Griffe ziehen. Pfeiltasten verschieben '
      'schrittweise; mit gedrückter Umschalttaste in größeren Schritten.';

  @override
  String get positionArea => 'Positionierungsbereich des Bilds';

  @override
  String get positionAreaHint =>
      'Zum Positionieren ziehen, zum Zoomen scrollen; Pfeiltasten verschieben '
      'schrittweise.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Begradigen';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Nach links drehen';

  @override
  String get rotateRight => 'Nach rechts drehen';

  @override
  String get flipHorizontal => 'Horizontal spiegeln';

  @override
  String get flipVertical => 'Vertikal spiegeln';

  @override
  String get useImage => 'Bild verwenden';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'Die Lizenzierung fügt das Bild Ihrer Mediathek hinzu und verbraucht '
        '1 Download',
    other:
        'Die Lizenzierung fügt das Bild Ihrer Mediathek hinzu und verbraucht '
        '${number(downloads)} Downloads',
  );

  @override
  String get selectImageToLicense => 'Bild zum Lizenzieren auswählen';

  @override
  String get findStockImages => 'Stockbilder suchen';

  @override
  String get noResultsHint =>
      'Versuchen Sie eine andere Suche oder lockern Sie die Filter.';

  @override
  String stockSearchPrompt(String provider) =>
      'Suchbegriff eingeben, um Millionen Bilder auf $provider zu durchsuchen.';

  @override
  String providerResults(String provider) => 'Ergebnisse von $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} Ergebnis',
    other: '${number(count)} Ergebnisse',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} von ${resultCount(total)}';

  @override
  String searchProvider(String provider) => '$provider durchsuchen';

  @override
  String get orientation => 'Ausrichtung';

  @override
  String get anyOrientation => 'Alle Ausrichtungen';

  @override
  String get horizontal => 'Querformat';

  @override
  String get vertical => 'Hochformat';

  @override
  String get square => 'Quadratisch';

  @override
  String get imageType => 'Bildtyp';

  @override
  String get anyType => 'Alle Typen';

  @override
  String get photos => 'Fotos';

  @override
  String get illustrations => 'Illustrationen';

  @override
  String get vectors => 'Vektorgrafiken';

  @override
  String licenseFrom(String provider) => 'Bei $provider lizenzieren';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Fügt das Bild Ihrer Mediathek hinzu und verbraucht 1 Download Ihres '
        '$provider-Tarifs.',
    other:
        'Fügt das Bild Ihrer Mediathek hinzu und verbraucht '
        '${number(downloads)} Downloads Ihres $provider-Tarifs.',
  );

  @override
  String get couldNotLicense => 'Bild konnte nicht lizenziert werden';

  @override
  String get licenseAndAdd => 'Lizenzieren und hinzufügen';

  @override
  String get couldNotLoadSizes => 'Größen konnten nicht geladen werden';

  @override
  String editItem(String name) => '$name bearbeiten';

  @override
  String get done => 'Fertig';

  @override
  String get couldNotLoadPreview => 'Vorschau konnte nicht geladen werden';

  @override
  String get uploading => 'Wird hochgeladen';

  @override
  String get replace => 'Ersetzen';

  @override
  String get choose => 'Auswählen';

  @override
  String get editCrop => 'Zuschnitt bearbeiten';

  @override
  String get cropAndFocalPoint => 'Zuschnitt und Fokuspunkt';

  @override
  String get imagesOnly => 'Nur Bilder';

  @override
  String get typeText => 'Text';

  /// The family as a capitalized noun in a hyphenated compound:
  /// Application-Dateien.
  @override
  String familyFiles(String family) => family.isEmpty
      ? 'Dateien'
      : '${family[0].toUpperCase()}${family.substring(1)}-Dateien';

  @override
  String upTo(String size) => 'bis zu $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Hinzufügen nicht möglich: $names ist kein Bild.',
    other: 'Hinzufügen nicht möglich: $names sind keine Bilder.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one:
        'Hinzufügen nicht möglich: Der Dateityp von $names wird nicht '
        'unterstützt.',
    other:
        'Hinzufügen nicht möglich: Die Dateitypen von $names werden nicht '
        'unterstützt.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Hinzufügen nicht möglich: $names ist größer als $limit.',
    other: 'Hinzufügen nicht möglich: $names sind größer als $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Hinzufügen nicht möglich: $names ist ein Ordner.',
    other: 'Hinzufügen nicht möglich: $names sind Ordner.',
  );

  @override
  String refusedMixed(String items) => 'Hinzufügen nicht möglich: $items.';

  @override
  String refusedItemNotImage(String name) => '$name (kein Bild)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (Dateityp nicht unterstützt)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (größer als $limit)';

  @override
  String refusedItemFolder(String name) => '$name (Ordner)';
}
