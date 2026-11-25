import '../../../theme/table_metrics.dart';
import '../../sections/inputs_messages.dart';

/// Simplified Chinese [InputsMessages].
class InputsMessagesZh extends InputsMessages {
  const InputsMessagesZh([super.localeName = 'zh']);

  @override
  String get confirm => '确认';

  @override
  String get copied => '已复制';

  @override
  String get copyFailed => '复制失败';

  @override
  String get undo => '撤销';

  @override
  String get showMore => '显示更多';

  @override
  String get showLess => '收起';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get clearSearch => '清除搜索内容';

  @override
  String get couldNotLoadResults => '无法加载结果';

  @override
  String optionOf(String label, int position, int count) =>
      '$label，第 ${number(position)} 项，共 ${number(count)} 项';

  @override
  String get dateRange => '日期范围';

  @override
  String get clearDates => '清除日期';

  @override
  String dateSpan(String start, String end) => '$start 至 $end';

  @override
  String lastDays(int count) => plural(count, other: '最近 ${number(count)} 天');

  @override
  String get thisMonth => '本月';

  @override
  String get lastMonth => '上月';

  @override
  String get yearToDate => '今年至今';

  @override
  String get searchOrJumpTo => '搜索或跳转到…';

  @override
  String get recent => '最近使用';

  @override
  String get selectAResult => '请选择一个结果';

  @override
  String matchedIn(String place) => '匹配位置：$place';

  @override
  String get matchedInContent => '匹配位置：内容';

  @override
  String get run => '执行';

  @override
  String get open => '打开';

  @override
  String get typeToSearch => '输入内容以搜索';

  @override
  String noResultsFor(String query) => '未找到“$query”的相关结果';

  @override
  String resultCount(int count) =>
      plural(count, zero: '无结果', other: '${number(count)} 个结果');

  @override
  String get navigateHint => '导航';

  @override
  String get selectHint => '选择';

  @override
  String get closeHint => '关闭';

  @override
  String get keysUpDown => '上下方向键';

  @override
  String get keyEnter => '回车键';

  @override
  String get keyEscape => 'Esc 键';

  @override
  String get fieldsGroup => '字段';

  @override
  String get notifications => '通知';

  @override
  String get allCaughtUp => '暂无新通知';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get unread => '未读';

  @override
  String get allNotifications => '全部';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String get viewAll => '查看全部';

  @override
  String get couldNotLoadNotifications => '无法加载通知';

  @override
  String unreadCount(String title, int count) => '$title，${number(count)} 条未读';

  @override
  String get appearanceTheme => '主题';

  @override
  String get appearanceMode => '模式';

  @override
  String get modeLight => '浅色';

  @override
  String get modeDark => '深色';

  @override
  String get modeSystem => '跟随系统';

  @override
  String get accentColour => '强调色';

  @override
  String get themeAccent => '主题色';

  @override
  String accentName(String name) => switch (name) {
    'Crimson' => '绯红',
    'Violet' => '紫罗兰',
    'Teal' => '蓝绿',
    'Amber' => '琥珀',
    _ => name,
  };

  @override
  String get tableDensity => '表格密度';

  @override
  String densityName(TableDensity density) => switch (density) {
    TableDensity.compact => '紧凑',
    TableDensity.standard => '标准',
    TableDensity.comfortable => '宽松',
  };
}
