import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Japanese [InputsMessages].
class InputsMessagesJa extends InputsMessages {
  const InputsMessagesJa([super.localeName = 'ja']);

  @override
  String get confirm => 'OK';

  @override
  String get copied => 'コピーしました';

  @override
  String get copyFailed => 'コピーできませんでした';

  @override
  String get undo => '元に戻す';

  @override
  String get showMore => 'さらに表示';

  @override
  String get showLess => '表示を減らす';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを非表示';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String get couldNotLoadResults => '結果を読み込めませんでした';

  /// Spoken as the position among all, which reads better than a slash.
  @override
  String optionOf(String label, int position, int count) =>
      '$label、${number(count)} 件中 ${number(position)} 番目';

  @override
  String get dateRange => '期間';

  @override
  String get clearDates => '日付をクリア';

  /// Japanese joins a span with a wave dash.
  @override
  String dateSpan(String start, String end) => '$start〜$end';

  @override
  String lastDays(int count) => plural(count, other: '過去 ${number(count)} 日間');

  @override
  String get thisMonth => '今月';

  @override
  String get lastMonth => '先月';

  @override
  String get yearToDate => '年初から今日まで';

  @override
  String get searchOrJumpTo => '検索または移動先を入力…';

  @override
  String get recent => '最近使用した項目';

  @override
  String get selectAResult => '結果を選択してください';

  @override
  String matchedIn(String place) => '$place に一致';

  @override
  String get matchedInContent => 'コンテンツに一致';

  @override
  String get run => '実行';

  @override
  String get open => '開く';

  @override
  String get typeToSearch => '入力して検索';

  @override
  String noResultsFor(String query) => '「$query」に一致する結果はありません';

  @override
  String resultCount(int count) =>
      plural(count, zero: '結果はありません', other: '${number(count)} 件の結果');

  @override
  String get navigateHint => '移動';

  @override
  String get selectHint => '選択';

  @override
  String get closeHint => '閉じる';

  @override
  String get keysUpDown => '上下の矢印キー';

  @override
  String get keyEnter => 'Enter キー';

  @override
  String get keyEscape => 'Esc キー';

  @override
  String get fieldsGroup => 'フィールド';

  @override
  String get notifications => '通知';

  @override
  String get allCaughtUp => '新しい通知はありません';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get unread => '未読';

  @override
  String get allNotifications => 'すべて';

  @override
  String get markAsRead => '既読にする';

  @override
  String get markAsUnread => '未読にする';

  @override
  String get viewAll => 'すべて表示';

  @override
  String get couldNotLoadNotifications => '通知を読み込めませんでした';

  @override
  String unreadCount(String title, int count) => '$title、未読 ${number(count)} 件';

  @override
  String get appearanceTheme => 'テーマ';

  @override
  String get appearanceMode => 'モード';

  @override
  String get modeLight => 'ライト';

  @override
  String get modeDark => 'ダーク';

  @override
  String get modeSystem => 'システム';

  @override
  String get accentColour => 'アクセントカラー';

  @override
  String get themeAccent => 'テーマカラー';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => 'クリムゾン',
    'Violet' => 'バイオレット',
    'Teal' => 'ティール',
    'Amber' => 'アンバー',
    _ => name,
  };

  @override
  String get tableDensity => 'テーブルの表示密度';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => 'コンパクト',
    TableDensity.standard => '標準',
    TableDensity.comfortable => 'ゆったり',
  };
}
