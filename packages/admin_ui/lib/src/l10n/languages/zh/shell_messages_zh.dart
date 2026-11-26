import '../../sections/shell_messages.dart';

/// Simplified Chinese [ShellMessages].
class ShellMessagesZh extends ShellMessages {
  const ShellMessagesZh([super.localeName = 'zh']);

  @override
  String get navigation => '导航';

  @override
  String get mainContent => '主要内容';

  @override
  String get openNavigation => '打开导航';

  @override
  String get closeNavigation => '关闭导航';

  @override
  String navItemWithBadge(String label, String badge) => '$label，$badge';

  @override
  String get discard => '放弃';

  @override
  String get publish => '发布';

  @override
  String get morePublishOptions => '更多发布选项';

  @override
  String get publishing => '正在发布…';

  @override
  String get saved => '已保存';

  @override
  String get published => '已发布';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => '无法保存';

  @override
  String get couldNotPublish => '无法发布';

  @override
  String fieldsNeedAttention(int count) =>
      plural(count, other: '${number(count)} 个字段需要处理');

  @override
  String get noChangesToPublish => '没有可发布的更改';

  @override
  String get noChanges => '无更改';

  @override
  String get discardChangesTitle => '放弃更改？';

  @override
  String get discardChangesMessage => '未保存的更改将会丢失。';

  @override
  String get leaveWhileSavingTitle => '正在保存，仍要离开吗？';

  @override
  String get leaveWhileSavingMessage => '更改仍在保存中。如果离开后保存失败，这些更改将会丢失。';

  @override
  String get leave => '离开';

  @override
  String get email => '邮箱';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => '密码';

  @override
  String get signIn => '登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get or => '或';

  /// [label] is a Chinese field label, which takes no space.
  @override
  String isRequired(String label) => '请输入$label';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get setPassword => '设置密码';

  @override
  String get changePassword => '修改密码';

  @override
  String passwordTooShort(int minLength) =>
      plural(minLength, other: '请至少使用 ${number(minLength)} 个字符。');

  @override
  String get passwordsDontMatch => '两次输入的密码不一致。';

  @override
  String get strengthWeak => '弱';

  @override
  String get strengthFair => '一般';

  @override
  String get strengthGood => '良好';

  @override
  String get strengthStrong => '强';

  @override
  String get verificationCode => '验证码';

  @override
  String get verify => '验证';

  @override
  String codeIncomplete(int length) =>
      plural(length, other: '验证码为 ${number(length)} 位数字。');

  @override
  String get recoveryCode => '恢复码';

  @override
  String get useRecoveryCode => '使用恢复码';

  @override
  String get useAuthenticatorApp => '使用身份验证器应用';

  @override
  String get backToSignIn => '返回登录';

  @override
  String get authenticatorQrCode => '用于身份验证器应用的二维码';

  @override
  String get cantScanQrCode => '无法扫描二维码？';

  @override
  String get enterSetupKey => '请改为在应用中输入此密钥。';

  @override
  String get copySetupKey => '复制密钥';

  @override
  String get copyAllCodes => '全部复制';

  @override
  String get savedRecoveryCodes => '我已保存这些恢复码';

  @override
  String get addTagHint => '添加…';

  @override
  String get shared => '通用';
}
