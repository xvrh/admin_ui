import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_ja.dart';
import 'collection_messages_ja.dart';
import 'display_messages_ja.dart';
import 'fields_messages_ja.dart';
import 'inputs_messages_ja.dart';
import 'shell_messages_ja.dart';

/// Japanese [AdminLocalizations].
class AdminLocalizationsJa extends AdminLocalizations {
  const AdminLocalizationsJa([super.localeName = 'ja']);

  @override
  InputsMessages get inputs => const InputsMessagesJa();

  @override
  DisplayMessages get display => const DisplayMessagesJa();

  @override
  CollectionMessages get collection => const CollectionMessagesJa();

  @override
  FieldsMessages get fields => const FieldsMessagesJa();

  @override
  ShellMessages get shell => const ShellMessagesJa();

  @override
  AssetsMessages get assets => const AssetsMessagesJa();

  @override
  String get apply => '適用';

  @override
  String get retry => '再試行';

  @override
  String get remove => '削除';

  @override
  String removeItem(String name) => '$name を削除';

  @override
  String get reset => 'リセット';

  @override
  String get loading => '読み込み中…';

  @override
  String get saving => '保存中…';

  @override
  String get edited => '編集済み';

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String get noResults => '結果はありません';

  @override
  String get noMatches => '一致する項目はありません';

  @override
  String get couldNotLoad => '読み込めませんでした';

  @override
  String get searchFailed => '検索に失敗しました';

  @override
  String get loadMore => 'さらに読み込む';

  @override
  String get searching => '検索中…';

  @override
  String get somethingWentWrong => 'エラーが発生しました';

  @override
  String get somethingWentWrongTryAgain => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get notAllowed => 'アクセス権がありません';

  @override
  String get notAllowedAskAdministrator => '必要な場合は、管理者にお問い合わせください。';

  @override
  String get goBack => '戻る';

  @override
  String get moreActions => 'その他の操作';

  @override
  String get clearSelection => '選択を解除';

  @override
  String get moveUp => '上に移動';

  @override
  String get moveDown => '下に移動';

  @override
  String get selectPlaceholder => '選択…';

  @override
  String get filterPlaceholder => '絞り込み…';

  @override
  String get searchPlaceholder => '検索…';

  @override
  String get addItem => '項目を追加';

  @override
  String get addRow => '行を追加';

  @override
  String get keyLabel => 'キー';

  @override
  String get valueLabel => '値';

  @override
  String get linkPlaceholder => 'リンク先を選択…';

  @override
  String get restoreLiveVersion => 'このフィールドの公開版を復元';

  @override
  String get assetNotFound => 'メディアが見つかりません';

  @override
  String get assetPreview => 'メディアのプレビュー';

  @override
  String get uploadFailed => 'アップロードに失敗しました';

  /// Japanese has one form for a file and for files.
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: images ? '画像をドラッグ＆ドロップ、または' : 'ファイルをドラッグ＆ドロップ、または',
    link: images ? '画像を選択' : 'ファイルを選択',
    after: '',
  );

  @override
  String selectedCount(int count) =>
      plural(count, zero: '選択なし', other: '${number(count)} 件を選択中');

  @override
  String countOf(int count, int total) => '${number(count)} / ${number(total)}';

  /// Japanese writes bytes as a word, and the larger units in capitals.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['バイト', 'KB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get copy => 'コピー';

  @override
  String get close => '閉じる';

  @override
  String get clear => 'テキストを消去';

  @override
  String get search => '検索';

  @override
  String get more => 'その他';

  @override
  String get selectAll => 'すべてを選択';

  @override
  String get dismiss => '閉じる';

  @override
  String get rowsPerPage => 'ページあたりの行数:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$first - $last 行（合計 $total 行）';

  @override
  String get previousPage => '前のページ';

  @override
  String get nextPage => '次のページ';

  @override
  String get previousMonth => '前月';

  @override
  String get nextMonth => '来月';

  @override
  String get today => '今日';

  @override
  String rangeStartDate(String date) => '開始日 $date';

  @override
  String rangeEndDate(String date) => '終了日 $date';

  @override
  String get selectDate => '日付の選択';

  @override
  String get selectDateRange => '期間の選択';

  @override
  String get navigationMenu => 'ナビゲーション メニュー';

  @override
  String get expand => '展開';

  @override
  String get collapse => '折りたたむ';

  @override
  String get proceed => '続行';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'PageDown';

  @override
  String get keyboardKeyPageUp => 'PageUp';

  @override
  String get keyboardKeySpace => 'Space';

  @override
  String get keyboardKeyCapsLock => 'CapsLock';

  @override
  String get keyboardKeyPrintScreen => 'Printscreen';

  @override
  String get keyboardKeyScrollLock => 'ScrollLock';

  @override
  String get keyboardKeyNumLock => 'NumLock';

  @override
  String get keyboardKeyFn => 'Fn';
}
