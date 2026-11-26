import '../../sections/assets_messages.dart';

/// Simplified Chinese [AssetsMessages].
class AssetsMessagesZh extends AssetsMessages {
  const AssetsMessagesZh([super.localeName = 'zh']);

  @override
  String get assets => '素材';

  @override
  String get loadingAssets => '正在加载素材…';

  @override
  String get couldNotLoadAssets => '无法加载素材';

  @override
  String get noMatchingAssets => '没有匹配的素材';

  @override
  String get noMatchingAssetsHint => '请尝试其他搜索词或筛选条件。';

  @override
  String get noAssetsYet => '暂无素材';

  @override
  String get noAssetsYetHint => '上传图片和文件，建立素材库。';

  @override
  String assetCount(int count) => plural(count, other: '${number(count)} 个素材');

  @override
  String assetsShown(int shown, int total) =>
      '已显示 ${number(shown)} 个，共 ${assetCount(total)}';

  @override
  String get searchAssets => '搜索素材';

  @override
  String get filterByType => '按类型筛选';

  @override
  String filterChoice(String filter, String choice) => '$filter：$choice';

  @override
  String get allTypes => '所有类型';

  @override
  String get typeImages => '图片';

  @override
  String get typeVideos => '视频';

  @override
  String get typeAudio => '音频';

  @override
  String get typeDocuments => '文档';

  @override
  String get typeOther => '其他';

  @override
  String get kindImage => '图片';

  @override
  String get kindVideo => '视频';

  @override
  String get kindAudio => '音频';

  @override
  String get kindDocument => '文档';

  @override
  String get kindOther => '其他';

  @override
  String get view => '显示方式';

  @override
  String get gridView => '网格视图';

  @override
  String get listView => '列表视图';

  @override
  String get libraryTab => '素材库';

  @override
  String get uploadTab => '上传';

  @override
  String get pickerTitle => '选择素材';

  @override
  String get select => '选择';

  @override
  String get loadingMore => '正在加载更多…';

  @override
  String get dropToUpload => '松开即可上传';

  @override
  String couldNotLoadMore(String reason) => '无法加载更多。$reason';

  @override
  String get uploadIncomplete => '上传未完成，请重试。';

  @override
  String get asset => '素材';

  @override
  String get type => '类型';

  @override
  String get size => '大小';

  @override
  String get dimensions => '尺寸';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => '替代文本';

  @override
  String get defaultAltText => '默认替代文本';

  @override
  String get defaultAltTextHelp => '用于此素材出现的所有位置，除非在使用处另行设置。';

  @override
  String get saveAltText => '保存替代文本';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => '复制 URL';

  @override
  String get aspectFree => '自由';

  @override
  String get imageUnavailable => '图片不可用';

  @override
  String get cropArea => '图片裁剪区域';

  @override
  String get cropAreaHint => '拖动控制点进行裁剪。方向键可微调；按住 Shift 键可加大步幅。';

  @override
  String get positionArea => '图片定位区域';

  @override
  String get positionAreaHint => '拖动可调整位置，滚动可缩放；方向键可微调。';

  @override
  String get zoom => '缩放';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => '拉直';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => '向左旋转';

  @override
  String get rotateRight => '向右旋转';

  @override
  String get flipHorizontal => '水平翻转';

  @override
  String get flipVertical => '垂直翻转';

  @override
  String get useImage => '使用图片';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    other: '获取授权后，图片将添加到素材库，并使用 ${number(downloads)} 次下载额度',
  );

  @override
  String get selectImageToLicense => '选择要获取授权的图片';

  @override
  String get findStockImages => '查找图库图片';

  @override
  String get noResultsHint => '请尝试其他搜索词或放宽筛选条件。';

  @override
  String stockSearchPrompt(String provider) => '输入关键词，在 $provider 上搜索数百万张图片。';

  @override
  String providerResults(String provider) => '$provider 搜索结果';

  @override
  String resultCount(int count) => plural(count, other: '${number(count)} 个结果');

  @override
  String resultsShown(int shown, int total) =>
      '已显示 ${number(shown)} 个，共 ${resultCount(total)}';

  @override
  String searchProvider(String provider) => '搜索 $provider';

  @override
  String get orientation => '方向';

  @override
  String get anyOrientation => '不限方向';

  @override
  String get horizontal => '横向';

  @override
  String get vertical => '纵向';

  @override
  String get square => '方形';

  @override
  String get imageType => '图片类型';

  @override
  String get anyType => '不限类型';

  @override
  String get photos => '照片';

  @override
  String get illustrations => '插画';

  @override
  String get vectors => '矢量图';

  @override
  String licenseFrom(String provider) => '从 $provider 获取授权';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    other:
        '将图片添加到素材库，并使用 $provider 套餐中的 '
        '${number(downloads)} 次下载额度。',
  );

  @override
  String get couldNotLicense => '无法获取此图片的授权';

  @override
  String get licenseAndAdd => '获取授权并添加';

  @override
  String get couldNotLoadSizes => '无法加载可选尺寸';

  @override
  String editItem(String name) => '编辑“$name”';

  @override
  String get done => '完成';

  @override
  String get couldNotLoadPreview => '无法加载预览';

  @override
  String get uploading => '正在上传';

  @override
  String get replace => '替换';

  @override
  String get choose => '选择';

  @override
  String get editCrop => '编辑裁剪';

  @override
  String get cropAndFocalPoint => '裁剪和焦点';

  @override
  String get imagesOnly => '仅限图片';

  @override
  String get typeText => '文本';

  /// Chinese has no capitals: the MIME family is written as it is.
  @override
  String familyFiles(String family) => family.isEmpty ? '文件' : '$family 文件';

  @override
  String upTo(String size) => '不超过 $size';

  /// The enumeration comma.
  @override
  String get listSeparator => '、';

  @override
  String refusedNotImage(String names, int count) =>
      plural(count, other: '无法添加 $names：不是图片。');

  @override
  String refusedNotSupported(String names, int count) =>
      plural(count, other: '无法添加 $names：不支持该文件类型。');

  @override
  String refusedTooLarge(String names, int count, String limit) =>
      plural(count, other: '无法添加 $names：文件超过 $limit。');

  @override
  String refusedFolder(String names, int count) =>
      plural(count, other: '无法添加 $names：不支持文件夹。');

  @override
  String refusedMixed(String items) => '无法添加 $items。';

  @override
  String refusedItemNotImage(String name) => '$name（不是图片）';

  @override
  String refusedItemNotSupported(String name) => '$name（不支持的文件类型）';

  @override
  String refusedItemTooLarge(String name, String limit) => '$name（超过 $limit）';

  @override
  String refusedItemFolder(String name) => '$name（文件夹）';
}
