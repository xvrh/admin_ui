import '../messages.dart';

/// Strings for the asset library, picker, cropper and editor.
///
/// [AssetsMessagesEn], [AssetsMessagesFr] and [AssetsMessagesAr] each
/// extend this class directly, so a member added here without its French or
/// Arabic text fails to compile. Add a message to all three in the same edit.
abstract class AssetsMessages extends AdminMessages {
  const AssetsMessages(super.localeName);

  // ── library and picker ─────────────────────────────────────────────────

  /// The accessible name of a grid or list of assets.
  String get assets;

  /// The library is fetching its first page, with a trailing ellipsis.
  String get loadingAssets;

  /// The library could not be fetched.
  String get couldNotLoadAssets;

  /// A search or a filter over the library found nothing.
  String get noMatchingAssets;

  /// What to do about [noMatchingAssets].
  String get noMatchingAssetsHint;

  /// The library is empty.
  String get noAssetsYet;

  /// What to do about [noAssetsYet].
  String get noAssetsYetHint;

  /// How many assets match: "1 asset", "120 assets".
  String assetCount(int count);

  /// The first [shown] of [total] matching assets: "24 of 120 assets".
  String assetsShown(int shown, int total);

  /// The placeholder of the library's search box.
  String get searchAssets;

  /// The tooltip of the type filter.
  String get filterByType;

  /// The accessible name of a filter menu: what it [filter]s by, and its
  /// current [choice].
  String filterChoice(String filter, String choice);

  /// The type filter's unfiltered option.
  String get allTypes;

  /// A type filter option, and an accepted file family.
  String get typeImages;

  /// A type filter option, and an accepted file family.
  String get typeVideos;

  /// A type filter option, and an accepted file family.
  String get typeAudio;

  /// A type filter option.
  String get typeDocuments;

  /// A type filter option: files of no other type.
  String get typeOther;

  /// One asset's type, as its details list it.
  String get kindImage;

  /// One asset's type, as its details list it.
  String get kindVideo;

  /// One asset's type, as its details list it.
  String get kindAudio;

  /// One asset's type, as its details list it.
  String get kindDocument;

  /// One asset's type, as its details list it: none of the others.
  String get kindOther;

  /// The accessible name of the grid / list switch.
  String get view;

  /// The grid option of the view switch.
  String get gridView;

  /// The list option of the view switch.
  String get listView;

  /// The tab of the library in a picker.
  String get libraryTab;

  /// The tab that uploads new files in a picker.
  String get uploadTab;

  /// The title of the media picker, which also names it to assistive
  /// technology.
  String get pickerTitle;

  /// Confirms the pick of a picker.
  String get select;

  /// The next page of a grid is on its way, with a trailing ellipsis.
  String get loadingMore;

  /// Shown over a picker while a file is dragged over it.
  String get dropToUpload;

  /// A next page failed: [reason] is a sentence of its own saying why.
  String couldNotLoadMore(String reason);

  /// An upload the source neither finished nor explained.
  String get uploadIncomplete;

  // ── details ────────────────────────────────────────────────────────────

  /// The title of an asset's detail sheet.
  String get asset;

  /// The label of an asset's type.
  String get type;

  /// The label of a file size, or of a licensable size.
  String get size;

  /// The label of an image's pixel dimensions.
  String get dimensions;

  /// An image's pixel dimensions: "1920 × 1080".
  String pixelSize(int width, int height);

  /// The label of an asset's identifier.
  String get id;

  /// The label of an image's text alternative.
  String get altText;

  /// The label of the library-wide text alternative.
  String get defaultAltText;

  /// What [defaultAltText] is for.
  String get defaultAltTextHelp;

  /// Saves [defaultAltText].
  String get saveAltText;

  /// The label of an asset's address.
  String get url;

  /// Copies an asset's address.
  String get copyUrl;

  // ── cropper ────────────────────────────────────────────────────────────

  /// The aspect preset that leaves the crop's shape free.
  String get aspectFree;

  /// An image that failed to load.
  String get imageUnavailable;

  /// The accessible name of the crop area.
  String get cropArea;

  /// How to use [cropArea] from the keyboard or the pointer.
  String get cropAreaHint;

  /// The accessible name of the area that positions an image in a frame.
  String get positionArea;

  /// How to use [positionArea].
  String get positionAreaHint;

