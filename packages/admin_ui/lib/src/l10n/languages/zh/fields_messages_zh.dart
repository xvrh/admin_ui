import '../../sections/fields_messages.dart';

/// Simplified Chinese [FieldsMessages].
class FieldsMessagesZh extends FieldsMessages {
  const FieldsMessagesZh([super.localeName = 'zh']);

  @override
  String quoted(String text) => '“$text”';

  @override
  String get filterOrAdd => '筛选或添加…';

  @override
  String maxSelected(int max) => '已达上限（${number(max)} 项）';

  @override
  String createOption(String value) => '创建 ${quoted(value)}';

  @override
  String get onLabel => '开';

  @override
  String get offLabel => '关';

  @override
  String get selectDate => '选择日期…';

  @override
  String get selectDateTime => '选择日期和时间…';

  @override
  String get selectTime => '选择时间…';

  @override
  String get clearDate => '清除日期';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String get hour => '小时';

  @override
  String get minute => '分钟';

  /// 年, 月, 日, 时, 分, as a Chinese date input shows its empty parts. One
  /// character each, so a masked date field shows its own blanks instead.
  @override
  ({String year, String month, String day, String hour, String minute})
  get dateTokens => (year: '年', month: '月', day: '日', hour: '时', minute: '分');

  @override
  String numberLike(String example) => '请输入数字，例如 $example';

  @override
  String numberBetween(String min, String max) => '请输入 $min 到 $max 之间的数字';

  @override
  String numberAtLeast(String min) => '请输入不小于 $min 的数字';

  @override
  String numberAtMost(String max) => '请输入不大于 $max 的数字';

  @override
  String get decrease => '减少';

  @override
  String get increase => '增加';

  @override
  String get pickColor => '选择颜色…';

  @override
  String get hexDigitsError => '请输入 3 位或 6 位十六进制数字';

  @override
  String get setColor => '设置';

  @override
  String get validJson => 'JSON 有效';

  @override
  String jsonError(int line, int column, String detail) =>
      '第 ${number(line)} 行，第 ${number(column)} 列：$detail';

  @override
  String get formatJson => '格式化';

  @override
  String get plainText => '纯文本';

  @override
  String get addTag => '添加标签…';

  @override
  String get noTags => '无标签';

  @override
  String get noEntries => '无条目';

  @override
  String duplicateKey(String key) => '键 ${quoted(key)} 重复，以下方的行为准';

  @override
  String get duplicateKeys => '存在重复的键，以下方的行为准';

  @override
  String get removeRow => '移除行';

  @override
  String get noMedia => '无素材';

  @override
  String retryItem(String name) => '重试“$name”';

  @override
  String cancelUpload(String name) => '取消上传“$name”';

  @override
  String get cover => '封面';

  @override
  String get processing => '正在处理…';

  @override
  String get addImage => '添加图片';

  @override
  String get addFile => '添加文件';

  @override
  String get noReference => '无关联';

  @override
  String get unavailable => '不可用';

  @override
  String get replaceReference => '替换';

  @override
  String get typeToSearch => '输入内容以搜索…';

  @override
  String removeItemAt(int position) => '移除第 ${number(position)} 项';

  @override
  String get noItemsYet => '暂无项目。';

  @override
  String get help => '帮助';

  @override
  String helpFor(String field) => '“$field”的帮助';

  @override
  String get versionHistory => '版本历史';

  @override
  String get pendingEdit => '待生效的修改';

  @override
  String get baseline => '线上';

  @override
  String editedDetail(String detail) => '已修改 · $detail';

  @override
  String comments(int count) =>
      plural(count, zero: '评论', other: '${number(count)} 条评论');

  @override
  String commentsHeading(int count) => '评论 · ${number(count)}';

  @override
  String get resolve => '解决';

  @override
  String get replyPlaceholder => '回复…';

  @override
  String get sendReply => '发送回复';

  @override
  String commentOnField(int openThreads) => plural(
    openThreads,
    zero: '评论此字段',
    other: '${number(openThreads)} 个未解决的讨论',
  );

  @override
  String get openThread => '打开讨论';

  @override
  String get translationSource => '源语言';

  @override
  String get translationUpToDate => '已是最新';

  @override
  String get translationNeedsReview => '待审核';

  @override
  String get translationOutdated => '已过时';

  @override
  String get translationMissing => '未翻译';

  @override
  String get retranslate => '重新翻译';

  /// [language] is a Chinese language name, which takes no space.
  @override
  String retranslateLanguage(String language) => '重新翻译为$language';

  @override
  String get sourceChanged => '翻译后原文已更改';

  @override
  String sourceIn(String language) => '原文（$language）';

  @override
  String fieldInLanguage(String field, String language) => '$field，$language';

  @override
  String get languages => '语言';

  @override
  String get languageMenuHint => '点按以切换 · 勾选以并排比较。';

  @override
  String compareLanguage(String language) => '对照$language';

  @override
  String switchToLanguage(String language) => '切换到$language';

  @override
  String get editing => '编辑中';

  @override
  String get inherited => '继承';

  @override
  String get custom => '自定义';

  @override
  String inheritedDescription(String source) => '跟随$source，自动更新';

  @override
  String customDescription(String? noun) => '单独设置${noun ?? '值'}';

  @override
  String get valueRequired => '必填';

  @override
  String tooShort(int min) => plural(min, other: '请至少输入 ${number(min)} 个字符');

  @override
  String tooLong(int max) => plural(max, other: '请输入不超过 ${number(max)} 个字符');

  @override
  String get invalidEmail => '请输入有效的电子邮件地址';

  @override
  String get invalidUrl => '请输入有效的网址';

  @override
  String get invalidFormat => '请输入符合格式要求的值';

  @override
  String tooSmall(String min) => numberAtLeast(min);

  @override
  String tooLarge(String max) => numberAtMost(max);

  @override
  String addAtLeast(int count) =>
      plural(count, other: '请至少添加 ${number(count)} 项');

  @override
  String keepAtMost(int count) =>
      plural(count, other: '最多保留 ${number(count)} 项');

  @override
  String get checking => '正在检查…';

  /// Chinese forms write 选填, in full-width parentheses.
  @override
  String get optionalMarker => '（选填）';

  @override
  String validationSummaryTitle(int count) =>
      plural(count, other: '${number(count)} 个字段需要修正');

  @override
  String jumpToField(String label) => '转到“$label”';

  @override
  String fieldMessage(String label, String message) => '$label：$message';

  @override
  String get wizardNext => '下一步';

  @override
  String get wizardBack => '上一步';

  @override
  String wizardStepBlocked(int count) =>
      plural(count, other: '请修正 ${number(count)} 个字段后继续');
}
