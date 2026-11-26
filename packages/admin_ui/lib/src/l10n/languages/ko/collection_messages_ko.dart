import '../../sections/collection_messages.dart';

/// Korean [CollectionMessages].
class CollectionMessagesKo extends CollectionMessages {
  const CollectionMessagesKo([super.localeName = 'ko']);

  @override
  String get nothingHereYet => '아직 항목이 없습니다';

  @override
  String get noResultsMessage => '현재 검색어나 필터와 일치하는 항목이 없습니다.';

  @override
  String get clearFilters => '필터 지우기';

  @override
  String get sortAscending => '오름차순 정렬';

  @override
  String get sortDescending => '내림차순 정렬';

  @override
  String get clearSort => '정렬 해제';

  @override
  String get pinColumn => '열 고정';

  @override
  String get unpinColumn => '열 고정 해제';

  @override
  String get resetWidth => '너비 초기화';

  @override
  String get hideColumn => '열 숨기기';

  @override
  String get manageColumns => '열 관리…';

  @override
  String get columnOptions => '열 옵션';

  @override
  String columnOptionsFor(String column) => '$column 열 옵션';

  @override
  String notSorted(String column) => '$column, 정렬 안 됨';

  @override
  String sortedAscending(String column) => '$column, 오름차순 정렬됨';

  @override
  String sortedDescending(String column) => '$column, 내림차순 정렬됨';

  @override
  String selectRow(int row) => '${number(row)}행 선택';

  @override
  String get selectAllOnPage => '페이지 전체 선택';

  @override
  String selectCard(int card) => '${number(card)}번째 카드 선택';

  @override
  String perPage(int size) => '페이지당 ${number(size)}개';

  @override
  String get clear => '해제';

  @override
  String allSelected(int total) =>
      plural(total, zero: '선택된 항목 없음', other: '전체 ${number(total)}개 선택됨');

  /// 전체 reads as well before one as before many.
  @override
  String allOf(int total, String selection) => '전체 $selection';

  @override
  String selectAllCount(int total) => '전체 ${number(total)}개 선택';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get any => '제한 없음';

  @override
  String get from => '시작일';

  @override
  String get to => '종료일';

  @override
  String get min => '최소';

  @override
  String get max => '최대';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get containsPlaceholder => '포함…';

  @override
  String clearFilter(String field) => '$field 필터 지우기';

  @override
  String get valueSeparator => ': ';

  @override
  String filterValue(String field, String value) => '$field: $value';

  /// Korean writes an open bound as a word after the number, and a range
  /// with a tilde.
  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min~$max',
    (final min?, null) => '$min 이상',
    (null, final max?) => '$max 이하',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from ~ $to',
    (final from?, null) => '$from부터',
    (null, final to?) => '$to까지',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '“$text”';

  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a, $b',
    [final first, ...final rest] => '$first 외 ${number(rest.length)}개',
    [] => '',
  };

  @override
  String get columns => '열';

  @override
  String withHidden(String label, int hidden) =>
      '$label (${number(hidden)}개 숨김)';

  @override
  String get findColumn => '열 찾기';

  @override
  String get showAll => '모두 표시';

  @override
  String get hideAll => '모두 숨기기';

  @override
  String get noMatchingColumns => '일치하는 열 없음';

  @override
  String get locked => '잠김';

  @override
  String get moveLeft => '왼쪽으로 이동';

  @override
  String get moveRight => '오른쪽으로 이동';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get duplicate => '복제';

  @override
  String get setAsDefault => '기본으로 설정';

  @override
  String get moreViews => '다른 보기';

  @override
  String get saveAsNewView => '현재 상태를 새 보기로 저장';

  @override
  String get defaultView => '기본 보기';

  @override
  String viewOptions(String view) => '$view 보기 옵션';

  @override
  String copyOf(String name) => '$name의 사본';

  @override
  String get allViews => '전체';

  @override
  String currentView(String view) => '보기: $view';

  @override
  String get saveViewTitle => '보기 저장';

  @override
  String get saveViewDescription => '현재 필터와 정렬을 저장해 클릭 한 번으로 다시 적용합니다.';

  @override
  String get renameViewTitle => '보기 이름 바꾸기';

  @override
  String get viewName => '이름';

  @override
  String get viewNameRequired => '보기 이름을 입력하세요.';

  @override
  String get viewScope => '공개 범위';

  @override
  String get personalView => '개인';

  @override
  String get personalViewDescription => '나만 볼 수 있음';

  @override
  String get sharedView => '공유';

  @override
  String get sharedViewDescription => '팀원 모두가 볼 수 있음';

  @override
  String get dropHere => '여기에 놓기';

  @override
  String get noItems => '항목 없음';

  /// 열 carries the particle, which would otherwise depend on how [column]
  /// ends.
  @override
  String moveTo(String column) => '$column 열로 이동';

  @override
  String get moveCard => '이동…';

  @override
  String matchedIn(String field) => '일치: $field';
}
