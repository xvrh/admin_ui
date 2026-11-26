import '../../sections/collection_messages.dart';

/// Turkish [CollectionMessages].
class CollectionMessagesTr extends CollectionMessages {
  const CollectionMessagesTr([super.localeName = 'tr']);

  @override
  String get nothingHereYet => 'Henüz burada bir şey yok';

  @override
  String get noResultsMessage =>
      'Mevcut arama veya filtrelerle eşleşen bir şey yok.';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get sortAscending => 'Artan düzende sırala';

  @override
  String get sortDescending => 'Azalan düzende sırala';

  @override
  String get clearSort => 'Sıralamayı temizle';

  @override
  String get pinColumn => 'Sütunu sabitle';

  @override
  String get unpinColumn => 'Sütunun sabitlemesini kaldır';

  @override
  String get resetWidth => 'Genişliği sıfırla';

  @override
  String get hideColumn => 'Sütunu gizle';

  @override
  String get manageColumns => 'Sütunları yönet…';

  @override
  String get columnOptions => 'Sütun seçenekleri';

  @override
  String columnOptionsFor(String column) => '$column sütunu seçenekleri';

  @override
  String notSorted(String column) => '$column, sıralanmamış';

  @override
  String sortedAscending(String column) => '$column, artan düzende sıralı';

  @override
  String sortedDescending(String column) => '$column, azalan düzende sıralı';

  /// Ordinals take a dot, so the case ending falls on the noun.
  @override
  String selectRow(int row) => '${number(row)}. satırı seç';

  @override
  String get selectAllOnPage => 'Sayfadaki tüm öğeleri seç';

  @override
  String selectCard(int card) => '${number(card)}. kartı seç';

  @override
  String perPage(int size) => '${number(size)} / sayfa';

  @override
  String get clear => 'Temizle';

  @override
  String allSelected(int total) => plural(
    total,
    zero: 'Hiçbir öğe seçilmedi',
    one: '${number(total)} öğe seçildi',
    other: '${number(total)} öğenin tümü seçildi',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: 'Tüm sonuçlar: $selection');

  @override
  String selectAllCount(int total) => '${number(total)} öğenin tümünü seç';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get any => 'Fark etmez';

  @override
  String get from => 'Başlangıç';

  @override
  String get to => 'Bitiş';

  @override
  String get min => 'En az';

  @override
  String get max => 'En fazla';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get containsPlaceholder => 'İçerir…';

  @override
  String clearFilter(String field) => '$field filtresini temizle';

  @override
  String get valueSeparator => ': ';

  @override
  String filterValue(String field, String value) => '$field: $value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  /// The case ending falls on "tarih", not on the formatted date.
  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from – $to',
    (final from?, null) => '$from tarihinden itibaren',
    (null, final to?) => '$to tarihine kadar',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '“$text”';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => 'Sütunlar';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)} gizli)';

  @override
  String get findColumn => 'Sütun bul';

  @override
  String get showAll => 'Tümünü göster';

  @override
  String get hideAll => 'Tümünü gizle';

  @override
  String get noMatchingColumns => 'Eşleşen sütun yok';

  @override
  String get locked => 'Kilitli';

  @override
  String get moveLeft => 'Sola taşı';

  @override
  String get moveRight => 'Sağa taşı';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get duplicate => 'Çoğalt';

  @override
  String get setAsDefault => 'Varsayılan yap';

  @override
  String get moreViews => 'Diğer görünümler';

  @override
  String get saveAsNewView => 'Yeni görünüm olarak kaydet';

  @override
  String get defaultView => 'Varsayılan';

  @override
  String viewOptions(String view) => '$view görünümü seçenekleri';

  @override
  String copyOf(String name) => '$name kopyası';

  @override
  String get allViews => 'Tümü';

  @override
  String currentView(String view) => 'Görünüm: $view';

  @override
  String get saveViewTitle => 'Görünümü kaydet';

  @override
  String get saveViewDescription =>
      'Mevcut filtreleri ve sıralamayı tek tıkla yeniden uygulamanızı sağlar.';

  @override
  String get renameViewTitle => 'Görünümü yeniden adlandır';

  @override
  String get viewName => 'Ad';

  @override
  String get viewNameRequired => 'Görünüme bir ad verin.';

  @override
  String get viewScope => 'Kimler görebilir';

  @override
  String get personalView => 'Kişisel';

  @override
  String get personalViewDescription => 'Yalnızca siz görebilirsiniz';

  @override
  String get sharedView => 'Paylaşılan';

  @override
  String get sharedViewDescription => 'Ekipteki herkes görebilir';

  @override
  String get dropHere => 'Buraya bırakın';

  @override
  String get noItems => 'Öğe yok';

  @override
  String moveTo(String column) => '$column sütununa taşı';

  @override
  String get moveCard => 'Şuraya taşı…';

  @override
  String matchedIn(String field) => 'Eşleşme: $field';
}