  /// The label of the zoom slider.
  String get zoom;

  /// A zoom factor: [amount] is already formatted, "1.5×".
  String zoomLevel(String amount);

  /// The label of the slider that levels a tilted image.
  String get straighten;

  /// An angle: [amount] is already formatted, "3°".
  String degrees(String amount);

  /// Turns the image a quarter counter-clockwise.
  String get rotateLeft;

  /// Turns the image a quarter clockwise.
  String get rotateRight;

  /// Mirrors the image left to right.
  String get flipHorizontal;

  /// Mirrors the image top to bottom.
  String get flipVertical;

  // ── stock providers ────────────────────────────────────────────────────

  /// Confirms the pick of a stock image.
  String get useImage;

  /// What licensing the picked image does, costing [downloads].
  String licenseNotice(int downloads);

  /// The footer of a provider browser with nothing picked.
  String get selectImageToLicense;

  /// The empty provider browser, before a search.
  String get findStockImages;

  /// What to do about a provider search that found nothing.
  String get noResultsHint;

  /// What to do in the empty browser of [provider].
  String stockSearchPrompt(String provider);

  /// The accessible name of [provider]'s results.
  String providerResults(String provider);

  /// How many results a search has: "1 result", "340 results".
  String resultCount(int count);

  /// The first [shown] of [total] results: "24 of 340 results".
  String resultsShown(int shown, int total);

  /// The placeholder of the search box of [provider].
  String searchProvider(String provider);

  /// The tooltip of the orientation filter.
  String get orientation;

  /// The orientation filter's unfiltered option.
  String get anyOrientation;

  /// An orientation filter option: wider than tall.
  String get horizontal;

  /// An orientation filter option: taller than wide.
  String get vertical;

  /// An orientation filter option.
  String get square;

  /// The tooltip of the image type filter.
  String get imageType;

  /// The image type filter's unfiltered option.
  String get anyType;

  /// An image type filter option.
  String get photos;

  /// An image type filter option.
  String get illustrations;

  /// An image type filter option.
  String get vectors;

  /// The title of the dialog that licenses an image from [provider].
  String licenseFrom(String provider);

  /// What licensing does, costing [downloads] of the [provider] plan.
  String licenseDetail(String provider, int downloads);

  /// Licensing the image failed.
  String get couldNotLicense;

  /// Licenses the image and adds it to the library.
  String get licenseAndAdd;

  /// The licensable sizes could not be fetched.
  String get couldNotLoadSizes;

  // ── asset editor ───────────────────────────────────────────────────────

  /// The title of the editor of the field or item named [name].
  String editItem(String name);

  /// Closes an editor whose changes already applied.
  String get done;

  /// The preview could not be fetched.
  String get couldNotLoadPreview;

  /// The accessible name of an upload's progress.
  String get uploading;

  /// Picks another asset in place of the current one.
  String get replace;

  /// Picks an asset for an empty field.
  String get choose;

  /// Opens the crop dialog.
  String get editCrop;

  /// The title of the crop dialog.
  String get cropAndFocalPoint;

  // ── accepted files ─────────────────────────────────────────────────────

  /// A drop zone that takes images and nothing else.
  String get imagesOnly;

  /// Accepted text files.
  String get typeText;

  /// Accepted files of the MIME [family], such as 'application'.
  String familyFiles(String family);

  /// A size limit: [size] is already formatted, "up to 10 MB".
  String upTo(String size);

  /// Joins the names of a list: ', ' in English.
  String get listSeparator;

  /// [count] files named in [names] were refused as not images.
  String refusedNotImage(String names, int count);

  /// [count] files named in [names] were refused for their type.
  String refusedNotSupported(String names, int count);

  /// [count] files named in [names] were refused as larger than [limit].
  String refusedTooLarge(String names, int count, String limit);

  /// [count] folders named in [names] were refused.
  String refusedFolder(String names, int count);

  /// Files refused for different reasons: [items] lists each with its
  /// reason, as [refusedItemNotImage] and its siblings word it.
  String refusedMixed(String items);

  /// One file of [refusedMixed]: [name] is not an image.
  String refusedItemNotImage(String name);

  /// One file of [refusedMixed]: [name]'s type is not accepted.
  String refusedItemNotSupported(String name);

