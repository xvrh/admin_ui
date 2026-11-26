import '../../sections/assets_messages.dart';

/// Italian [AssetsMessages].
class AssetsMessagesIt extends AssetsMessages {
  const AssetsMessagesIt([super.localeName = 'it']);

  @override
  String get assets => 'Risorse';

  @override
  String get loadingAssets => 'Caricamento delle risorse…';

  @override
  String get couldNotLoadAssets => 'Impossibile caricare le risorse';

  @override
  String get noMatchingAssets => 'Nessuna risorsa corrispondente';

  @override
  String get noMatchingAssetsHint =>
      'Prova con un’altra ricerca o un altro filtro.';

  @override
  String get noAssetsYet => 'Ancora nessuna risorsa';

  @override
  String get noAssetsYetHint =>
      'Carica immagini e file per creare la tua libreria.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} risorsa',
    other: '${number(count)} risorse',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} di ${assetCount(total)}';

  @override
  String get searchAssets => 'Cerca risorse';

  @override
  String get filterByType => 'Filtra per tipo';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Tutti i tipi';

  @override
  String get typeImages => 'Immagini';

  @override
  String get typeVideos => 'Video';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Documenti';

  @override
  String get typeOther => 'Altro';

  @override
  String get kindImage => 'Immagine';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Documento';

  @override
  String get kindOther => 'Altro';

  @override
  String get view => 'Visualizzazione';

  @override
  String get gridView => 'Vista griglia';

  @override
  String get listView => 'Vista elenco';

  @override
  String get libraryTab => 'Libreria';

  @override
  String get uploadTab => 'Carica';

  @override
  String get pickerTitle => 'Scegli risorse';

  @override
  String get select => 'Seleziona';

  @override
  String get loadingMore => 'Caricamento di altri elementi…';

  @override
  String get dropToUpload => 'Rilascia per caricare';

  @override
  String couldNotLoadMore(String reason) =>
      'Impossibile caricare altri elementi. $reason';

  @override
  String get uploadIncomplete =>
      'Il caricamento non è stato completato. Riprova.';

  @override
  String get asset => 'Risorsa';

  @override
  String get type => 'Tipo';

  /// Singular, as a file's size: "Dimensioni" is [dimensions].
  @override
  String get size => 'Dimensione';

  @override
  String get dimensions => 'Dimensioni in pixel';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Testo alternativo';

  @override
  String get defaultAltText => 'Testo alternativo predefinito';

  @override
  String get defaultAltTextHelp =>
      'Usato ovunque compaia questa risorsa, salvo se sostituito nel punto '
      'in cui è usata.';

  @override
  String get saveAltText => 'Salva testo alternativo';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'Copia URL';

  @override
  String get aspectFree => 'Libero';

  @override
  String get imageUnavailable => 'Immagine non disponibile';

  @override
  String get cropArea => 'Area di ritaglio dell’immagine';

  @override
  String get cropAreaHint =>
      'Trascina le maniglie per ritagliare. Le frecce spostano di poco; tieni '
      'premuto Maiusc per spostamenti più ampi.';

  @override
  String get positionArea => 'Area di posizionamento dell’immagine';

  @override
  String get positionAreaHint =>
      'Trascina per riposizionare, scorri per lo zoom; le frecce spostano di '
      'poco.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Raddrizza';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Ruota a sinistra';

  @override
  String get rotateRight => 'Ruota a destra';

  @override
  String get flipHorizontal => 'Capovolgi orizzontalmente';

  @override
  String get flipVertical => 'Capovolgi verticalmente';

  @override
  String get useImage => 'Usa immagine';

  /// "Download" does not change in the plural.
  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    other:
        'Ottenere la licenza aggiunge l’immagine alla tua libreria e consuma '
        '${number(downloads)} download',
  );

  @override
  String get selectImageToLicense =>
      'Seleziona un’immagine per ottenerne la licenza';

  @override
  String get findStockImages => 'Trova immagini di repertorio';

  @override
  String get noResultsHint => 'Prova con un’altra ricerca o riduci i filtri.';

  @override
  String stockSearchPrompt(String provider) =>
      'Digita per cercare tra milioni di immagini su $provider.';

  @override
  String providerResults(String provider) => 'Risultati di $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} risultato',
    other: '${number(count)} risultati',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} di ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'Cerca su $provider';

  @override
  String get orientation => 'Orientamento';

  @override
  String get anyOrientation => 'Qualsiasi orientamento';

  @override
  String get horizontal => 'Orizzontale';

  @override
  String get vertical => 'Verticale';

  @override
  String get square => 'Quadrato';

  @override
  String get imageType => 'Tipo di immagine';

  @override
  String get anyType => 'Qualsiasi tipo';

  @override
  String get photos => 'Foto';

  @override
  String get illustrations => 'Illustrazioni';

  @override
  String get vectors => 'Vettoriali';

  @override
  String licenseFrom(String provider) => 'Ottieni la licenza da $provider';

  /// "Download" does not change in the plural.
  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    other:
        'Aggiunge l’immagine alla tua libreria e consuma '
        '${number(downloads)} download del tuo piano $provider.',
  );

  @override
  String get couldNotLicense =>
      'Impossibile ottenere la licenza per questa immagine';

  @override
  String get licenseAndAdd => 'Ottieni licenza e aggiungi';

  @override
  String get couldNotLoadSizes => 'Impossibile caricare le dimensioni';

  @override
  String editItem(String name) => 'Modifica $name';

  @override
  String get done => 'Fine';

  @override
  String get couldNotLoadPreview => 'Impossibile caricare l’anteprima';

  @override
  String get uploading => 'Caricamento in corso';

  @override
  String get replace => 'Sostituisci';

  @override
  String get choose => 'Scegli';

  @override
  String get editCrop => 'Modifica ritaglio';

  @override
  String get cropAndFocalPoint => 'Ritaglio e punto focale';

  @override
  String get imagesOnly => 'Solo immagini';

  @override
  String get typeText => 'Testo';

  /// Italian puts the noun first, so [family] keeps its MIME spelling.
  @override
  String familyFiles(String family) => family.isEmpty ? 'File' : 'File $family';

  @override
  String upTo(String size) => 'fino a $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Impossibile aggiungere $names: non è un’immagine.',
    other: 'Impossibile aggiungere $names: non sono immagini.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'Impossibile aggiungere $names: il tipo di file non è supportato.',
    other: 'Impossibile aggiungere $names: i tipi di file non sono supportati.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Impossibile aggiungere $names: supera $limit.',
    other: 'Impossibile aggiungere $names: superano $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Impossibile aggiungere $names: è una cartella.',
    other: 'Impossibile aggiungere $names: sono cartelle.',
  );

  @override
  String refusedMixed(String items) => 'Impossibile aggiungere $items.';

  @override
  String refusedItemNotImage(String name) => '$name (non è un’immagine)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (tipo di file non supportato)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (supera $limit)';

  @override
  String refusedItemFolder(String name) => '$name (è una cartella)';
}
