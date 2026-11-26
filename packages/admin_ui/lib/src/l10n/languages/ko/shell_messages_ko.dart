import '../../sections/shell_messages.dart';

/// Korean [ShellMessages].
class ShellMessagesKo extends ShellMessages {
  const ShellMessagesKo([super.localeName = 'ko']);

  @override
  String get navigation => '탐색';

  @override
  String get mainContent => '본문';

  @override
  String get openNavigation => '탐색 메뉴 열기';

  @override
  String get closeNavigation => '탐색 메뉴 닫기';

  @override
  String navItemWithBadge(String label, String badge) => '$label, $badge';

  @override
  String get discard => '폐기';

  @override
  String get publish => '게시';

  @override
  String get morePublishOptions => '게시 옵션 더보기';

  @override
  String get publishing => '게시 중…';

  @override
  String get saved => '저장됨';

  @override
  String get published => '게시됨';

  @override
  String statusWithDetail(String status, String detail) => '$status · $detail';

  @override
  String get couldNotSave => '저장 실패';

  @override
  String get couldNotPublish => '게시 실패';

  @override
  String fieldsNeedAttention(int count) =>
      plural(count, other: '확인이 필요한 필드 ${number(count)}개');

  @override
  String get noChangesToPublish => '게시할 변경 사항 없음';

  @override
  String get noChanges => '변경 사항 없음';

  @override
  String get discardChangesTitle => '변경 사항을 폐기할까요?';

  @override
  String get discardChangesMessage => '저장하지 않은 변경 사항이 사라집니다.';

  @override
  String get leaveWhileSavingTitle => '저장 중입니다. 그래도 나갈까요?';

  @override
  String get leaveWhileSavingMessage =>
      '변경 사항을 아직 저장하고 있습니다. 나간 후 저장에 실패하면 변경 사항이 '
      '사라집니다.';

  @override
  String get leave => '나가기';

  @override
  String get email => '이메일';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => '비밀번호';

  @override
  String get signIn => '로그인';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get or => '또는';

  /// 항목 carries the particle, which would otherwise depend on how
  /// [label] ends.
  @override
  String isRequired(String label) => '$label 항목은 필수입니다';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get confirmNewPassword => '새 비밀번호 확인';

  @override
  String get currentPassword => '현재 비밀번호';

  @override
  String get setPassword => '비밀번호 설정';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String passwordTooShort(int minLength) =>
      plural(minLength, other: '${number(minLength)}자 이상 사용하세요.');

  @override
  String get passwordsDontMatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get strengthWeak => '약함';

  @override
  String get strengthFair => '보통';

  @override
  String get strengthGood => '좋음';

  @override
  String get strengthStrong => '강함';

  @override
  String get verificationCode => '인증 코드';

  @override
  String get verify => '확인';

  @override
  String codeIncomplete(int length) =>
      plural(length, other: '코드는 ${number(length)}자리입니다.');

  @override
  String get recoveryCode => '복구 코드';

  @override
  String get useRecoveryCode => '복구 코드 사용';

  @override
  String get useAuthenticatorApp => '인증 앱 사용';

  @override
  String get backToSignIn => '로그인으로 돌아가기';

  @override
  String get authenticatorQrCode => '인증 앱용 QR 코드';

  @override
  String get cantScanQrCode => '코드를 스캔할 수 없나요?';

  @override
  String get enterSetupKey => '대신 앱에 이 키를 입력하세요.';

  @override
  String get copySetupKey => '키 복사';

  @override
  String get copyAllCodes => '모두 복사';

  @override
  String get savedRecoveryCodes => '이 코드를 저장했습니다';

  @override
  String get addTagHint => '추가…';

  @override
  String get shared => '공통';
}