  /// One file of [refusedMixed]: [name] is larger than [limit].
  String refusedItemTooLarge(String name, String limit);

  /// One file of [refusedMixed]: [name] is a folder.
  String refusedItemFolder(String name);
}

/// English [AssetsMessages]. Subclass it to override a few strings.
class AssetsMessagesEn extends AssetsMessages {
  const AssetsMessagesEn([super.localeName = 'en']);

  @override
  String get assets => 'Assets';

  @override
  String get loadingAssets => 'Loading assets…';

  @override
  String get couldNotLoadAssets => 'Couldn’t load assets';

  @override
  String get noMatchingAssets => 'No matching assets';

  @override
  String get noMatchingAssetsHint => 'Try a different search or filter.';

  @override
  String get noAssetsYet => 'No assets yet';

  @override
  String get noAssetsYetHint =>
      'Upload images and files to build your library.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} asset',
    other: '${number(count)} assets',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} of ${assetCount(total)}';

  @override
  String get searchAssets => 'Search assets';

  @override
  String get filterByType => 'Filter by type';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'All types';

  @override
  String get typeImages => 'Images';

  @override
  String get typeVideos => 'Videos';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Documents';

  @override
  String get typeOther => 'Other';

  @override
  String get kindImage => 'Image';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Document';

  @override
  String get kindOther => 'Other';

  @override
  String get view => 'View';

  @override
  String get gridView => 'Grid view';

  @override
  String get listView => 'List view';

  @override
  String get libraryTab => 'Library';

  @override
  String get uploadTab => 'Upload';

  @override
  String get pickerTitle => 'Choose media';

  @override
  String get select => 'Select';

  @override
  String get loadingMore => 'Loading more…';

  @override
  String get dropToUpload => 'Drop to upload';

  @override
  String couldNotLoadMore(String reason) => 'Couldn’t load more. $reason';

  @override
  String get uploadIncomplete => 'The upload didn’t complete. Try again.';

  @override
  String get asset => 'Asset';

  @override
  String get type => 'Type';

  @override
  String get size => 'Size';

  @override
  String get dimensions => 'Dimensions';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Alt text';

  @override
  String get defaultAltText => 'Default alt text';

  @override
  String get defaultAltTextHelp =>
      'Used wherever this asset appears, unless overridden on the usage.';

  @override
  String get saveAltText => 'Save alt text';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get aspectFree => 'Free';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get cropArea => 'Image crop area';

  @override
  String get cropAreaHint =>
      'Drag the handles to crop. Arrow keys nudge; hold Shift for larger '
      'steps.';

  @override
  String get positionArea => 'Image position area';

  @override
  String get positionAreaHint =>
      'Drag to reposition, scroll to zoom; arrow keys nudge.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Straighten';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Rotate left';

  @override
  String get rotateRight => 'Rotate right';

  @override
  String get flipHorizontal => 'Flip horizontal';

  @override
  String get flipVertical => 'Flip vertical';

  @override
  String get useImage => 'Use image';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one: 'Licensing adds it to your library and uses 1 download',
    other:
        'Licensing adds it to your library and uses ${number(downloads)} '
        'downloads',
  );

  @override
  String get selectImageToLicense => 'Select an image to license';

  @override
  String get findStockImages => 'Find stock images';

  @override
  String get noResultsHint => 'Try a different search or loosen the filters.';

  @override
  String stockSearchPrompt(String provider) =>
      'Type to search millions of images on $provider.';

  @override
  String providerResults(String provider) => '$provider results';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} result',
    other: '${number(count)} results',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} of ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'Search $provider';

  @override
  String get orientation => 'Orientation';

  @override
  String get anyOrientation => 'Any orientation';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get square => 'Square';

  @override
  String get imageType => 'Image type';

  @override
  String get anyType => 'Any type';

  @override
  String get photos => 'Photos';

  @override
  String get illustrations => 'Illustrations';

  @override
  String get vectors => 'Vectors';

  @override
  String licenseFrom(String provider) => 'License from $provider';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Adds the image to your library and uses 1 download from your '
        '$provider plan.',
    other:
        'Adds the image to your library and uses ${number(downloads)} '
        'downloads from your $provider plan.',
  );

  @override
  String get couldNotLicense => 'Couldn’t license this image';

  @override
  String get licenseAndAdd => 'License & add';

  @override
  String get couldNotLoadSizes => 'Couldn’t load the sizes';

  @override
  String editItem(String name) => 'Edit $name';

  @override
  String get done => 'Done';

  @override
  String get couldNotLoadPreview => 'Couldn’t load the preview';

  @override
  String get uploading => 'Uploading';

  @override
  String get replace => 'Replace';

  @override
  String get choose => 'Choose';

  @override
  String get editCrop => 'Edit crop';

  @override
  String get cropAndFocalPoint => 'Crop & focal point';

  @override
  String get imagesOnly => 'Images only';

  @override
  String get typeText => 'Text';

  @override
  String familyFiles(String family) => family.isEmpty
      ? 'Files'
      : '${family[0].toUpperCase()}${family.substring(1)} files';

  @override
  String upTo(String size) => 'up to $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Couldn’t add $names: it’s not an image.',
    other: 'Couldn’t add $names: they’re not images.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'Couldn’t add $names: it’s not a supported file type.',
    other: 'Couldn’t add $names: they’re not supported file types.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Couldn’t add $names: it’s larger than $limit.',
    other: 'Couldn’t add $names: they’re larger than $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Couldn’t add $names: it’s a folder.',
    other: 'Couldn’t add $names: they’re folders.',
  );

  @override
  String refusedMixed(String items) => 'Couldn’t add $items.';

  @override
  String refusedItemNotImage(String name) => '$name (not an image)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (not a supported file type)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (larger than $limit)';

  @override
  String refusedItemFolder(String name) => '$name (a folder)';
}

