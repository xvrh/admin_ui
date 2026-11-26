import '../../sections/display_messages.dart';

/// Turkish [DisplayMessages].
class DisplayMessagesTr extends DisplayMessages {
  const DisplayMessagesTr([super.localeName = 'tr']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => 'Yükleniyor';

  @override
  String get errorTimeout =>
      'Sunucunun yanıt vermesi çok uzun sürdü. Tekrar deneyin.';

  @override
  String get errorUnreachable =>
      'Sunucuya ulaşılamıyor. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get errorUnreadable => 'Sunucunun yanıtı okunamadı. Tekrar deneyin.';

  @override
  String get errorUnauthorized =>
      'Oturumunuzun süresi doldu. Oturum açıp tekrar deneyin.';

  @override
  String get errorPaymentRequired =>
      'Bunun için ücretli bir plan veya daha fazla kredi gerekiyor.';

  @override
  String get errorForbidden => 'Bunu yapma izniniz yok.';

  @override
  String get errorNotFound => 'Bulunamadı. Taşınmış veya silinmiş olabilir.';

  @override
  String get errorConflict =>
      'Başka bir yerde değiştirildi. Yeniden yükleyip tekrar deneyin.';

  @override
  String get errorTooLarge => 'Sunucunun kabul edemeyeceği kadar büyük.';

  @override
  String get errorRateLimited =>
      'Çok fazla istek gönderildi. Biraz bekleyip tekrar deneyin.';

  @override
  String get errorServer =>
      'Sunucuda bir sorun oluştu. Birazdan tekrar deneyin.';

  @override
  String get errorRequestFailed => 'Sunucu isteği tamamlayamadı.';

  @override
  String get breadcrumb => 'İçerik haritası';

  @override
  String currentPage(String label) => '$label, mevcut sayfa';

  @override
  String get switchPage => 'Sayfa değiştir';

  @override
  String showMore(int count) =>
      plural(count, other: '${number(count)} öğe daha göster');

  @override
  String pageNumber(int page) => 'Sayfa ${number(page)}';

  @override
  String jsonKeys(int count) =>
      plural(count, other: '${number(count)} anahtar');

  @override
  String jsonItems(int count) => plural(count, other: '${number(count)} öğe');

  @override
  String get expandAll => 'Tümünü genişlet';

  @override
  String get collapseAll => 'Tümünü daralt';

  @override
  String get copyJson => 'JSON’u kopyala';

  @override
  String get copyValue => 'Değeri kopyala';

  @override
  String get copyPath => 'Yolu kopyala';

  @override
  String invalidJson(String detail) => 'Geçersiz JSON — $detail';

  @override
  String get logEmpty => 'Henüz çıktı yok';

  @override
  String get zoomArea => 'Yakınlaştırılabilir görünüm';

  @override
  String get zoomAreaHint =>
      'Yakınlaştırmak için kaydırın, gezinmek için sürükleyin; + ve − ile '
      'yakınlaştırın, 0 ile sığdırın, ok tuşlarıyla gezinin.';

  @override
  String get zoomIn => 'Yakınlaştır';

  @override
  String get zoomOut => 'Uzaklaştır';

  @override
  String get zoomToFit => 'Sığdır';

  @override
  String get qrCode => 'QR kodu';

  @override
  String uploadDone(int total) => plural(
    total,
    one: 'Yükleme tamamlandı',
    other: '${number(total)} dosyanın tümü yüklendi',
  );

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} / ${number(total)} yüklendi'
      : '${number(done)} / ${number(total)} yüklendi · '
            '${number(failed)} başarısız';

  @override
  String get clearCompleted => 'Tamamlananları temizle';

  @override
  String get queued => 'Sırada';

  @override
  String get retryUpload => 'Yüklemeyi tekrar dene';

  @override
  String get removeFile => 'Dosyayı kaldır';

  @override
  String get cancelUpload => 'Yüklemeyi iptal et';

  @override
  String get chartEmpty => 'Bu dönem için veri yok';

  @override
  String get heatLess => 'Az';

  @override
  String get heatMore => 'Çok';

  @override
  String statValue(String label, String value) => '$label: $value';

  /// [delta] comes formatted, the percent sign first: "%12 artış".
  @override
  String trendUp(String delta) => '$delta artış';

  @override
  String trendDown(String delta) => '$delta düşüş';

  @override
  String get needsAttention => 'Dikkat gerektirenler';

  @override
  String get recentActivity => 'Son etkinlikler';

  @override
  String get contentMix => 'İçerik dağılımı';

  @override
  String itemsUnit(int count) => plural(count, other: 'öğe');

