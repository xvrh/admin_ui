import '../../sections/fields_messages.dart';

/// Korean [FieldsMessages].
class FieldsMessagesKo extends FieldsMessages {
  const FieldsMessagesKo([super.localeName = 'ko']);

  @override
  String quoted(String text) => '“$text”';

  @override
  String get filterOrAdd => '필터 또는 추가…';

  @override
  String maxSelected(int max) => '최대 ${number(max)}개 선택됨';

  @override
  String createOption(String value) => '${quoted(value)} 만들기';

  @override
  String get onLabel => '켜짐';

  @override
  String get offLabel => '꺼짐';

  @override
  String get selectDate => '날짜 선택…';

  @override
  String get selectDateTime => '날짜 및 시간 선택…';

  @override
  String get selectTime => '시간 선택…';

  @override
  String get clearDate => '날짜 지우기';

  @override
  String get year => '연도';

  @override
  String get month => '월';

  @override
  String get day => '일';

  @override
  String get hour => '시';

  @override
  String get minute => '분';

  /// Korean forms write the placeholders in Latin letters, as YYYY-MM-DD.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens =>
      (year: 'YYYY', month: 'MM', day: 'DD', hour: 'HH', minute: 'MM');

  @override
  String numberLike(String example) => '$example 형식의 숫자를 입력하세요';

  @override
  String numberBetween(String min, String max) => '$min에서 $max 사이의 숫자를 입력하세요';

  @override
  String numberAtLeast(String min) => '$min 이상의 값을 입력하세요';

  @override
  String numberAtMost(String max) => '$max 이하의 값을 입력하세요';

  @override
  String get decrease => '감소';

  @override
  String get increase => '증가';

  @override
  String get pickColor => '색상 선택…';

  @override
  String get hexDigitsError => '16진수 3자리 또는 6자리를 입력하세요';

  @override
  String get setColor => '설정';

  @override
  String get validJson => '유효한 JSON';

  @override
  String jsonError(int line, int column, String detail) =>
      '줄 ${number(line)}, 열 ${number(column)}  $detail';

  @override
  String get formatJson => '서식 지정';

  @override
  String get plainText => '일반 텍스트';

  @override
  String get addTag => '태그 추가…';

  @override
  String get noTags => '태그 없음';

  @override
  String get noEntries => '항목 없음';

  @override
  String duplicateKey(String key) => '중복된 키 ${quoted(key)}: 아래쪽 행이 적용됩니다';

  @override
  String get duplicateKeys => '중복된 키: 아래쪽 행이 적용됩니다';

  @override
  String get removeRow => '행 제거';

  @override
  String get noMedia => '미디어 없음';

  @override
  String retryItem(String name) => '$name 다시 시도';

  @override
  String cancelUpload(String name) => '$name 업로드 취소';

  @override
  String get cover => '대표';

  @override
  String get processing => '처리 중…';

  @override
  String get addImage => '이미지 추가';

  @override
  String get addFile => '파일 추가';

  @override
  String get noReference => '연결된 항목 없음';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String get replaceReference => '교체';

  @override
  String get typeToSearch => '검색어 입력…';

  @override
  String removeItemAt(int position) => '${number(position)}번째 항목 제거';

  @override
  String get noItemsYet => '아직 항목이 없습니다.';

  @override
  String get help => '도움말';

  @override
  String helpFor(String field) => '$field 도움말';

  @override
  String get versionHistory => '버전 기록';

  @override
  String get pendingEdit => '대기 중인 수정 사항';

  @override
  String get baseline => '게시됨';

  @override
  String editedDetail(String detail) => '수정됨 · $detail';

  @override
  String comments(int count) =>
      plural(count, zero: '댓글', other: '댓글 ${number(count)}개');

  @override
  String commentsHeading(int count) => '댓글 · ${number(count)}';

  @override
  String get resolve => '해결';

  @override
  String get replyPlaceholder => '답글 입력…';

  @override
  String get sendReply => '답글 보내기';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: '이 필드에 댓글 달기',
    other: '미해결 스레드 ${number(openThreads)}개',
  );

  @override
  String get openThread => '스레드 열기';

  @override
  String get translationSource => '원본';

  @override
  String get translationUpToDate => '최신';

  @override
  String get translationNeedsReview => '검토 필요';

  @override
  String get translationOutdated => '오래됨';

  @override
  String get translationMissing => '누락';

  @override
  String get retranslate => '다시 번역';

  @override
  String retranslateLanguage(String language) => '$language 다시 번역';

  @override
  String get sourceChanged => '번역 후 원본이 변경됨';

  @override
  String sourceIn(String language) => '$language 원본';

  @override
  String fieldInLanguage(String field, String language) => '$field, $language';

  @override
  String get languages => '언어';

  @override
  String get languageMenuHint => '탭하면 전환하고, 체크하면 나란히 비교합니다.';

  @override
  String compareLanguage(String language) => '$language 비교';

  /// "Edit [language]", which needs no particle after the name.
  @override
  String switchToLanguage(String language) => '$language 수정';

  @override
  String get editing => '수정 중';

  @override
  String get inherited => '상속됨';

  @override
  String get custom => '사용자 지정';

  @override
  String inheritedDescription(String source) =>
      '$source 값을 그대로 따르며 자동으로 업데이트됩니다';

  @override
  String customDescription(String? noun) => '${noun ?? '값'} 직접 지정';

  @override
  String get valueRequired => '필수 항목입니다';

  @override
  String tooShort(int min) => plural(min, other: '${number(min)}자 이상 입력하세요');

  @override
  String tooLong(int max) => plural(max, other: '${number(max)}자 이하로 입력하세요');

  @override
  String get invalidEmail => '올바른 이메일 주소를 입력하세요';

  @override
  String get invalidUrl => '올바른 웹 주소를 입력하세요';

  @override
  String get invalidFormat => '올바른 형식으로 입력하세요';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) =>
      plural(count, other: '항목을 ${number(count)}개 이상 추가하세요');

  @override
  String keepAtMost(int count) =>
      plural(count, other: '항목을 ${number(count)}개 이하로 유지하세요');

  @override
  String get checking => '확인 중…';

  @override
  String get optionalMarker => '(선택)';

  @override
  String validationSummaryTitle(int count) =>
      plural(count, other: '수정이 필요한 필드 ${number(count)}개');

  @override
  String jumpToField(String label) => '$label 필드로 이동';

  @override
  String fieldMessage(String label, String message) => '$label: $message';

  @override
  String get wizardNext => '다음';

  @override
  String get wizardBack => '이전';

  @override
  String wizardStepBlocked(int count) =>
      plural(count, other: '계속하려면 필드 ${number(count)}개를 수정하세요');
}