/// French [AssetsMessages].
class AssetsMessagesFr extends AssetsMessages {
  const AssetsMessagesFr([super.localeName = 'fr']);

  @override
  String get assets => 'Médias';

  @override
  String get loadingAssets => 'Chargement des médias…';

  @override
  String get couldNotLoadAssets => 'Impossible de charger les médias';

  @override
  String get noMatchingAssets => 'Aucun média correspondant';

  @override
  String get noMatchingAssetsHint =>
      'Essayez une autre recherche ou un autre filtre.';

  @override
  String get noAssetsYet => 'Aucun média pour l’instant';

  @override
  String get noAssetsYetHint =>
      'Importez des images et des fichiers pour constituer votre médiathèque.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} média',
    other: '${number(count)} médias',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} sur ${assetCount(total)}';

  @override
  String get searchAssets => 'Rechercher des médias';

  @override
  String get filterByType => 'Filtrer par type';

  @override
  String filterChoice(String filter, String choice) => '$filter\u00A0: $choice';

  @override
  String get allTypes => 'Tous les types';

  @override
  String get typeImages => 'Images';

  @override
  String get typeVideos => 'Vidéos';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Documents';

  @override
  String get typeOther => 'Autres';

  @override
  String get kindImage => 'Image';

  @override
  String get kindVideo => 'Vidéo';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Document';

  @override
  String get kindOther => 'Autre';

  @override
  String get view => 'Affichage';

  @override
  String get gridView => 'Vue en grille';

  @override
  String get listView => 'Vue en liste';

  @override
  String get libraryTab => 'Médiathèque';

  @override
  String get uploadTab => 'Importer';

  @override
  String get pickerTitle => 'Choisir un média';

  @override
  String get select => 'Sélectionner';

  @override
  String get loadingMore => 'Chargement de la suite…';

  @override
  String get dropToUpload => 'Déposez pour importer';

  @override
  String couldNotLoadMore(String reason) =>
      'Impossible de charger la suite. $reason';

  @override
  String get uploadIncomplete => 'L’envoi n’a pas abouti. Réessayez.';

  @override
  String get asset => 'Média';

  @override
  String get type => 'Type';

  @override
  String get size => 'Taille';

  @override
  String get dimensions => 'Dimensions';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Texte alternatif';

  @override
  String get defaultAltText => 'Texte alternatif par défaut';

  @override
  String get defaultAltTextHelp =>
      'Utilisé partout où ce média apparaît, sauf s’il est remplacé là où '
      'il est utilisé.';

  @override
  String get saveAltText => 'Enregistrer le texte alternatif';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'Copier l’URL';

  @override
  String get aspectFree => 'Libre';

  @override
  String get imageUnavailable => 'Image indisponible';

  @override
  String get cropArea => 'Zone de recadrage de l’image';

  @override
  String get cropAreaHint =>
      'Faites glisser les poignées pour recadrer. Les flèches déplacent '
      'finement ; maintenez Maj pour des pas plus grands.';

  @override
  String get positionArea => 'Zone de cadrage de l’image';

  @override
  String get positionAreaHint =>
      'Faites glisser pour repositionner, faites défiler pour zoomer ; les '
      'flèches déplacent finement.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Redresser';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Faire pivoter à gauche';

  @override
  String get rotateRight => 'Faire pivoter à droite';

  @override
  String get flipHorizontal => 'Retourner horizontalement';

  @override
  String get flipVertical => 'Retourner verticalement';

  @override
  String get useImage => 'Utiliser l’image';

  /// French counts 0 and 1 as the singular.
  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'La licence l’ajoute à votre médiathèque et utilise '
        '${number(downloads)} téléchargement',
    other:
        'La licence l’ajoute à votre médiathèque et utilise '
        '${number(downloads)} téléchargements',
  );

  @override
  String get selectImageToLicense =>
      'Sélectionnez une image pour en acquérir la licence';

  @override
  String get findStockImages => 'Trouver des images de banque';

  @override
  String get noResultsHint =>
      'Essayez une autre recherche ou assouplissez les filtres.';

  @override
  String stockSearchPrompt(String provider) =>
      'Saisissez une recherche parmi des millions d’images sur $provider.';

  @override
  String providerResults(String provider) => 'Résultats $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} résultat',
    other: '${number(count)} résultats',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} sur ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'Rechercher sur $provider';

  @override
  String get orientation => 'Orientation';

  @override
  String get anyOrientation => 'Toutes les orientations';

  @override
  String get horizontal => 'Paysage';

  @override
  String get vertical => 'Portrait';

  @override
  String get square => 'Carré';

  @override
  String get imageType => 'Type d’image';

  @override
  String get anyType => 'Tous les types';

  @override
  String get photos => 'Photos';

  @override
  String get illustrations => 'Illustrations';

  @override
  String get vectors => 'Vectoriels';

  @override
  String licenseFrom(String provider) => 'Licence $provider';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Ajoute l’image à votre médiathèque et utilise '
        '${number(downloads)} téléchargement de votre forfait $provider.',
    other:
        'Ajoute l’image à votre médiathèque et utilise '
        '${number(downloads)} téléchargements de votre forfait $provider.',
  );

  @override
  String get couldNotLicense => 'Impossible d’acquérir la licence de l’image';

  @override
  String get licenseAndAdd => 'Acquérir et ajouter';

  @override
  String get couldNotLoadSizes => 'Impossible de charger les tailles';

  @override
  String editItem(String name) => 'Modifier : $name';

  @override
  String get done => 'Terminé';

  @override
  String get couldNotLoadPreview => 'Impossible de charger l’aperçu';

  @override
  String get uploading => 'Envoi en cours';

  @override
  String get replace => 'Remplacer';

  @override
  String get choose => 'Choisir';

  @override
  String get editCrop => 'Modifier le recadrage';

  @override
  String get cropAndFocalPoint => 'Recadrage et point focal';

  @override
  String get imagesOnly => 'Images uniquement';

  @override
  String get typeText => 'Texte';

  @override
  String familyFiles(String family) => 'Fichiers $family';

  @override
  String upTo(String size) => 'jusqu’à $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Impossible d’ajouter $names : ce n’est pas une image.',
    other: 'Impossible d’ajouter $names : ce ne sont pas des images.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one:
        'Impossible d’ajouter $names : ce type de fichier n’est pas pris en '
        'charge.',
    other:
        'Impossible d’ajouter $names : ces types de fichier ne sont pas pris '
        'en charge.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Impossible d’ajouter $names : le fichier dépasse $limit.',
    other: 'Impossible d’ajouter $names : les fichiers dépassent $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Impossible d’ajouter $names : c’est un dossier.',
    other: 'Impossible d’ajouter $names : ce sont des dossiers.',
  );

  @override
  String refusedMixed(String items) => 'Impossible d’ajouter $items.';

  @override
  String refusedItemNotImage(String name) => '$name (pas une image)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (type de fichier non pris en charge)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (plus de $limit)';

  @override
  String refusedItemFolder(String name) => '$name (un dossier)';
}

