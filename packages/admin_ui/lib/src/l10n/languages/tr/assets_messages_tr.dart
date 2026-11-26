import '../../sections/assets_messages.dart';

/// Turkish [AssetsMessages].
class AssetsMessagesTr extends AssetsMessages {
  const AssetsMessagesTr([super.localeName = 'tr']);

  @override
  String get assets => 'Medya';

  @override
  String get loadingAssets => 'Medya yükleniyor…';

  @override
  String get couldNotLoadAssets => 'Medya yüklenemedi';

  @override
  String get noMatchingAssets => 'Eşleşen medya yok';

  @override
  String get noMatchingAssetsHint => 'Farklı bir arama veya filtre deneyin.';

  @override
  String get noAssetsYet => 'Henüz medya yok';

  @override
  String get noAssetsYetHint =>
      'Kitaplığınızı oluşturmak için görsel ve dosya yükleyin.';

  @override
  String assetCount(int count) =>
      plural(count, other: '${number(count)} medya öğesi');

  @override
  String assetsShown(int shown, int total) =>
      '${number(shown)} / ${assetCount(total)}';

  @override
  String get searchAssets => 'Medyada ara';

  @override
  String get filterByType => 'Türe göre filtrele';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => 'Tüm türler';

  @override
  String get typeImages => 'Görseller';

  @override
  String get typeVideos => 'Videolar';

  @override
  String get typeAudio => 'Ses';

  @override
  String get typeDocuments => 'Belgeler';

  @override
  String get typeOther => 'Diğer';

  @override
  String get kindImage => 'Görsel';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindAudio => 'Ses';

  @override
  String get kindDocument => 'Belge';

  @override
  String get kindOther => 'Diğer';

  @override
  String get view => 'Görünüm';

  @override
  String get gridView => 'Izgara görünümü';

  @override
  String get listView => 'Liste görünümü';

  @override
  String get libraryTab => 'Kitaplık';

  @override
  String get uploadTab => 'Yükle';

  @override
  String get pickerTitle => 'Medya seçin';

  @override
  String get select => 'Seç';

  @override
  String get loadingMore => 'Daha fazlası yükleniyor…';

  @override
  String get dropToUpload => 'Yüklemek için bırakın';

  @override
  String couldNotLoadMore(String reason) => 'Daha fazlası yüklenemedi. $reason';

  @override
  String get uploadIncomplete => 'Yükleme tamamlanamadı. Tekrar deneyin.';

  @override
  String get asset => 'Medya';

  @override
  String get type => 'Tür';

  @override
  String get size => 'Boyut';

  @override
  String get dimensions => 'Ölçüler';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => 'Alternatif metin';

  @override
  String get defaultAltText => 'Varsayılan alternatif metin';

  @override
  String get defaultAltTextHelp =>
      'Kullanıldığı yerde değiştirilmedikçe bu medyanın göründüğü her yerde '
      'kullanılır.';

  @override
  String get saveAltText => 'Alternatif metni kaydet';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'URL’yi kopyala';

  @override
  String get aspectFree => 'Serbest';

  @override
  String get imageUnavailable => 'Görsel kullanılamıyor';

  @override
  String get cropArea => 'Görsel kırpma alanı';

  @override
  String get cropAreaHint =>
      'Kırpmak için tutamaçları sürükleyin. Ok tuşlarıyla ince ayar yapın; '
      'daha büyük adımlar için Shift tuşunu basılı tutun.';

  @override
  String get positionArea => 'Görsel konumlandırma alanı';

  @override
  String get positionAreaHint =>
      'Konumlandırmak için sürükleyin, yakınlaştırmak için kaydırın; ok '
      'tuşlarıyla ince ayar yapın.';

  @override
  String get zoom => 'Yakınlaştırma';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => 'Düzleştir';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => 'Sola döndür';

  @override
  String get rotateRight => 'Sağa döndür';

  @override
  String get flipHorizontal => 'Yatay çevir';

  @override
  String get flipVertical => 'Dikey çevir';

