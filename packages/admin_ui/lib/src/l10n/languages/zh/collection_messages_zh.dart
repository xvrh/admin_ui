import '../../sections/collection_messages.dart';

/// Simplified Chinese [CollectionMessages].
class CollectionMessagesZh extends CollectionMessages {
  const CollectionMessagesZh([super.localeName = 'zh']);

  @override
  String get nothingHereYet => '暂无内容';

  @override
  String get noResultsMessage => '没有与当前搜索或筛选条件匹配的内容。';

  @override
  String get clearFilters => '清除筛选条件';

  @override
  String get sortAscending => '升序排列';

  @override
  String get sortDescending => '降序排列';

  @override
  String get clearSort => '清除排序';

  @override
  String get pinColumn => '固定列';

  @override
  String get unpinColumn => '取消固定列';

  @override
  String get resetWidth => '重置列宽';

  @override
  String get hideColumn => '隐藏列';

  @override
  String get manageColumns => '管理列…';

  @override
  String get columnOptions => '列选项';

  @override
  String columnOptionsFor(String column) => '“$column”列选项';

  @override
  String notSorted(String column) => '$column，未排序';

  @override
  String sortedAscending(String column) => '$column，升序';

  @override
  String sortedDescending(String column) => '$column，降序';

  @override
  String selectRow(int row) => '选择第 ${number(row)} 行';

  @override
  String get selectAllOnPage => '全选本页';

  @override
  String selectCard(int card) => '选择第 ${number(card)} 张卡片';

  @override
  String perPage(int size) => '${number(size)} 条/页';

  @override
  String get clear => '清除';

  @override
  String allSelected(int total) => plural(
    total,
    zero: '未选择任何项',
    one: '已选择 ${number(total)} 项',
    other: '已选择全部 ${number(total)} 项',
  );

  @override
  String allOf(int total, String selection) =>
      plural(total, one: selection, other: '全部结果：$selection');

  @override
  String selectAllCount(int total) => '选择全部 ${number(total)} 项';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get any => '不限';

  @override
  String get from => '开始';

  @override
  String get to => '结束';

  @override
  String get min => '最小值';

  @override
  String get max => '最大值';

  @override
  String get clearAll => '全部清除';

  @override
  String get containsPlaceholder => '包含…';

  @override
  String clearFilter(String field) => '清除“$field”筛选条件';

  /// The full-width colon, with no space after it.
  @override
  String get valueSeparator => '：';

  @override
  String filterValue(String field, String value) => '$field：$value';

  @override
  String numberRange(String? min, String? max) => switch ((min, max)) {
    (final min?, final max?) => '$min–$max',
    (final min?, null) => '≥ $min',
    (null, final max?) => '≤ $max',
    (null, null) => '',
  };

  @override
  String dateRange(String? from, String? to) => switch ((from, to)) {
    (final from?, final to?) => '$from 至 $to',
    (final from?, null) => '$from 起',
    (null, final to?) => '截至 $to',
    (null, null) => '',
  };

  @override
  String quoted(String text) => '“$text”';

  /// Two labels take the enumeration comma.
  @override
  String optionsSummary(List<String> labels) => switch (labels) {
    [final only] => only,
    [final a, final b] => '$a、$b',
    [final first, ...final rest] => '$first +${number(rest.length)}',
    [] => '',
  };

  @override
  String get columns => '列';

  @override
  String withHidden(String label, int hidden) =>
      '$label（已隐藏 ${number(hidden)} 列）';

  @override
  String get findColumn => '查找列';

  @override
  String get showAll => '全部显示';

  @override
  String get hideAll => '全部隐藏';

  @override
  String get noMatchingColumns => '没有匹配的列';

  @override
  String get locked => '已锁定';

  @override
  String get moveLeft => '左移';

  @override
  String get moveRight => '右移';

  @override
  String get rename => '重命名';

  @override
  String get duplicate => '创建副本';

  @override
  String get setAsDefault => '设为默认';

  @override
  String get moreViews => '更多视图';

  @override
  String get saveAsNewView => '将当前设置另存为新视图';

  @override
  String get defaultView => '默认';

  @override
  String viewOptions(String view) => '“$view”视图选项';

  @override
  String copyOf(String name) => '$name 副本';

  @override
  String get allViews => '全部';

  @override
  String currentView(String view) => '视图：$view';

  @override
  String get saveViewTitle => '保存视图';

  @override
  String get saveViewDescription => '保存当前的筛选条件和排序，一键即可再次使用。';

  @override
  String get renameViewTitle => '重命名视图';

  @override
  String get viewName => '名称';

  @override
  String get viewNameRequired => '请为视图命名。';

  @override
  String get viewScope => '可见范围';

  @override
  String get personalView => '个人';

  @override
  String get personalViewDescription => '仅自己可见';

  @override
  String get sharedView => '共享';

  @override
  String get sharedViewDescription => '团队所有成员可见';

  @override
  String get dropHere => '拖放到此处';

  @override
  String get noItems => '暂无项目';

  @override
  String moveTo(String column) => '移至“$column”';

  @override
  String get moveCard => '移至…';

  @override
  String matchedIn(String field) => '匹配：$field';
}
