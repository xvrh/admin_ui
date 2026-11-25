import '../../sections/fields_messages.dart';

/// Turkish [FieldsMessages].
class FieldsMessagesTr extends FieldsMessages {
  const FieldsMessagesTr([super.localeName = 'tr']);

  @override
  String quoted(String text) => '“$text”';

  @override
  String get filterOrAdd => 'Filtrele veya ekle…';

  @override
  String maxSelected(int max) => '${number(max)} seçim sınırına ulaşıldı';

  @override
  String createOption(String value) => '${quoted(value)} oluştur';

  @override
  String get onLabel => 'Açık';

  @override
  String get offLabel => 'Kapalı';

  @override
  String get selectDate => 'Tarih seçin…';

  @override
  String get selectDateTime => 'Tarih ve saat seçin…';

  @override
  String get selectTime => 'Saat seçin…';

  @override
  String get clearDate => 'Tarihi temizle';

  @override
  String get year => 'Yıl';

  @override
  String get month => 'Ay';

  @override
  String get day => 'Gün';

  @override
  String get hour => 'Saat';

  @override
  String get minute => 'Dakika';

  /// Yıl, ay, gün, saat, dakika: GG.AA.YYYY and SS:DD, as Turkish forms
  /// write them.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'YYYY', month: 'AA', day: 'GG', hour: 'SS', minute: 'DD');

  @override
  String numberLike(String example) => '$example gibi bir sayı girin';

  @override
  String numberBetween(String min, String max) =>
      '$min ile $max arasında bir sayı girin';

  @override
  String numberAtLeast(String min) => 'En az $min girin';

  @override
  String numberAtMost(String max) => 'En fazla $max girin';

  @override
  String get decrease => 'Azalt';

  @override
  String get increase => 'Artır';

  @override
  String get pickColor => 'Renk seçin…';

  @override
  String get hexDigitsError => '3 veya 6 onaltılık basamak girin';

  @override
  String get setColor => 'Ayarla';

  @override
  String get validJson => 'Geçerli JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      'Satır ${number(line)}:${number(column)}  $detail';

  @override
  String get formatJson => 'Biçimlendir';

  @override
  String get plainText => 'Düz metin';

  @override
  String get addTag => 'Etiket ekle…';

  @override
  String get noTags => 'Etiket yok';

  @override
  String get noEntries => 'Girdi yok';

  @override
  String duplicateKey(String key) =>
      'Yinelenen anahtar ${quoted(key)} — alttaki satır kullanılır';

  @override
  String get duplicateKeys => 'Yinelenen anahtarlar — alttaki satır kullanılır';

  @override
  String get removeRow => 'Satırı kaldır';

  @override
  String get noMedia => 'Medya yok';

  @override
  String retryItem(String name) => '$name dosyasını yeniden yükle';

  @override
  String cancelUpload(String name) => '$name yüklemesini iptal et';

  @override
  String get cover => 'Kapak';

  @override
  String get processing => 'İşleniyor…';

  @override
  String get addImage => 'Görsel ekle';

  @override
  String get addFile => 'Dosya ekle';

  @override
  String get noReference => 'Referans yok';

  @override
  String get unavailable => 'Kullanılamıyor';

  @override
  String get replaceReference => 'Değiştir';

  @override
  String get typeToSearch => 'Aramak için yazın…';

  /// Ordinals take a dot, so the case ending falls on the noun.
  @override
  String removeItemAt(int position) => '${number(position)}. öğeyi kaldır';

  @override
  String get noItemsYet => 'Henüz öğe yok.';

  @override
  String get help => 'Yardım';

  @override
  String helpFor(String field) => '$field için yardım';

  @override
  String get versionHistory => 'Sürüm geçmişi';

  @override
  String get pendingEdit => 'Bekleyen değişiklik';

  @override
  String get baseline => 'Yayında';

  @override
  String editedDetail(String detail) => 'Düzenlendi · $detail';

  @override
  String comments(int count) =>
      plural(count, zero: 'Yorumlar', other: '${number(count)} yorum');

  @override
  String commentsHeading(int count) => 'Yorumlar · ${number(count)}';

  @override
  String get resolve => 'Çözümle';

  @override
  String get replyPlaceholder => 'Yanıtla…';

  @override
  String get sendReply => 'Yanıtı gönder';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'Bu alana yorum yap',
    other: '${number(openThreads)} açık yorum dizisi',
  );

  @override
  String get openThread => 'Yorum dizisini aç';

  @override
  String get translationSource => 'Kaynak';

  @override
  String get translationUpToDate => 'Güncel';

  @override
  String get translationNeedsReview => 'İnceleme gerekiyor';

  @override
  String get translationOutdated => 'Güncel değil';

  @override
  String get translationMissing => 'Eksik';

  @override
  String get retranslate => 'Yeniden çevir';

  @override
  String retranslateLanguage(String language) =>
      '$language diline yeniden çevir';

  @override
  String get sourceChanged => 'Bu çeviri yapıldıktan sonra kaynak değişti';

  @override
  String sourceIn(String language) => '$language kaynak';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => 'Diller';

  @override
  String get languageMenuHint =>
      'Geçmek için dokunun · yan yana karşılaştırmak için işaretleyin.';

  @override
  String compareLanguage(String language) => '$language ile karşılaştır';

  @override
  String switchToLanguage(String language) => '$language diline geç';

  @override
  String get editing => 'düzenleniyor';

  @override
  String get inherited => 'Devralınan';

  @override
  String get custom => 'Özel';

  /// The case ending falls on "değer", not on the language's name.
  @override
  String inheritedDescription(String source) =>
      '$source değerini izler — otomatik güncellenir';

  @override
  String customDescription(String? noun) =>
      'Özel bir ${noun ?? 'değer'} belirleyin';

  @override
  String get valueRequired => 'Zorunlu';

  @override
  String tooShort(int min) =>
      plural(min, other: 'En az ${number(min)} karakter girin');

  @override
  String tooLong(int max) =>
      plural(max, other: 'En fazla ${number(max)} karakter girin');

  @override
  String get invalidEmail => 'Geçerli bir e-posta adresi girin';

  @override
  String get invalidUrl => 'Geçerli bir web adresi girin';

  @override
  String get invalidFormat => 'Beklenen biçimde bir değer girin';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) =>
      plural(count, other: 'En az ${number(count)} öğe ekleyin');

  @override
  String keepAtMost(int count) =>
      plural(count, other: 'En fazla ${number(count)} öğe bırakın');

  @override
  String get checking => 'Kontrol ediliyor…';

  @override
  String get optionalMarker => '(isteğe bağlı)';

  @override
  String validationSummaryTitle(int count) =>
      plural(count, other: '${number(count)} alanın düzeltilmesi gerekiyor');

  @override
  String jumpToField(String label) => '$label alanına git';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => 'İleri';

  @override
  String get wizardBack => 'Geri';

  @override
  String wizardStepBlocked(int count) =>
      plural(count, other: 'Devam etmek için ${number(count)} alanı düzeltin');
}