  @override
  String get useImage => 'Görseli kullan';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    other:
        'Lisanslama, görseli kitaplığınıza ekler ve ${number(downloads)} '
        'indirme hakkı kullanır',
  );

  @override
  String get selectImageToLicense => 'Lisanslamak için bir görsel seçin';

  @override
  String get findStockImages => 'Stok görsel bulun';

  @override
  String get noResultsHint =>
      'Farklı bir arama deneyin veya filtreleri gevşetin.';

  @override
  String stockSearchPrompt(String provider) =>
      '$provider üzerindeki milyonlarca görselde arama yapmak için yazın.';

  @override
  String providerResults(String provider) => '$provider sonuçları';

  @override
  String resultCount(int count) =>
      plural(count, other: '${number(count)} sonuç');

  @override
  String resultsShown(int shown, int total) =>
      '${number(shown)} / ${resultCount(total)}';

  @override
  String searchProvider(String provider) => '$provider içinde ara';

  @override
  String get orientation => 'Yön';

  @override
  String get anyOrientation => 'Tüm yönler';

  @override
  String get horizontal => 'Yatay';

  @override
  String get vertical => 'Dikey';

  @override
  String get square => 'Kare';

  @override
  String get imageType => 'Görsel türü';

  @override
  String get anyType => 'Tüm türler';

  @override
  String get photos => 'Fotoğraflar';

  @override
  String get illustrations => 'İllüstrasyonlar';

  @override
  String get vectors => 'Vektörler';

  @override
  String licenseFrom(String provider) => '$provider üzerinden lisansla';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    other:
        'Görseli kitaplığınıza ekler ve $provider planınızdan '
        '${number(downloads)} indirme hakkı kullanır.',
  );

  @override
  String get couldNotLicense => 'Bu görsel lisanslanamadı';

  @override
  String get licenseAndAdd => 'Lisansla ve ekle';

  @override
  String get couldNotLoadSizes => 'Boyutlar yüklenemedi';

  @override
  String editItem(String name) => 'Düzenle: $name';

  @override
  String get done => 'Bitti';

  @override
  String get couldNotLoadPreview => 'Önizleme yüklenemedi';

  @override
  String get uploading => 'Yükleme sürüyor';

  @override
  String get replace => 'Değiştir';

  @override
  String get choose => 'Seç';

  @override
  String get editCrop => 'Kırpmayı düzenle';

  @override
  String get cropAndFocalPoint => 'Kırpma ve odak noktası';

  @override
  String get imagesOnly => 'Yalnızca görseller';

  @override
  String get typeText => 'Metin';

  /// [family] is a MIME code, kept as it is: Dart's capitals would turn
  /// its i into I, not İ.
  @override
  String familyFiles(String family) =>
      family.isEmpty ? 'Dosyalar' : '$family dosyaları';

  @override
  String upTo(String size) => 'en fazla $size';

  @override
  String get listSeparator => ', ';

  @override
  String refusedNotImage(String names, int count) => plural(
    count,
    one: '$names eklenemedi: görsel değil.',
    other: '$names eklenemedi: bunlar görsel değil.',
  );

  @override
  String refusedNotSupported(String names, int count) => plural(
    count,
    one: '$names eklenemedi: dosya türü desteklenmiyor.',
    other: '$names eklenemedi: dosya türleri desteklenmiyor.',
  );

  @override
  String refusedTooLarge(String names, int count, String limit) => plural(
    count,
    one: '$names eklenemedi: dosya $limit sınırını aşıyor.',
    other: '$names eklenemedi: dosyalar $limit sınırını aşıyor.',
  );

  @override
  String refusedFolder(String names, int count) => plural(
    count,
    one: '$names eklenemedi: bu bir klasör.',
    other: '$names eklenemedi: bunlar klasör.',
  );

  @override
  String refusedMixed(String items) => '$items eklenemedi.';

  @override
  String refusedItemNotImage(String name) => '$name (görsel değil)';

  @override
  String refusedItemNotSupported(String name) =>
      '$name (desteklenmeyen dosya türü)';

  @override
  String refusedItemTooLarge(String name, String limit) =>
      '$name ($limit sınırını aşıyor)';

  @override
  String refusedItemFolder(String name) => '$name (klasör)';
}
