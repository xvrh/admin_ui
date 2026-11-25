import '../../sections/collection_messages.dart';

/// Japanese [CollectionMessages].
class CollectionMessagesJa extends CollectionMessages {
  const CollectionMessagesJa([super.localeName = 'ja']);

  @override
  String get nothingHereYet => 'まだ何もありません';

  @override
  String get noResultsMessage => '現在の検索条件またはフィルターに一致する項目はありません。';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get sortAscending => '昇順で並べ替え';

  @override
  String get sortDescending => '降順で並べ替え';

  @override
  String get clearSort => '並べ替えを解除';

  @override
  String get pinColumn => '列を固定';

  @override
  String get unpinColumn => '列の固定を解除';

  @override
  String get resetWidth => '幅をリセット';

  @override
  String get hideColumn => '列を非表示';

  @override
  String get manageColumns => '列を管理…';

  @override
  String get columnOptions => '列のオプション';

  @override
  String columnOptionsFor(String column) => '$column 列のオプション';

  @override
  String notSorted(String column) => '$column、並べ替えなし';

  @override
  String sortedAscending(String column) => '$column、昇順';

  @override
  String sortedDescending(String column) => '$column、降順';

  @override
  String selectRow(int row) => '${number(row)} 行目を選択';

  @override
  String get selectAllOnPage => 'このページをすべて選択';

  @override
  String selectCard(int card) => '${number(card)} 番目のカードを選択';

  @override
  String perPage(int size) => '${number(size)} 件/ページ';

  @override
  String get clear => '解除';

  @override
  String allSelected(int total) =>
      plural(total, zero: '選択なし', other: '全 ${number(total)} 件を選択中');

  @override
  String allOf(int total, String selection) =>
      plural(total, other: '$selection（全件）');

  @override
  String selectAllCount(int total) => '全 ${number(total)} 件を選択';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get any => '指定なし';

  @override
  String get from => '開始';

  @override
  String get to => '終了';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get containsPlaceholder => '次を含む…';

  @override
  String clearFilter(String field) => '$field のフィルターをクリア';

  /// A full-width colon, with no space around it.
  @override
  String get valueSeparator => '：';

  @override
  String filterValue(String field, String value) => '$field：$value';

  /// Japanese words the open bounds, and joins two with a wave dash.
  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min〜$max',
    (final min?, null) => '$min 以上',
    (null, final max?) => '$max 以下',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from〜$to',
    (final from?, null) => '$from 以降',
    (null, final to?) => '$to まで',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '「$text」';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a、$b',
    [final first, ...final rest] => '$first 他 ${number(rest.length)} 件',
    [] => '',
  };

  @override
  String get columns => '列';

  @override
  String withHidden(String label, int hidden) =>
      '$label（${number(hidden)} 列が非表示）';

  @override
  String get findColumn => '列を検索';

  @override
  String get showAll => 'すべて表示';

  @override
  String get hideAll => 'すべて非表示';

  @override
  String get noMatchingColumns => '一致する列はありません';

  @override
  String get locked => 'ロック中';

  @override
  String get moveLeft => '左に移動';

  @override
  String get moveRight => '右に移動';

  @override
  String get rename => '名前を変更';

  @override
  String get duplicate => '複製';

  @override
  String get setAsDefault => 'デフォルトに設定';

  @override
  String get moreViews => 'その他のビュー';

  @override
  String get saveAsNewView => '現在の状態を新しいビューとして保存';

  @override
  String get defaultView => 'デフォルト';

  @override
  String viewOptions(String view) => '$view のオプション';

  @override
  String copyOf(String name) => '$name のコピー';

  @override
  String get allViews => 'すべて';

  @override
  String currentView(String view) => 'ビュー：$view';

  @override
  String get saveViewTitle => 'ビューを保存';

  @override
  String get saveViewDescription => '現在のフィルターと並べ替えを保存し、ワンクリックで呼び出せるようにします。';

  @override
  String get renameViewTitle => 'ビューの名前を変更';

  @override
  String get viewName => '名前';

  @override
  String get viewNameRequired => 'ビューの名前を入力してください。';

  @override
  String get viewScope => '共有範囲';

  @override
  String get personalView => '個人用';

  @override
  String get personalViewDescription => '自分だけが閲覧できます';

  @override
  String get sharedView => '共有';

  @override
  String get sharedViewDescription => 'チームの全員が閲覧できます';

  @override
  String get dropHere => 'ここにドロップ';

  @override
  String get noItems => '項目はありません';

  @override
  String moveTo(String column) => '$column に移動';

  @override
  String get moveCard => '移動…';

  @override
  String matchedIn(String field) => '一致：$field';
}
