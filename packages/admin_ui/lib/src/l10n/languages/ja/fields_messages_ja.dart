import '../../sections/fields_messages.dart';

/// Japanese [FieldsMessages].
class FieldsMessagesJa extends FieldsMessages {
  const FieldsMessagesJa([super.localeName = 'ja']);

  /// Corner brackets, which need no space beside the words around them.
  @override
  String quoted(String text) => '「$text」';

  @override
  String get filterOrAdd => '絞り込みまたは追加…';

  @override
  String maxSelected(int max) => '上限の ${number(max)} 件に達しました';

  @override
  String createOption(String value) => '${quoted(value)}を作成';

  @override
  String get onLabel => 'オン';

  @override
  String get offLabel => 'オフ';

  @override
  String get selectDate => '日付を選択…';

  @override
  String get selectDateTime => '日時を選択…';

  @override
  String get selectTime => '時刻を選択…';

  @override
  String get clearDate => '日付をクリア';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String get hour => '時';

  @override
  String get minute => '分';

  /// Year, month, day, hour and minute, as Japanese date fields label
  /// their cells: one character each, so a masked field shows its blanks.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens => (year: '年', month: '月', day: '日', hour: '時', minute: '分');

  @override
  String numberLike(String example) => '数値を入力してください（例：$example）';

  @override
  String numberBetween(String min, String max) => '$min から $max までの数値を入力してください';

  @override
  String numberAtLeast(String min) => '$min 以上の値を入力してください';

  @override
  String numberAtMost(String max) => '$max 以下の値を入力してください';

  @override
  String get decrease => '減らす';

  @override
  String get increase => '増やす';

  @override
  String get pickColor => '色を選択…';

  @override
  String get hexDigitsError => '3 桁または 6 桁の 16 進数を入力してください';

  @override
  String get setColor => '設定';

  @override
  String get validJson => '有効な JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      '${number(line)} 行 ${number(column)} 列：$detail';

  @override
  String get formatJson => '整形';

  @override
  String get plainText => 'プレーンテキスト';

  @override
  String get addTag => 'タグを追加…';

  @override
  String get noTags => 'タグはありません';

  @override
  String get noEntries => '項目はありません';

  @override
  String duplicateKey(String key) => 'キー${quoted(key)}が重複しているため、下の行が優先されます';

  @override
  String get duplicateKeys => 'キーが重複しているため、下の行が優先されます';

  @override
  String get removeRow => '行を削除';

  @override
  String get noMedia => 'メディアはありません';

  @override
  String retryItem(String name) => '$name を再試行';

  @override
  String cancelUpload(String name) => '$name のアップロードをキャンセル';

  @override
  String get cover => 'カバー';

  @override
  String get processing => '処理中…';

  @override
  String get addImage => '画像を追加';

  @override
  String get addFile => 'ファイルを追加';

  @override
  String get noReference => 'リンクはありません';

  @override
  String get unavailable => '利用できません';

  @override
  String get replaceReference => '置き換え';

  @override
  String get typeToSearch => '入力して検索…';

  @override
  String removeItemAt(int position) => '${number(position)} 番目の項目を削除';

  @override
  String get noItemsYet => 'まだ項目はありません。';

  @override
  String get help => 'ヘルプ';

  @override
  String helpFor(String field) => '$field のヘルプ';

  @override
  String get versionHistory => 'バージョン履歴';

  @override
  String get pendingEdit => '保留中の編集';

  @override
  String get baseline => '公開版';

  @override
  String editedDetail(String detail) => '編集済み · $detail';

  @override
  String comments(int count) =>
      plural(count, zero: 'コメント', other: 'コメント ${number(count)} 件');

  @override
  String commentsHeading(int count) => 'コメント · ${number(count)}';

  @override
  String get resolve => '解決';

  @override
  String get replyPlaceholder => '返信…';

  @override
  String get sendReply => '返信を送信';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: 'このフィールドにコメント',
    other: '未解決のスレッド ${number(openThreads)} 件',
  );

  @override
  String get openThread => 'スレッドを開く';

  @override
  String get translationSource => '翻訳元';

  @override
  String get translationUpToDate => '最新';

  @override
  String get translationNeedsReview => '要確認';

  @override
  String get translationOutdated => '要更新';

  @override
  String get translationMissing => '未翻訳';

  @override
  String get retranslate => '再翻訳';

  @override
  String retranslateLanguage(String language) => '$language に再翻訳';

  @override
  String get sourceChanged => 'この翻訳の作成後に翻訳元が変更されました';

  @override
  String sourceIn(String language) => '翻訳元（$language）';

  @override
  String fieldInLanguage(String field, String language) => '$field、$language';

  @override
  String get languages => '言語';

  @override
  String get languageMenuHint => 'タップで切り替え · チェックを入れると並べて比較できます。';

  @override
  String compareLanguage(String language) => '$language と比較';

  @override
  String switchToLanguage(String language) => '$language に切り替え';

  @override
  String get editing => '編集中';

  @override
  String get inherited => '継承';

  @override
  String get custom => 'カスタム';

  @override
  String inheritedDescription(String source) => '$source と同じ値を使用し、自動的に更新されます';

  @override
  String customDescription(String? noun) => '独自の${noun ?? '値'}を設定';

  @override
  String get valueRequired => '必須項目です';

  @override
  String tooShort(int min) =>
      plural(min, other: '${number(min)} 文字以上で入力してください');

  @override
  String tooLong(int max) => plural(max, other: '${number(max)} 文字以内で入力してください');

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get invalidUrl => '有効な URL を入力してください';

  @override
  String get invalidFormat => '正しい形式で入力してください';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) =>
      plural(count, other: '${number(count)} 件以上追加してください');

  @override
  String keepAtMost(int count) =>
      plural(count, other: '${number(count)} 件以内にしてください');

  @override
  String get checking => '確認中…';

  @override
  String get optionalMarker => '（任意）';

  @override
  String validationSummaryTitle(int count) =>
      plural(count, other: '修正が必要なフィールドが ${number(count)} 件あります');

  @override
  String jumpToField(String label) => '$label に移動';

  @override
  String fieldMessage(String label, String message) => '$label：$message';

  @override
  String get wizardNext => '次へ';

  @override
  String get wizardBack => '戻る';

  @override
  String wizardStepBlocked(int count) =>
      plural(count, other: '続行するには ${number(count)} 件のフィールドを修正してください');
}
