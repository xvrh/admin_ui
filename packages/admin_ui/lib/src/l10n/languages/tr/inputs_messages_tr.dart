import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Turkish [InputsMessages].
class InputsMessagesTr extends InputsMessages {
  const InputsMessagesTr([super.localeName = 'tr']);

  @override
  String get confirm => 'Onayla';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get copyFailed => 'Kopyalanamadı';

  @override
  String get undo => 'Geri al';

  @override
  String get showMore => 'Daha fazla göster';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get couldNotLoadResults => 'Sonuçlar yüklenemedi';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(position)} / ${number(count)}';

  @override
  String get dateRange => 'Tarih aralığı';

  @override
  String get clearDates => 'Tarihleri temizle';

  @override
  String dateSpan(String start, String end) => '$start – $end';

  @override
  String lastDays(int count) =>
      plural(count, other: 'Son ${number(count)} gün');

  @override
  String get thisMonth => 'Bu ay';

  @override
  String get lastMonth => 'Geçen ay';

  @override
  String get yearToDate => 'Yılbaşından bugüne';

  @override
  String get searchOrJumpTo => 'Ara veya şuraya git…';

  @override
  String get recent => 'Son kullanılanlar';

  @override
  String get selectAResult => 'Bir sonuç seçin';

  @override
  String matchedIn(String place) => '$place içinde eşleşti';

  @override
  String get matchedInContent => 'İçerikte eşleşti';

  @override
  String get run => 'Çalıştır';

  @override
  String get open => 'Aç';

  @override
  String get typeToSearch => 'Aramak için yazın';

  @override
  String noResultsFor(String query) => '“$query” için sonuç yok';

  @override
  String resultCount(int count) =>
      plural(count, zero: 'Sonuç yok', other: '${number(count)} sonuç');

  /// Read after the key: "↑↓ gezinmek için".
  @override
  String get navigateHint => 'gezinmek için';

  @override
  String get selectHint => 'seçmek için';

  @override
  String get closeHint => 'kapatmak için';

  @override
  String get keysUpDown => 'Yukarı ve aşağı oklar';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyEscape => 'Escape';

  @override
  String get fieldsGroup => 'Alanlar';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get allCaughtUp => 'Her şeyi gördünüz';

  @override
  String get markAllRead => 'Tümünü okundu olarak işaretle';

  @override
  String get unread => 'Okunmamış';

  @override
  String get allNotifications => 'Tümü';

  @override
  String get markAsRead => 'Okundu olarak işaretle';

  @override
  String get markAsUnread => 'Okunmadı olarak işaretle';

  @override
  String get viewAll => 'Tümünü görüntüle';

  @override
  String get couldNotLoadNotifications => 'Bildirimler yüklenemedi';

  @override
  String unreadCount(String title, int count) =>
      '$title, ${number(count)} okunmamış';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceMode => 'Mod';

  @override
  String get modeLight => 'Açık';

  @override
  String get modeDark => 'Koyu';

  @override
  String get modeSystem => 'Sistem';

  @override
  String get accentColour => 'Vurgu rengi';

  @override
  String get themeAccent => 'Tema rengi';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'Kızıl',
    'Violet' => 'Menekşe',
    'Teal' => 'Petrol mavisi',
    'Amber' => 'Kehribar',
    _ => name,
  };

  @override
  String get tableDensity => 'Tablo yoğunluğu';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'Sıkı',
    TableDensity.standard => 'Standart',
    TableDensity.comfortable => 'Rahat',
  };
}
