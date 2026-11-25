import '../../admin_ui_localizations.dart';
import '../../sections/assets_messages.dart';
import '../../sections/collection_messages.dart';
import '../../sections/display_messages.dart';
import '../../sections/fields_messages.dart';
import '../../sections/inputs_messages.dart';
import '../../sections/shell_messages.dart';
import 'assets_messages_zh.dart';
import 'collection_messages_zh.dart';
import 'display_messages_zh.dart';
import 'fields_messages_zh.dart';
import 'inputs_messages_zh.dart';
import 'shell_messages_zh.dart';

/// Simplified Chinese [AdminLocalizations].
class AdminLocalizationsZh extends AdminLocalizations {
  const AdminLocalizationsZh([super.localeName = 'zh']);

  @override
  InputsMessages get inputs => const InputsMessagesZh();

  @override
  DisplayMessages get display => const DisplayMessagesZh();

  @override
  CollectionMessages get collection => const CollectionMessagesZh();

  @override
  FieldsMessages get fields => const FieldsMessagesZh();

  @override
  ShellMessages get shell => const ShellMessagesZh();

  @override
  AssetsMessages get assets => const AssetsMessagesZh();

  @override
  String get apply => '应用';

  @override
  String get retry => '重试';

  @override
  String get remove => '移除';

  @override
  String removeItem(String name) => '移除“$name”';

  @override
  String get reset => '重置';

  @override
  String get loading => '正在加载…';

  @override
  String get saving => '正在保存…';

  @override
  String get edited => '已修改';

  @override
  String get unsavedChanges => '有未保存的更改';

  @override
  String get noResults => '无结果';

  @override
  String get noMatches => '无匹配项';

  @override
  String get couldNotLoad => '无法加载';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get loadMore => '加载更多';

  @override
  String get searching => '正在搜索…';

  @override
  String get somethingWentWrong => '出了点问题';

  @override
  String get somethingWentWrongTryAgain => '出了点问题，请重试。';

  @override
  String get notAllowed => '无权访问此内容';

  @override
  String get notAllowedAskAdministrator => '如需访问，请联系管理员。';

  @override
  String get goBack => '返回';

  @override
  String get moreActions => '更多操作';

  @override
  String get clearSelection => '取消选择';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get selectPlaceholder => '请选择…';

  @override
  String get filterPlaceholder => '筛选…';

  @override
  String get searchPlaceholder => '搜索…';

  @override
  String get addItem => '添加项';

  @override
  String get addRow => '添加行';

  @override
  String get keyLabel => '键';

  @override
  String get valueLabel => '值';

  @override
  String get linkPlaceholder => '关联…';

  @override
  String get restoreLiveVersion => '恢复此字段的线上版本';

  @override
  String get assetNotFound => '找不到素材';

  @override
  String get assetPreview => '素材预览';

  @override
  String get uploadFailed => '上传失败';

  /// Chinese words a file and files alike, and the whole zone is the link's
  /// target: 点击上传, as Chinese upload zones write it.
  @override
  ({String before, String link, String after}) dropPrompt({
    required bool multiple,
    bool images = false,
  }) => (before: images ? '将图片拖到此处，或' : '将文件拖到此处，或', link: '点击上传', after: '');

  @override
  String selectedCount(int count) =>
      plural(count, zero: '未选择任何项', other: '已选择 ${number(count)} 项');

  @override
  String countOf(int count, int total) => '${number(count)}/${number(total)}';

  /// Chinese software writes KB in capitals.
  @override
  String byteSize(String amount, int power) =>
      '$amount ${const ['B', 'KB', 'MB', 'GB', 'TB'][power]}';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get close => '关闭';

  @override
  String get clear => '清除文字';

  @override
  String get search => '搜索';

  @override
  String get more => '更多';

  @override
  String get selectAll => '全选';

  @override
  String get dismiss => '关闭';

  @override
  String get rowsPerPage => '每页行数：';

  @override
  String pageRowsInfo(String first, String last, String total) =>
      '第 $first-$last 行（共 $total 行）';

  @override
  String get previousPage => '上一页';

  @override
  String get nextPage => '下一页';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get today => '今天';

  @override
  String rangeStartDate(String date) => '开始日期为 $date';

  @override
  String rangeEndDate(String date) => '结束日期为 $date';

  @override
  String get selectDate => '选择日期';

  @override
  String get selectDateRange => '选择范围';

  @override
  String get navigationMenu => '导航菜单';

  @override
  String get expand => '展开';

  @override
  String get collapse => '收起';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyBackspace => '退格键';

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
  String get keyboardKeyPageDown => 'PgDn';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => '空格键';

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
