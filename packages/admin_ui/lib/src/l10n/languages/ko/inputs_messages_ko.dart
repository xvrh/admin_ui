import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Korean [InputsMessages].
class InputsMessagesKo extends InputsMessages {
  const InputsMessagesKo([super.localeName = 'ko']);

  @override
  String get confirm => '확인';

  @override
  String get copied => '복사됨';

  @override
  String get copyFailed => '복사 실패';

  @override
  String get undo => '실행취소';

  @override
  String get showMore => '더보기';

  @override
  String get showLess => '간략히';

  @override
  String get showPassword => '비밀번호 표시';

  @override
  String get hidePassword => '비밀번호 숨기기';

  @override
  String get clearSearch => '검색어 지우기';

  @override
  String get couldNotLoadResults => '결과를 불러올 수 없음';

  @override
  String optionOf(String label, int position, int count) =>
      '$label, ${number(count)}개 중 ${number(position)}번째';

  @override
  String get dateRange => '기간';

  @override
  String get clearDates => '날짜 지우기';

  /// Korean joins a span with a tilde.
  @override
  String dateSpan(String start, String end) => '$start ~ $end';

  @override
  String lastDays(int count) => plural(count, other: '최근 ${number(count)}일');

  @override
  String get thisMonth => '이번 달';

  @override
  String get lastMonth => '지난달';

  @override
  String get yearToDate => '연초부터 오늘까지';

  @override
  String get searchOrJumpTo => '검색 또는 이동…';

  @override
  String get recent => '최근 항목';

  @override
  String get selectAResult => '결과를 선택하세요';

  @override
  String matchedIn(String place) => '$place에서 일치';

  @override
  String get matchedInContent => '콘텐츠에서 일치';

  @override
  String get run => '실행';

  @override
  String get open => '열기';

  @override
  String get typeToSearch => '검색어를 입력하세요';

  @override
  String noResultsFor(String query) => '“$query”에 대한 결과 없음';

  @override
  String resultCount(int count) =>
      plural(count, zero: '결과 없음', other: '결과 ${number(count)}개');

  @override
  String get navigateHint => '이동';

  @override
  String get selectHint => '선택';

  @override
  String get closeHint => '닫기';

  @override
  String get keysUpDown => '위쪽 및 아래쪽 화살표 키';

  @override
  String get keyEnter => 'Enter 키';

  @override
  String get keyEscape => 'Esc 키';

  @override
  String get fieldsGroup => '필드';

  @override
  String get notifications => '알림';

  @override
  String get allCaughtUp => '모두 확인했습니다';

  @override
  String get markAllRead => '모두 읽음으로 표시';

  @override
  String get unread => '읽지 않음';

  @override
  String get allNotifications => '전체';

  @override
  String get markAsRead => '읽음으로 표시';

  @override
  String get markAsUnread => '읽지 않음으로 표시';

  @override
  String get viewAll => '모두 보기';

  @override
  String get couldNotLoadNotifications => '알림을 불러올 수 없음';

  @override
  String unreadCount(String title, int count) =>
      '$title, 읽지 않음 ${number(count)}개';

  @override
  String get appearanceTheme => '테마';

  @override
  String get appearanceMode => '모드';

  @override
  String get modeLight => '라이트';

  @override
  String get modeDark => '다크';

  @override
  String get modeSystem => '시스템';

  @override
  String get accentColour => '강조 색상';

  @override
  String get themeAccent => '테마 색상';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => '진홍색',
    'Violet' => '보라색',
    'Teal' => '청록색',
    'Amber' => '호박색',
    _ => name,
  };

  @override
  String get tableDensity => '표 밀도';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => '좁게',
    TableDensity.standard => '기본',
    TableDensity.comfortable => '넓게',
  };
}
