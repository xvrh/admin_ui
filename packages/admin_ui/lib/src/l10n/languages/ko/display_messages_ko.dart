import '../../sections/display_messages.dart';

/// Korean [DisplayMessages].
class DisplayMessagesKo extends DisplayMessages {
  const DisplayMessagesKo([super.localeName = 'ko']);

  @override
  String joinParts(List<String> parts) => parts.join(', ');

  @override
  String get loadingLabel => '불러오는 중';

  @override
  String get errorTimeout => '서버 응답 시간이 초과되었습니다. 다시 시도하세요.';

  @override
  String get errorUnreachable => '서버에 연결할 수 없습니다. 네트워크 연결을 확인하고 다시 시도하세요.';

  @override
  String get errorUnreadable => '서버 응답을 읽을 수 없습니다. 다시 시도하세요.';

  @override
  String get errorUnauthorized => '세션이 만료되었습니다. 로그인한 후 다시 시도하세요.';

  @override
  String get errorPaymentRequired => '유료 요금제나 추가 크레딧이 필요합니다.';

  @override
  String get errorForbidden => '이 작업을 수행할 권한이 없습니다.';

  @override
  String get errorNotFound => '찾을 수 없습니다. 이동되었거나 삭제되었을 수 있습니다.';

  @override
  String get errorConflict => '다른 곳에서 변경되었습니다. 새로고침한 후 다시 시도하세요.';

  @override
  String get errorTooLarge => '서버에서 허용하는 크기를 초과합니다.';

  @override
  String get errorRateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도하세요.';

  @override
  String get errorServer => '서버에 문제가 발생했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get errorRequestFailed => '서버에서 요청을 완료할 수 없습니다.';

  @override
  String get breadcrumb => '이동 경로';

  @override
  String currentPage(String label) => '$label, 현재 페이지';

  @override
  String get switchPage => '페이지 전환';

  @override
  String showMore(int count) => plural(count, other: '${number(count)}개 더보기');

  @override
  String pageNumber(int page) => '${number(page)}페이지';

  @override
  String jsonKeys(int count) => plural(count, other: '키 ${number(count)}개');

  @override
  String jsonItems(int count) => plural(count, other: '항목 ${number(count)}개');

  @override
  String get expandAll => '모두 펼치기';

  @override
  String get collapseAll => '모두 접기';

  @override
  String get copyJson => 'JSON 복사';

  @override
  String get copyValue => '값 복사';

  @override
  String get copyPath => '경로 복사';

  @override
  String invalidJson(String detail) => '잘못된 JSON: $detail';

  @override
  String get logEmpty => '아직 출력 없음';

  @override
  String get zoomArea => '확대/축소 영역';

  @override
  String get zoomAreaHint =>
      '스크롤하여 확대/축소하고 드래그하여 이동하세요. +/− 키로 확대/축소, 0 키로 '
      '화면 맞춤, 화살표 키로 이동합니다.';

  @override
  String get zoomIn => '확대';

  @override
  String get zoomOut => '축소';

  @override
  String get zoomToFit => '화면에 맞추기';

  @override
  String get qrCode => 'QR 코드';