/// Arabic [AssetsMessages].
class AssetsMessagesAr extends AssetsMessages {
  const AssetsMessagesAr([super.localeName = 'ar']);

  @override
  String get assets => 'الملفات';

  @override
  String get loadingAssets => 'جارٍ تحميل الملفات…';

  @override
  String get couldNotLoadAssets => 'تعذّر تحميل الملفات';

  @override
  String get noMatchingAssets => 'لا توجد ملفات مطابقة';

  @override
  String get noMatchingAssetsHint => 'جرّب بحثًا أو عامل تصفية مختلفًا.';

  @override
  String get noAssetsYet => 'لا توجد ملفات بعد';

  @override
  String get noAssetsYetHint => 'ارفع الصور والملفات لإنشاء مكتبتك.';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String assetCount(int count) => plural(
    count,
    zero: 'لا ملفات',
    one: 'ملف واحد',
    two: 'ملفان',
    few: '${number(count)} ملفات',
    many: '${number(count)} ملفًا',
    other: '${number(count)} ملف',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} من ${assetCount(total)}';

  @override
  String get searchAssets => 'البحث في الملفات';

  @override
  String get filterByType => 'التصفية حسب النوع';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'كل الأنواع';

  @override
  String get typeImages => 'الصور';

  @override
  String get typeVideos => 'الفيديوهات';

