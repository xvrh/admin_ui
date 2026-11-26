import '../../sections/assets_messages.dart';

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
