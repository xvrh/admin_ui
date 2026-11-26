import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_tr.dart';
import 'collection_messages_tr.dart';
import 'display_messages_tr.dart';
import 'fields_messages_tr.dart';
import 'inputs_messages_tr.dart';
import 'shell_messages_tr.dart';

/// Turkish [AdminLocalizations].
class AdminLocalizationsTr extends AdminLocalizations {
  const AdminLocalizationsTr([super.localeName = 'tr']);

  @override
  InputsMessages get inputs => const InputsMessagesTr();

  @override
  DisplayMessages get display => const DisplayMessagesTr();

  @override
  CollectionMessages get collection => const CollectionMessagesTr();

  @override
  FieldsMessages get fields => const FieldsMessagesTr();

  @override
  ShellMessages get shell => const ShellMessagesTr();

  @override
  AssetsMessages get assets => const AssetsMessagesTr();

  @override
  String get apply => 'Uygula';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get remove => 'Kaldır';

  @override
  String removeItem(String name) => '$name öğesini kaldır';

  @override
  String get reset => 'Sıfırla';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get saving => 'Kaydediliyor…';

  @override
  String get edited => 'Düzenlendi';

  @override
  String get unsavedChanges => 'Kaydedilmemiş değişiklikler';

  @override
  String get noResults => 'Sonuç yok';

  @override
  String get noMatches => 'Eşleşme yok';

  @override
  String get couldNotLoad => 'Yüklenemedi';

  @override
  String get searchFailed => 'Arama başarısız oldu';

  @override
  String get loadMore => 'Daha fazla yükle';

  @override
  String get searching => 'Aranıyor…';

  @override
  String get somethingWentWrong => 'Bir hata oluştu';

  @override
  String get somethingWentWrongTryAgain => 'Bir hata oluştu. Tekrar deneyin.';

  @override
  String get notAllowed => 'Buraya erişiminiz yok';

  @override
  String get notAllowedAskAdministrator =>
      'İhtiyacınız varsa bir yöneticiye başvurun.';

  @override
  String get goBack => 'Geri dön';

  @override
  String get moreActions => 'Diğer işlemler';

  @override
  String get clearSelection => 'Seçimi temizle';

  @override
  String get moveUp => 'Yukarı taşı';

  @override
  String get moveDown => 'Aşağı taşı';

  @override
  String get selectPlaceholder => 'Seçin…';

  @override
  String get filterPlaceholder => 'Filtrele…';

  @override
  String get searchPlaceholder => 'Ara…';

  @override
  String get addItem => 'Öğe ekle';

  @override
  String get addRow => 'Satır ekle';

  @override
  String get keyLabel => 'Anahtar';

  @override
  String get valueLabel => 'Değer';

  @override
  String get linkPlaceholder => 'Bağla…';

  @override
  String get restoreLiveVersion => 'Bu alanın yayındaki sürümünü geri yükle';

  @override
  String get assetNotFound => 'Medya bulunamadı';

  @override
  String get assetPreview => 'Medya önizlemesi';

  @override
  String get uploadFailed => 'Yükleme başarısız oldu';

  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: switch ((images, multiple)) {
      (false, false) => 'Bir dosya sürükleyip bırakın veya ',
      (false, true) => 'Dosyaları sürükleyip bırakın veya ',
      (true, false) => 'Bir görsel sürükleyip bırakın veya ',
      (true, true) => 'Görselleri sürükleyip bırakın veya ',
    },
    link: 'göz atın',
    after: '',
  );

  /// Turkish keeps the noun singular after a number: one form.
  @override
  String selectedCount(int count) => plural(
    count,
    zero: 'Hiçbir öğe seçilmedi',
    other: '${number(count)} öğe seçildi',
  );

  /// "3 / 12", as Material's Turkish writes a page's rows.
  @override
  String countOf(int count, int total) => '${number(count)} / ${number(total)}';

  /// CLDR's Turkish units: bayt, kB, MB, GB, TB.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['bayt', 'kB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get copy => 'Kopyala';

  @override
  String get close => 'Kapat';

  @override
  String get clear => 'Metni temizle';

  @override
  String get search => 'Ara';

  @override
  String get more => 'Diğer';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get dismiss => 'Kapat';

  @override
  String get rowsPerPage => 'Sayfa başına satır sayısı:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first-$last / $total';

  @override
  String get previousPage => 'Önceki sayfa';

  @override
  String get nextPage => 'Sonraki sayfa';

  @override
  String get previousMonth => 'Önceki ay';

  @override
  String get nextMonth => 'Gelecek ay';

  @override
  String get today => 'Bugün';

  @override
  String rangeStartDate(String date) => 'Başlangıç tarihi $date';

  @override
  String rangeEndDate(String date) => 'Bitiş tarihi $date';

  @override
  String get selectDate => 'Tarih seçin';

  @override
  String get selectDateRange => 'Aralık seçin';

  @override
  String get navigationMenu => 'Gezinme menüsü';

  @override
  String get expand => 'Genişlet';

  @override
  String get collapse => 'Daralt';

  @override
  String get proceed => 'Devam';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'üst karakter';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Geri Tuşu';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEnd => 'Son';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'Boşluk';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyPrintScreen => 'Ekranı Yazdır';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyFn => 'Fn';
}