  @override
  String get typeAudio => 'الصوتيات';

  @override
  String get typeDocuments => 'المستندات';

  @override
  String get typeOther => 'أخرى';

  @override
  String get kindImage => 'صورة';

  @override
  String get kindVideo => 'فيديو';

  @override
  String get kindAudio => 'صوت';

  @override
  String get kindDocument => 'مستند';

  @override
  String get kindOther => 'آخر';

  @override
  String get view => 'طريقة العرض';

  @override
  String get gridView => 'عرض شبكي';

  @override
  String get listView => 'عرض قائمة';

  @override
  String get libraryTab => 'المكتبة';

  @override
  String get uploadTab => 'رفع';

  @override
  String get pickerTitle => 'اختيار الوسائط';

  @override
  String get select => 'تحديد';

  @override
  String get loadingMore => 'جارٍ تحميل المزيد…';

  @override
  String get dropToUpload => 'أفلِت الملفات للرفع';

  @override
  String couldNotLoadMore(String reason) => 'تعذّر تحميل المزيد. $reason';

  @override
  String get uploadIncomplete => 'لم يكتمل الرفع. حاول مرة أخرى.';

  @override
  String get asset => 'الملف';

  @override
  String get type => 'النوع';

  @override
  String get size => 'الحجم';

  @override
  String get dimensions => 'الأبعاد';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'المعرّف';

  @override
  String get altText => 'النص البديل';

  @override
  String get defaultAltText => 'النص البديل الافتراضي';

  @override
  String get defaultAltTextHelp =>
      'يُستخدم أينما ظهر هذا الملف، ما لم يُستبدل في موضع استخدامه.';

  @override
  String get saveAltText => 'حفظ النص البديل';

  @override
  String get url => 'الرابط';

  @override
  String get copyUrl => 'نسخ الرابط';

  @override
  String get aspectFree => 'حر';

  @override
  String get imageUnavailable => 'الصورة غير متاحة';

  @override
  String get cropArea => 'منطقة قص الصورة';

  @override
  String get cropAreaHint =>
      'اسحب المقابض للقص. تحرّك مفاتيح الأسهم القص قليلًا، واضغط Shift '
      'مع الاستمرار لخطوات أكبر.';

  @override
  String get positionArea => 'منطقة موضع الصورة';

  @override
  String get positionAreaHint =>
      'اسحب لتغيير الموضع ومرّر للتكبير، وتحرّك مفاتيح الأسهم الصورة قليلًا.';

  @override
  String get zoom => 'التكبير';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'تعديل الميل';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'تدوير لليسار';

  @override
  String get rotateRight => 'تدوير لليمين';

  @override
  String get flipHorizontal => 'قلب أفقي';

  @override
  String get flipVertical => 'قلب رأسي';

