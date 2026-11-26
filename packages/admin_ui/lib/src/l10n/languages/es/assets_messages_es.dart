import '../../sections/assets_messages.dart';

/// Spanish [AssetsMessages].
class AssetsMessagesEs extends AssetsMessages {
  const AssetsMessagesEs([super.localeName = 'es']);

  @override
  String get assets => 'Recursos';

  @override
  String get loadingAssets => 'Cargando recursos…';

  @override
  String get couldNotLoadAssets => 'No se pudieron cargar los recursos';

  @override
  String get noMatchingAssets => 'No hay recursos que coincidan';

  @override
  String get noMatchingAssetsHint => 'Prueba con otra búsqueda u otro filtro.';

  @override
  String get noAssetsYet => 'Aún no hay recursos';

  @override
  String get noAssetsYetHint =>
      'Sube imágenes y archivos para crear tu biblioteca.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} recurso',
    other: '${number(count)} recursos',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} de ${assetCount(total)}';

  @override
  String get searchAssets => 'Buscar recursos';

  @override
  String get filterByType => 'Filtrar por tipo';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Todos los tipos';

  @override
  String get typeImages => 'Imágenes';

  @override
  String get typeVideos => 'Videos';

  @override
  String get typeAudio => 'Audio';

  @override
  String get typeDocuments => 'Documentos';

  @override
  String get typeOther => 'Otros';

  @override
  String get kindImage => 'Imagen';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Audio';

  @override
  String get kindDocument => 'Documento';

  @override
  String get kindOther => 'Otro';

  @override
  String get view => 'Vista';

  @override
  String get gridView => 'Vista de cuadrícula';

  @override
  String get listView => 'Vista de lista';

  @override
  String get libraryTab => 'Biblioteca';

  @override
  String get uploadTab => 'Subir';

  @override
  String get pickerTitle => 'Elegir recurso';

  @override
  String get select => 'Seleccionar';

  @override
  String get loadingMore => 'Cargando más…';

  @override
  String get dropToUpload => 'Suelta para subir';

  @override
  String couldNotLoadMore(String reason) => 'No se pudo cargar más. $reason';

  @override
  String get uploadIncomplete =>
      'La subida no se completó. Vuelve a intentarlo.';

  @override
  String get asset => 'Recurso';

  @override
  String get type => 'Tipo';

  @override
  String get size => 'Tamaño';

  @override
  String get dimensions => 'Dimensiones';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Texto alternativo';

  @override
  String get defaultAltText => 'Texto alternativo predeterminado';

  @override
  String get defaultAltTextHelp =>
      'Se usa en todos los lugares donde aparece este recurso, salvo que se '
      'reemplace en un uso concreto.';

  @override
  String get saveAltText => 'Guardar texto alternativo';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get aspectFree => 'Libre';

  @override
  String get imageUnavailable => 'Imagen no disponible';

  @override
  String get cropArea => 'Área de recorte de la imagen';

  @override
  String get cropAreaHint =>
      'Arrastra los controles para recortar. Las flechas mueven en pasos '
      'pequeños; mantén presionada Mayús para pasos más grandes.';

  @override
  String get positionArea => 'Área de encuadre de la imagen';

  @override
  String get positionAreaHint =>
      'Arrastra para mover la imagen y desplázate para hacer zoom; las '
      'flechas la mueven en pasos pequeños.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Enderezar';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Girar a la izquierda';

  @override
  String get rotateRight => 'Girar a la derecha';

  @override
  String get flipHorizontal => 'Voltear horizontalmente';

  @override
  String get flipVertical => 'Voltear verticalmente';

  @override
  String get useImage => 'Usar imagen';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'Al obtener la licencia, se agrega a tu biblioteca y se usa 1 '
        'descarga',
    other:
        'Al obtener la licencia, se agrega a tu biblioteca y se usan '
        '${number(downloads)} descargas',
  );

  @override
  String get selectImageToLicense =>
      'Selecciona una imagen para obtener su licencia';

  @override
  String get findStockImages => 'Buscar imágenes de stock';

  @override
  String get noResultsHint => 'Prueba con otra búsqueda o usa menos filtros.';

  @override
  String stockSearchPrompt(String provider) =>
      'Escribe para buscar entre millones de imágenes en $provider.';

  @override
  String providerResults(String provider) => 'Resultados de $provider';

  @override
  String resultCount(int count) => plural(
    count,
    one: '${number(count)} resultado',
    other: '${number(count)} resultados',
  );

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} de ${resultCount(total)}';

  @override
  String searchProvider(String provider) => 'Buscar en $provider';

  @override
  String get orientation => 'Orientación';

  @override
  String get anyOrientation => 'Cualquier orientación';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  /// An orientation is feminine.
  @override
  String get square => 'Cuadrada';

  @override
  String get imageType => 'Tipo de imagen';

  @override
  String get anyType => 'Cualquier tipo';

  @override
  String get photos => 'Fotos';

  @override
  String get illustrations => 'Ilustraciones';

  @override
  String get vectors => 'Vectores';

  @override
  String licenseFrom(String provider) => 'Obtener licencia de $provider';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Agrega la imagen a tu biblioteca y usa 1 descarga de tu plan de '
        '$provider.',
    other:
        'Agrega la imagen a tu biblioteca y usa ${number(downloads)} '
        'descargas de tu plan de $provider.',
  );

  @override
  String get couldNotLicense => 'No se pudo obtener la licencia de esta imagen';

  @override
  String get licenseAndAdd => 'Obtener licencia y agregar';

  @override
  String get couldNotLoadSizes => 'No se pudieron cargar los tamaños';

  @override
  String editItem(String name) => 'Editar $name';

  @override
  String get done => 'Listo';

  @override
  String get couldNotLoadPreview => 'No se pudo cargar la vista previa';

  @override
  String get uploading => 'Subiendo';

  @override
  String get replace => 'Reemplazar';

  @override
  String get choose => 'Elegir';

  @override
  String get editCrop => 'Editar recorte';

  @override
  String get cropAndFocalPoint => 'Recorte y punto focal';

  @override
  String get imagesOnly => 'Solo imágenes';

  @override
  String get typeText => 'Texto';

  /// The MIME family follows the noun as it is: "Archivos application".
  @override
  String familyFiles(String family) =>
      family.isEmpty ? 'Archivos' : 'Archivos $family';

  @override
  String upTo(String size) => 'hasta $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'No se pudo agregar $names: no es una imagen.',
    other: 'No se pudieron agregar $names: no son imágenes.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'No se pudo agregar $names: no es un tipo de archivo compatible.',
    other:
        'No se pudieron agregar $names: no son tipos de archivo compatibles.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'No se pudo agregar $names: ocupa más de $limit.',
    other: 'No se pudieron agregar $names: ocupan más de $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'No se pudo agregar $names: es una carpeta.',
    other: 'No se pudieron agregar $names: son carpetas.',
  );

  @override
  String refusedMixed(String items) => 'No se pudieron agregar $items.';

  @override
  String refusedItemNotImage(String name) => '$name (no es una imagen)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (tipo de archivo no compatible)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (ocupa más de $limit)';

  @override
  String refusedItemFolder(String name) => '$name (es una carpeta)';
}
