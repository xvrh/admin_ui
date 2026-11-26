import '../../sections/assets_messages.dart';

/// Brazilian Portuguese [AssetsMessages].
class AssetsMessagesPt extends AssetsMessages {
  const AssetsMessagesPt([super.localeName = 'pt']);

  @override
  String get assets => 'Mídias';

  @override
  String get loadingAssets => 'Carregando mídias…';

  @override
  String get couldNotLoadAssets => 'Não foi possível carregar as mídias';

  @override
  String get noMatchingAssets => 'Nenhuma mídia correspondente';

  @override
  String get noMatchingAssetsHint => 'Tente outra pesquisa ou outro filtro.';

  @override
  String get noAssetsYet => 'Nenhuma mídia ainda';

  @override
  String get noAssetsYetHint =>
      'Envie imagens e arquivos para montar sua biblioteca.';

  @override
  String assetCount(int count) => plural(
    count,
    one: '${number(count)} mídia',
    other: '${number(count)} mídias',
  );

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} de ${assetCount(total)}';

  @override
  String get searchAssets => 'Pesquisar mídias';

  @override
  String get filterByType => 'Filtrar por tipo';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Todos os tipos';

  @override
  String get typeImages => 'Imagens';

  @override
  String get typeVideos => 'Vídeos';

  @override
  String get typeAudio => 'Áudio';

  @override
  String get typeDocuments => 'Documentos';

  @override
  String get typeOther => 'Outros';

  @override
  String get kindImage => 'Imagem';

  @override
  String get kindVideo => 'Vídeo';

  @override
  String get kindAudio => 'Áudio';

  @override
  String get kindDocument => 'Documento';

  @override
  String get kindOther => 'Outro';

  @override
  String get view => 'Exibição';

  @override
  String get gridView => 'Exibição em grade';

  @override
  String get listView => 'Exibição em lista';

  @override
  String get libraryTab => 'Biblioteca';

  @override
  String get uploadTab => 'Enviar';

  @override
  String get pickerTitle => 'Escolher mídia';

  @override
  String get select => 'Selecionar';

  @override
  String get loadingMore => 'Carregando mais…';

  @override
  String get dropToUpload => 'Solte para enviar';

  @override
  String couldNotLoadMore(String reason) =>
      'Não foi possível carregar mais. $reason';

  @override
  String get uploadIncomplete => 'O envio não foi concluído. Tente novamente.';

  @override
  String get asset => 'Mídia';

  @override
  String get type => 'Tipo';

  @override
  String get size => 'Tamanho';

  @override
  String get dimensions => 'Dimensões';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Texto alternativo';

  @override
  String get defaultAltText => 'Texto alternativo padrão';

  @override
  String get defaultAltTextHelp =>
      'Usado onde quer que esta mídia apareça, a menos que seja substituído '
      'no local de uso.';

  @override
  String get saveAltText => 'Salvar texto alternativo';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get aspectFree => 'Livre';

  @override
  String get imageUnavailable => 'Imagem indisponível';

  @override
  String get cropArea => 'Área de corte da imagem';

  @override
  String get cropAreaHint =>
      'Arraste as alças para cortar. As setas fazem ajustes finos; segure '
      'Shift para passos maiores.';

  @override
  String get positionArea => 'Área de posicionamento da imagem';

  @override
  String get positionAreaHint =>
      'Arraste para reposicionar e role para aplicar zoom; as setas fazem '
      'ajustes finos.';

  @override
  String get zoom => 'Zoom';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Endireitar';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Girar para a esquerda';

  @override
  String get rotateRight => 'Girar para a direita';

  @override
  String get flipHorizontal => 'Inverter horizontalmente';

  @override
  String get flipVertical => 'Inverter verticalmente';

  @override
  String get useImage => 'Usar imagem';

  /// Brazilian Portuguese counts 0 and 1 as the singular.
  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    one:
        'O licenciamento adiciona a imagem à sua biblioteca e usa '
        '${number(downloads)} download',
    other:
        'O licenciamento adiciona a imagem à sua biblioteca e usa '
        '${number(downloads)} downloads',
  );

  @override
  String get selectImageToLicense => 'Selecione uma imagem para licenciar';

  @override
  String get findStockImages => 'Pesquisar em bancos de imagens';

  @override
  String get noResultsHint =>
      'Tente outra pesquisa ou use filtros menos restritivos.';

  @override
  String stockSearchPrompt(String provider) =>
      'Digite para pesquisar entre milhões de imagens em $provider.';

  @override
  String providerResults(String provider) => 'Resultados em $provider';

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
  String searchProvider(String provider) => 'Pesquisar em $provider';

  @override
  String get orientation => 'Orientação';

  @override
  String get anyOrientation => 'Qualquer orientação';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  /// An image is feminine.
  @override
  String get square => 'Quadrada';

  @override
  String get imageType => 'Tipo de imagem';

  @override
  String get anyType => 'Qualquer tipo';

  @override
  String get photos => 'Fotos';

  @override
  String get illustrations => 'Ilustrações';

  @override
  String get vectors => 'Vetores';

  /// Via, so that no article has to agree with the name of the provider.
  @override
  String licenseFrom(String provider) => 'Licenciar via $provider';

  /// Brazilian Portuguese counts 0 and 1 as the singular.
  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    one:
        'Adiciona a imagem à sua biblioteca e usa ${number(downloads)} '
        'download do seu plano $provider.',
    other:
        'Adiciona a imagem à sua biblioteca e usa ${number(downloads)} '
        'downloads do seu plano $provider.',
  );

  @override
  String get couldNotLicense => 'Não foi possível licenciar esta imagem';

  @override
  String get licenseAndAdd => 'Licenciar e adicionar';

  @override
  String get couldNotLoadSizes => 'Não foi possível carregar os tamanhos';

  @override
  String editItem(String name) => 'Editar $name';

  @override
  String get done => 'Concluído';

  @override
  String get couldNotLoadPreview => 'Não foi possível carregar a prévia';

  @override
  String get uploading => 'Enviando';

  @override
  String get replace => 'Substituir';

  @override
  String get choose => 'Escolher';

  @override
  String get editCrop => 'Editar corte';

  @override
  String get cropAndFocalPoint => 'Corte e ponto focal';

  @override
  String get imagesOnly => 'Somente imagens';

  @override
  String get typeText => 'Texto';

  /// The MIME family stays as it is written, after the noun, so it is not
  /// capitalised.
  @override
  String familyFiles(String family) =>
      family.isEmpty ? 'Arquivos' : 'Arquivos do tipo $family';

  @override
  String upTo(String size) => 'até $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: 'Não foi possível adicionar $names: não é uma imagem.',
    other: 'Não foi possível adicionar $names: não são imagens.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: 'Não foi possível adicionar $names: não é um tipo de arquivo aceito.',
    other:
        'Não foi possível adicionar $names: não são tipos de arquivo '
        'aceitos.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: 'Não foi possível adicionar $names: o arquivo excede $limit.',
    other: 'Não foi possível adicionar $names: os arquivos excedem $limit.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: 'Não foi possível adicionar $names: é uma pasta.',
    other: 'Não foi possível adicionar $names: são pastas.',
  );

  @override
  String refusedMixed(String items) => 'Não foi possível adicionar $items.';

  @override
  String refusedItemNotImage(String name) => '$name (não é uma imagem)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (tipo de arquivo não aceito)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name (maior que $limit)';

  @override
  String refusedItemFolder(String name) => '$name (pasta)';
}