  @override
  String get useImage => 'استخدام الصورة';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    zero: 'يضيفها الترخيص إلى مكتبتك دون استخدام أي تنزيل',
    one: 'يضيفها الترخيص إلى مكتبتك ويستخدم تنزيلًا واحدًا',
    two: 'يضيفها الترخيص إلى مكتبتك ويستخدم تنزيلين',
    few: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيلات',
    many: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيلًا',
    other: 'يضيفها الترخيص إلى مكتبتك ويستخدم ${number(downloads)} تنزيل',
  );

  @override
  String get selectImageToLicense => 'اختر صورة لترخيصها';

  @override
  String get findStockImages => 'ابحث عن صور جاهزة';

  @override
  String get noResultsHint => 'جرّب بحثًا مختلفًا أو خفّف عوامل التصفية.';

  @override
  String stockSearchPrompt(String provider) =>
      'اكتب للبحث في ملايين الصور على $provider.';

  @override
  String providerResults(String provider) => 'نتائج $provider';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String resultCount(int count) => plural(
    count,
    zero: 'لا نتائج',
    one: 'نتيجة واحدة',
    two: 'نتيجتان',
    few: '${number(count)} نتائج',
    many: '${number(count)} نتيجة',
    other: '${number(count)} نتيجة',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} من ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'البحث في $provider';

  @override
  String get orientation => 'الاتجاه';

  @override
  String get anyOrientation => 'أي اتجاه';

  @override
  String get horizontal => 'أفقي';

  @override
  String get vertical => 'رأسي';

  @override
  String get square => 'مربع';

  @override
  String get imageType => 'نوع الصورة';

  @override
  String get anyType => 'أي نوع';

  @override
  String get photos => 'صور فوتوغرافية';

  @override
  String get illustrations => 'رسوم توضيحية';

  @override
  String get vectors => 'رسوم متجهة';

  @override
  String licenseFrom(String provider) => 'الترخيص من $provider';

  /// Arabic counts with the noun, in all six plural forms.
  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    zero: 'يضيف الصورة إلى مكتبتك دون استخدام أي تنزيل من باقة $provider.',
    one: 'يضيف الصورة إلى مكتبتك ويستخدم تنزيلًا واحدًا من باقة $provider.',
    two: 'يضيف الصورة إلى مكتبتك ويستخدم تنزيلين من باقة $provider.',
    few:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيلات من '
        'باقة $provider.',
    many:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيلًا من '
        'باقة $provider.',
    other:
        'يضيف الصورة إلى مكتبتك ويستخدم ${number(downloads)} تنزيل من '
        'باقة $provider.',
  );

  @override
  String get couldNotLicense => 'تعذّر ترخيص هذه الصورة';

  @override
  String get licenseAndAdd => 'ترخيص وإضافة';

  @override
  String get couldNotLoadSizes => 'تعذّر تحميل المقاسات';

  @override
  String editItem(String name) => 'تعديل: $name';

  @override
  String get done => 'تم';

  @override
  String get couldNotLoadPreview => 'تعذّر تحميل المعاينة';

  @override
  String get uploading => 'جارٍ الرفع';

  @override
  String get replace => 'استبدال';

  @override
  String get choose => 'اختيار';

  @override
  String get editCrop => 'تعديل القص';

  @override
  String get cropAndFocalPoint => 'القص ونقطة التركيز';

  @override
  String get imagesOnly => 'الصور فقط';

  @override
  String get typeText => 'النصوص';

  @override
  String familyFiles(String family) => 'ملفات $family';

  @override
  String upTo(String size) => 'حتى $size';

  @override
  String get listSeparator => '، ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: الملف ليس صورة.',
    other: 'تعذّرت إضافة $names: الملفات ليست صورًا.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: نوع الملف غير مدعوم.',
    other: 'تعذّرت إضافة $names: أنواع الملفات غير مدعومة.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'تعذّرت إضافة $names: حجم الملف أكبر من $limit.',
    other: 'تعذّرت إضافة $names: حجم الملفات أكبر من $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'تعذّرت إضافة $names: إنه مجلد.',
    other: 'تعذّرت إضافة $names: إنها مجلدات.',
  );

  @override
  String refusedMixed(String items) => 'تعذّرت إضافة $items.';

  @override
  String refusedItemNotImage(String name) => '$name (ليس صورة)';

  @override
  String refusedItemNotSupported(String name) => '$name (نوع غير مدعوم)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (أكبر من $limit)';

  @override
  String refusedItemFolder(String name) => '$name (مجلد)';
}
