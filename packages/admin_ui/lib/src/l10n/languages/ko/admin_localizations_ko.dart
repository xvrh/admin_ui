import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_ko.dart';
import 'collection_messages_ko.dart';
import 'display_messages_ko.dart';
import 'fields_messages_ko.dart';
import 'inputs_messages_ko.dart';
import 'shell_messages_ko.dart';

/// Korean [AdminLocalizations].
class AdminLocalizationsKo extends AdminLocalizations {
  const AdminLocalizationsKo([super.localeName = 'ko']);

  @override
  InputsMessages get inputs => const InputsMessagesKo();

  @override
  DisplayMessages get display => const DisplayMessagesKo();

  @override
  CollectionMessages get collection => const CollectionMessagesKo();

  @override
  FieldsMessages get fields => const FieldsMessagesKo();

  @override
  ShellMessages get shell => const ShellMessagesKo();

  @override
  AssetsMessages get assets => const AssetsMessagesKo();

  @override
  String get apply => '적용';

  @override
  String get retry => '다시 시도';

  @override
  String get remove => '제거';

  @override
  String removeItem(String name) => '$name 제거';

  @override
  String get reset => '초기화';

  @override
  String get loading => '불러오는 중…';

  @override
  String get saving => '저장 중…';

  @override
  String get edited => '수정됨';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항';

  @override
  String get noResults => '결과 없음';

  @override
  String get noMatches => '일치하는 항목 없음';

  @override
  String get couldNotLoad => '불러올 수 없음';

  @override
  String get searchFailed => '검색 실패';

  @override
  String get loadMore => '더 불러오기';

  @override
  String get searching => '검색 중…';

  @override
  String get somethingWentWrong => '문제가 발생했습니다';

  @override
  String get somethingWentWrongTryAgain => '문제가 발생했습니다. 다시 시도하세요.';

  @override
  String get notAllowed => '접근 권한이 없습니다';

  @override
  String get notAllowedAskAdministrator => '필요하면 관리자에게 요청하세요.';

  @override
  String get goBack => '돌아가기';

  @override
  String get moreActions => '추가 작업';

  @override
  String get clearSelection => '선택 해제';

  @override
  String get moveUp => '위로 이동';

  @override
  String get moveDown => '아래로 이동';

  @override
  String get selectPlaceholder => '선택…';

  @override
  String get filterPlaceholder => '필터…';

  @override
  String get searchPlaceholder => '검색…';

  @override
  String get addItem => '항목 추가';

  @override
  String get addRow => '행 추가';

  @override
  String get keyLabel => '키';

  @override
  String get valueLabel => '값';

  @override
  String get linkPlaceholder => '연결…';

  @override
  String get restoreLiveVersion => '이 필드를 게시된 버전으로 복원';

  @override
  String get assetNotFound => '미디어를 찾을 수 없음';

  @override
  String get assetPreview => '미디어 미리보기';

  @override
  String get uploadFailed => '업로드 실패';

  /// Korean has no plural noun: one file and several read the same.
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (
    before: images ? '이미지를 끌어다 놓거나 ' : '파일을 끌어다 놓거나 ',
    link: '찾아보기',
    after: '',
  );

  @override
  String selectedCount(int count) =>
      plural(count, zero: '선택된 항목 없음', other: '${number(count)}개 선택됨');

  @override
  String countOf(int count, int total) =>
      '${number(total)}개 중 ${number(count)}개';

  /// Korean writes kilobytes as KB.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'KB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get copy => '복사';

  @override
  String get close => '닫기';

  @override
  String get clear => '텍스트 삭제';

  @override
  String get search => '검색';

  @override
  String get more => '더보기';

  @override
  String get selectAll => '전체 선택';

  @override
  String get dismiss => '닫기';

  @override
  String get rowsPerPage => '페이지당 행 수:';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '$total행 중 $first~$last행';

  @override
  String get previousPage => '이전 페이지';

  @override
  String get nextPage => '다음 페이지';

  @override
  String get previousMonth => '지난달';

  @override
  String get nextMonth => '다음 달';

  @override
  String get today => '오늘';

  @override
  String rangeStartDate(String date) => '시작일 $date';

  @override
  String rangeEndDate(String date) => '종료일 $date';

  @override
  String get selectDate => '날짜 선택';

  @override
  String get selectDateRange => '기간 선택';

  @override
  String get navigationMenu => '탐색 메뉴';

  @override
  String get expand => '펼치기';

  @override
  String get collapse => '접기';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => '메타';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => '백스페이스';

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
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PageUp';

  @override
  String get keyboardKeySpace => '스페이스';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyFn => 'Fn';
}