  @override
  String uploadDone(int total) =>
      plural(total, other: '${number(total)}개 업로드 완료');

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(total)}개 중 ${number(done)}개 업로드됨'
      : '${number(total)}개 중 ${number(done)}개 업로드됨 · '
            '${number(failed)}개 실패';

  @override
  String get clearCompleted => '완료된 항목 지우기';

  @override
  String get queued => '대기 중';

  @override
  String get retryUpload => '업로드 다시 시도';

  @override
  String get removeFile => '파일 제거';

  @override
  String get cancelUpload => '업로드 취소';

  @override
  String get chartEmpty => '이 기간의 데이터 없음';

  @override
  String get heatLess => '적음';

  @override
  String get heatMore => '많음';

  @override
  String statValue(String label, String value) => '$label: $value';

  @override
  String trendUp(String delta) => '$delta 증가';

  @override
  String trendDown(String delta) => '$delta 감소';

  @override
  String get needsAttention => '확인 필요';

  @override
  String get recentActivity => '최근 활동';

  @override
  String get contentMix => '콘텐츠 구성';

  @override
  String itemsUnit(int count) => '항목';

  @override
  String get allCaughtUp => '모두 처리했습니다. 확인이 필요한 항목이 없습니다.';

  @override
  String get noRecentActivity => '최근 활동 없음';

  @override
  String get noRecentActivityHint => '수정, 게시, 업로드 내역이 여기에 표시됩니다.';

  /// Korean counts after the noun, with the general counter 개.
  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '$label ${number(count)}개'
      : '$label ${number(count)}개, $caption';

  @override
  String stepOf(int step, int total, String title) =>
      '${number(total)}단계 중 ${number(step)}단계: $title';

  @override
  String get stepCompleted => '완료됨';

  @override
  String get stepCurrent => '진행 중';

  @override
  String get stepUpcoming => '예정';

  @override
  String get stepError => '오류';

  @override
  String get addItem => '항목 추가';

  @override
  String get untitled => '제목 없음';

  @override
  String get treeHeader => '그룹';

  @override
  String get indent => '들여쓰기';

  @override
  String get outdent => '내어쓰기';

  @override
  String get addChild => '하위 항목 추가';

  @override
  String get hideEntry => '숨기기';

  @override
  String get showEntry => '표시';

  /// 항목 carries the particle, which would otherwise depend on how
  /// [title] ends.
  @override
  String movedUp(String title) => '$title 항목을 위로 이동했습니다';

  @override
  String movedDown(String title) => '$title 항목을 아래로 이동했습니다';

  @override
  String indented(String title) => '$title 항목을 들여썼습니다';

  @override
  String outdented(String title) => '$title 항목을 내어썼습니다';

  @override
  String get rowMovedUp => '위로 이동했습니다';

  @override
  String get rowMovedDown => '아래로 이동했습니다';

  @override
  String get rowIndented => '들여썼습니다';

  @override
  String get rowOutdented => '내어썼습니다';

  @override
  String get resizePanes => '패널 크기 조정';

  @override
  String get moveLeft => '왼쪽으로 이동';

  @override
  String get moveRight => '오른쪽으로 이동';

  @override
  String get preview => '미리보기';

  @override
  String get previewHeading => '미리보기';

  @override
  String get noPreviewHeading => '미리보기 없음';

  @override
  String get insertsInline => '본문에 바로 삽입되므로 미리보기가 필요하지 않습니다.';

  @override
  String nothingMatches(String query) => '“$query”에 일치하는 항목 없음';

  @override
  String get choices => '선택 항목';

  @override
  String get diffAdded => '추가됨';

  @override
  String get diffRemoved => '삭제됨';

  @override
  String get diffChanged => '변경됨';

  @override
  String get diffMoved => '이동됨';

  @override
  String get diffUnchanged => '변경 없음';

  @override
  String addedCount(int count) => plural(count, other: '${number(count)}개 추가됨');

  @override
  String removedCount(int count) =>
      plural(count, other: '${number(count)}개 삭제됨');

  @override
  String changedCount(int count) =>
      plural(count, other: '${number(count)}개 변경됨');

  @override
  String movedCount(int count) => plural(count, other: '${number(count)}개 이동됨');

  @override
  String get before => '변경 전';

  @override
  String get after => '변경 후';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  /// 번째 takes the particle, which would otherwise depend on how the
  /// number is read.
  @override
  String movedFromTo(int from, int to) =>
      '${number(from)}번째에서 ${number(to)}번째로';

  @override
  String get unified => '통합';

  @override
  String get split => '분할';

  @override
  String get noChanges => '변경 사항 없음';

  @override
  String get versionsIdentical => '두 버전이 동일합니다.';

  @override
  String get noFieldChanges => '변경된 필드가 없습니다.';

  @override
  String get noBlockChanges => '변경된 블록이 없습니다.';

  @override
  String get empty => '비어 있음';

  @override
  String inserted(String text) => '삽입됨: $text, ';

  @override
  String deleted(String text) => '삭제됨: $text, ';

  @override
  String get restore => '복원';

  @override
  String get restoreThisVersion => '이 버전 복원';

  @override
  String get restoreThisField => '이 필드 복원';

  @override
  String get restoreThisItem => '이 항목 복원';

  @override
  String get restoreLiveBlock => '이 블록을 게시된 버전으로 복원';

  @override
  String get sharedLane => '공통';

  @override
  String get versionCurrent => '현재';

  @override
  String get versionPublished => '게시됨';

  @override
  String get versionRestored => '복원됨';

  @override
  String get versionArchived => '보관됨';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => '멘션할 사람';

  @override
  String mentionMatches(int count) =>
      plural(count, other: '멘션할 사람 ${number(count)}명');
}