  @override
  String get allCaughtUp => 'Her şey yolunda — dikkat gerektiren bir şey yok.';

  @override
  String get noRecentActivity => 'Son etkinlik yok';

  @override
  String get noRecentActivityHint =>
      'Düzenlemeler, yayımlamalar ve yüklemeler burada görünecek.';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      'Adım ${number(step)} / ${number(total)}: $title';

  @override
  String get stepCompleted => 'tamamlandı';

  @override
  String get stepCurrent => 'devam ediyor';

  @override
  String get stepUpcoming => 'bekliyor';

  @override
  String get stepError => 'hata';

  @override
  String get addItem => 'Öğe ekle';

  @override
  String get untitled => 'Adsız';

  @override
  String get treeHeader => 'Grup';

  @override
  String get indent => 'Girintiyi artır';

  @override
  String get outdent => 'Girintiyi azalt';

  @override
  String get addChild => 'Alt öğe ekle';

  @override
  String get hideEntry => 'Gizle';

  @override
  String get showEntry => 'Göster';

  @override
  String movedUp(String title) => '$title yukarı taşındı';

  @override
  String movedDown(String title) => '$title aşağı taşındı';

  @override
  String indented(String title) => '$title girintisi artırıldı';

  @override
  String outdented(String title) => '$title girintisi azaltıldı';

  @override
  String get rowMovedUp => 'Yukarı taşındı';

  @override
  String get rowMovedDown => 'Aşağı taşındı';

  @override
  String get rowIndented => 'Girinti artırıldı';

  @override
  String get rowOutdented => 'Girinti azaltıldı';

  @override
  String get resizePanes => 'Bölmeleri yeniden boyutlandır';

  @override
  String get moveLeft => 'Sola taşı';

  @override
  String get moveRight => 'Sağa taşı';

  @override
  String get preview => 'Önizleme';

  /// Turkish capitals keep the dot of i: İ.
  @override
  String get previewHeading => 'ÖNİZLEME';

  @override
  String get noPreviewHeading => 'ÖNİZLEME YOK';

  @override
  String get insertsInline => 'Satır içine eklenir — önizleme gerekmez.';

  @override
  String nothingMatches(String query) => '“$query” ile eşleşen bir şey yok';

  @override
  String get choices => 'Seçenekler';

  @override
  String get diffAdded => 'Eklendi';

  @override
  String get diffRemoved => 'Kaldırıldı';

  @override
  String get diffChanged => 'Değiştirildi';

  @override
  String get diffMoved => 'Taşındı';

  @override
  String get diffUnchanged => 'Değişmedi';

  @override
  String addedCount(int count) => '${number(count)} eklendi';

  @override
  String removedCount(int count) => '${number(count)} kaldırıldı';

  @override
  String changedCount(int count) => '${number(count)} değiştirildi';

  @override
  String movedCount(int count) => '${number(count)} taşındı';

  @override
  String get before => 'Önce';

  @override
  String get after => 'Sonra';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  /// Ordinals take a dot, so the case ending falls on the noun.
  @override
  String movedFromTo(int from, int to) =>
      '${number(from)}. konumdan ${number(to)}. konuma';

  @override
  String get unified => 'Birleşik';

  @override
  String get split => 'Yan yana';

  @override
  String get noChanges => 'Değişiklik yok';

  @override
  String get versionsIdentical => 'Bu iki sürüm aynı.';

  @override
  String get noFieldChanges => 'Alan değişikliği yok.';

  @override
  String get noBlockChanges => 'Blok değişikliği yok.';

  @override
  String get empty => 'Boş';

  @override
  String inserted(String text) => 'eklendi: $text, ';

  @override
  String deleted(String text) => 'silindi: $text, ';

  @override
  String get restore => 'Geri yükle';

  @override
  String get restoreThisVersion => 'Bu sürümü geri yükle';

  @override
  String get restoreThisField => 'Bu alanı geri yükle';

  @override
  String get restoreThisItem => 'Bu öğeyi geri yükle';

  @override
  String get restoreLiveBlock => 'Bu bloğun yayındaki sürümünü geri yükle';

  @override
  String get sharedLane => 'Ortak';

  @override
  String get versionCurrent => 'Güncel';

  @override
  String get versionPublished => 'Yayımlanmış';

  @override
  String get versionRestored => 'Geri yüklenmiş';

  @override
  String get versionArchived => 'Arşivlenmiş';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'Bahsedilecek kişiler';

  @override
  String mentionMatches(int count) =>
      plural(count, other: 'Bahsedilecek ${number(count)} kişi');
}
