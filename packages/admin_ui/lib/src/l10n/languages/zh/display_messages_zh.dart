import '../../sections/display_messages.dart';

/// Simplified Chinese [DisplayMessages].
class DisplayMessagesZh extends DisplayMessages {
  const DisplayMessagesZh([super.localeName = 'zh']);

  /// The full-width comma.
  @override
  String joinParts(List<String> parts) => parts.join('，');

  @override
  String get loadingLabel => '正在加载';

  @override
  String get errorTimeout => '服务器响应超时，请重试。';

  @override
  String get errorUnreachable => '无法连接到服务器。请检查网络连接后重试。';

  @override
  String get errorUnreadable => '无法读取服务器的响应，请重试。';

  @override
  String get errorUnauthorized => '会话已过期，请重新登录后重试。';

  @override
  String get errorPaymentRequired => '此操作需要付费套餐或更多额度。';

  @override
  String get errorForbidden => '无权执行此操作。';

  @override
  String get errorNotFound => '找不到该内容，它可能已被移动或删除。';

  @override
  String get errorConflict => '该内容已在别处被修改，请重新加载后重试。';

  @override
  String get errorTooLarge => '内容过大，服务器无法接收。';

  @override
  String get errorRateLimited => '请求过于频繁，请稍后重试。';

  @override
  String get errorServer => '服务器出现问题，请稍后重试。';

  @override
  String get errorRequestFailed => '服务器无法完成该请求。';

  @override
  String get breadcrumb => '面包屑导航';

  @override
  String currentPage(String label) => '$label，当前页面';

  @override
  String get switchPage => '切换页面';

  @override
  String showMore(int count) => plural(count, other: '显示其余 ${number(count)} 项');

  @override
  String pageNumber(int page) => '第 ${number(page)} 页';

  @override
  String jsonKeys(int count) => plural(count, other: '${number(count)} 个键');

  @override
  String jsonItems(int count) => plural(count, other: '${number(count)} 项');

  @override
  String get expandAll => '全部展开';

  @override
  String get collapseAll => '全部收起';

  @override
  String get copyJson => '复制 JSON';

  @override
  String get copyValue => '复制值';

  @override
  String get copyPath => '复制路径';

  @override
  String invalidJson(String detail) => '无效的 JSON：$detail';

  @override
  String get logEmpty => '暂无输出';

  @override
  String get zoomArea => '可缩放视图';

  @override
  String get zoomAreaHint => '滚动可缩放，拖动可平移；按 + 和 − 缩放，按 0 适应视图，按方向键平移。';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get zoomToFit => '适应视图';

  @override
  String get qrCode => '二维码';

  @override
  String uploadDone(int total) =>
      plural(total, one: '上传完成', other: '${number(total)} 个文件已全部上传');

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '已上传 ${number(done)}/${number(total)}'
      : '已上传 ${number(done)}/${number(total)} · '
            '${number(failed)} 个失败';

  @override
  String get clearCompleted => '清除已完成';

  @override
  String get queued => '排队中';

  @override
  String get retryUpload => '重新上传';

  @override
  String get removeFile => '移除文件';

  @override
  String get cancelUpload => '取消上传';

  @override
  String get chartEmpty => '此时间段暂无数据';

  @override
  String get heatLess => '少';

  @override
  String get heatMore => '多';

  @override
  String statValue(String label, String value) => '$label：$value';

  @override
  String trendUp(String delta) => '上升 $delta';

  @override
  String trendDown(String delta) => '下降 $delta';

  @override
  String get needsAttention => '待处理';

  @override
  String get recentActivity => '最近动态';

  @override
  String get contentMix => '内容构成';

  @override
  String itemsUnit(int count) => plural(count, other: '项');

  @override
  String get allCaughtUp => '全部处理完毕，没有待处理的事项。';

  @override
  String get noRecentActivity => '暂无最近动态';

  @override
  String get noRecentActivityHint => '修改、发布和上传记录将显示在这里。';

  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '${number(count)} $label'
      : '${number(count)} $label，$caption';

  @override
  String stepOf(int step, int total, String title) =>
      '第 ${number(step)} 步，共 ${number(total)} 步：$title';

  @override
  String get stepCompleted => '已完成';

  @override
  String get stepCurrent => '进行中';

  @override
  String get stepUpcoming => '未开始';

  @override
  String get stepError => '出错';

  @override
  String get addItem => '添加项';

  @override
  String get untitled => '未命名';

  @override
  String get treeHeader => '分组';

  @override
  String get indent => '增加缩进';

  @override
  String get outdent => '减少缩进';

  @override
  String get addChild => '添加子项';

  @override
  String get hideEntry => '隐藏';

  @override
  String get showEntry => '显示';

  @override
  String movedUp(String title) => '“$title”已上移';

  @override
  String movedDown(String title) => '“$title”已下移';

  @override
  String indented(String title) => '“$title”已增加缩进';

  @override
  String outdented(String title) => '“$title”已减少缩进';

  @override
  String get rowMovedUp => '已上移';

  @override
  String get rowMovedDown => '已下移';

  @override
  String get rowIndented => '已增加缩进';

  @override
  String get rowOutdented => '已减少缩进';

  @override
  String get resizePanes => '调整窗格大小';

  @override
  String get moveLeft => '左移';

  @override
  String get moveRight => '右移';

  @override
  String get preview => '预览';

  /// Chinese has no capitals.
  @override
  String get previewHeading => '预览';

  @override
  String get noPreviewHeading => '无预览';

  @override
  String get insertsInline => '以内联方式插入，无需预览。';

  @override
  String nothingMatches(String query) => '没有与“$query”匹配的内容';

  @override
  String get choices => '选项';

  @override
  String get diffAdded => '已添加';

  @override
  String get diffRemoved => '已删除';

  @override
  String get diffChanged => '已更改';

  @override
  String get diffMoved => '已移动';

  @override
  String get diffUnchanged => '未更改';

  @override
  String addedCount(int count) => '已添加 ${number(count)} 项';

  @override
  String removedCount(int count) => '已删除 ${number(count)} 项';

  @override
  String changedCount(int count) => '已更改 ${number(count)} 项';

  @override
  String movedCount(int count) => '已移动 ${number(count)} 项';

  @override
  String get before => '修改前';

  @override
  String get after => '修改后';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      '从第 ${number(from)} 位移到第 ${number(to)} 位';

  @override
  String get unified => '单栏';

  @override
  String get split => '并排';

  @override
  String get noChanges => '无更改';

  @override
  String get versionsIdentical => '这两个版本完全相同。';

  @override
  String get noFieldChanges => '没有字段更改。';

  @override
  String get noBlockChanges => '没有区块更改。';

  @override
  String get empty => '空';

  @override
  String inserted(String text) => '已插入：$text，';

  @override
  String deleted(String text) => '已删除：$text，';

  @override
  String get restore => '恢复';

  @override
  String get restoreThisVersion => '恢复此版本';

  @override
  String get restoreThisField => '恢复此字段';

  @override
  String get restoreThisItem => '恢复此项';

  @override
  String get restoreLiveBlock => '恢复此区块的线上版本';

  @override
  String get sharedLane => '通用';

  @override
  String get versionCurrent => '当前';

  @override
  String get versionPublished => '已发布';

  @override
  String get versionRestored => '已恢复';

  @override
  String get versionArchived => '已归档';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => '可提及的人';

  @override
  String mentionMatches(int count) =>
      plural(count, other: '${number(count)} 人可提及');
}
