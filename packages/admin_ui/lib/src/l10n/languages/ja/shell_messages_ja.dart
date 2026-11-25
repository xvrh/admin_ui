import '../../sections/shell_messages.dart';

/// Japanese [ShellMessages].
class ShellMessagesJa extends ShellMessages {
  const ShellMessagesJa([super.localeName = 'ja']);

  @override
  String get navigation => 'ナビゲーション';

  @override
  String get mainContent => 'メインコンテンツ';

  @override
  String get openNavigation => 'ナビゲーションを開く';

  @override
  String get closeNavigation => 'ナビゲーションを閉じる';

  @override
  String navItemWithBadge(String label, String badge) => '$label、$badge';

  @override
  String get discard => '破棄';

  @override
  String get publish => '公開';

  @override
  String get morePublishOptions => 'その他の公開オプション';

  @override
  String get publishing => '公開中…';

  @override
  String get saved => '保存済み';

  @override
  String get published => '公開済み';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => '保存できませんでした';

  @override
  String get couldNotPublish => '公開できませんでした';

  @override
  String fieldsNeedAttention(int count) =>
      plural(count, other: '確認が必要なフィールドが ${number(count)} 件あります');

  @override
  String get noChangesToPublish => '公開する変更はありません';

  @override
  String get noChanges => '変更はありません';

  @override
  String get discardChangesTitle => '変更を破棄しますか？';

  @override
  String get discardChangesMessage => '保存されていない変更は失われます。';

  @override
  String get leaveWhileSavingTitle => '保存中です。このまま移動しますか？';

  @override
  String get leaveWhileSavingMessage => '変更はまだ保存中です。移動した後に保存が失敗すると、変更は失われます。';

  @override
  String get leave => '移動';

  @override
  String get email => 'メールアドレス';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => 'パスワード';

  @override
  String get signIn => 'ログイン';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get or => 'または';

  @override
  String isRequired(String label) => '$label を入力してください';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmPassword => 'パスワード（確認用）';

  @override
  String get confirmNewPassword => '新しいパスワード（確認用）';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get setPassword => 'パスワードを設定';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String passwordTooShort(int minLength) =>
      plural(minLength, other: '${number(minLength)} 文字以上にしてください。');

  @override
  String get passwordsDontMatch => 'パスワードが一致しません。';

  @override
  String get strengthWeak => '弱い';

  @override
  String get strengthFair => '普通';

  @override
  String get strengthGood => '良い';

  @override
  String get strengthStrong => '強い';

  @override
  String get addTagHint => '追加…';

  @override
  String get shared => '共通';
}
