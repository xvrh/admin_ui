import '../../sections/assets_messages.dart';

/// Japanese [AssetsMessages].
class AssetsMessagesJa extends AssetsMessages {
  const AssetsMessagesJa([super.localeName = 'ja']);

  @override
  String get assets => 'メディア';

  @override
  String get loadingAssets => 'メディアを読み込み中…';

  @override
  String get couldNotLoadAssets => 'メディアを読み込めませんでした';

  @override
  String get noMatchingAssets => '一致するメディアはありません';

  @override
  String get noMatchingAssetsHint => '別の検索語句またはフィルターをお試しください。';

  @override
  String get noAssetsYet => 'まだメディアはありません';

  @override
  String get noAssetsYetHint => '画像やファイルをアップロードして、メディアライブラリを作成できます。';

  @override
  String assetCount(int count) =>
      plural(count, other: 'メディア ${number(count)} 件');

  /// Japanese names the whole before the part: 120 件中 24 件.
  @override
  String assetsShown(int shown, int total) =>
      '${assetCount(total)}中 ${number(shown)} 件';

  @override
  String get searchAssets => 'メディアを検索';

  @override
  String get filterByType => '種類で絞り込み';

  @override
  String filterChoice(String filter, String choice) => '$filter：$choice';

  @override
  String get allTypes => 'すべての種類';

  @override
  String get typeImages => '画像';

  @override
  String get typeVideos => '動画';

  @override
  String get typeAudio => '音声';

  @override
  String get typeDocuments => 'ドキュメント';

  @override
  String get typeOther => 'その他';

  @override
  String get kindImage => '画像';

  @override
  String get kindVideo => '動画';

  @override
  String get kindAudio => '音声';

  @override
  String get kindDocument => 'ドキュメント';

  @override
  String get kindOther => 'その他';

  @override
  String get view => '表示形式';

  @override
  String get gridView => 'グリッド表示';

  @override
  String get listView => 'リスト表示';

  @override
  String get libraryTab => 'ライブラリ';

  @override
  String get uploadTab => 'アップロード';

  @override
  String get pickerTitle => 'メディアを選択';

  @override
  String get select => '選択';

  @override
  String get loadingMore => 'さらに読み込み中…';

  @override
  String get dropToUpload => 'ドロップしてアップロード';

  @override
  String couldNotLoadMore(String reason) => '続きを読み込めませんでした。$reason';

  @override
  String get uploadIncomplete => 'アップロードが完了しませんでした。もう一度お試しください。';

  @override
  String get asset => 'メディア';

  @override
  String get type => '種類';

  @override
  String get size => 'サイズ';

  @override
  String get dimensions => '寸法';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => '代替テキスト';

  @override
  String get defaultAltText => 'デフォルトの代替テキスト';

  @override
  String get defaultAltTextHelp =>
      'このメディアが表示されるすべての場所で使用されます（使用箇所で上書きした場合を除く）。';

  @override
  String get saveAltText => '代替テキストを保存';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'URL をコピー';

  @override
  String get aspectFree => '自由';

  @override
  String get imageUnavailable => '画像を表示できません';

  @override
  String get cropArea => '画像のトリミング範囲';

  @override
  String get cropAreaHint =>
      'ハンドルをドラッグしてトリミングします。矢印キーで微調整し、Shift キーを押しながら操作すると'
      '大きく移動します。';

  @override
  String get positionArea => '画像の位置調整エリア';

  @override
  String get positionAreaHint => 'ドラッグで位置を調整、スクロールでズームします。矢印キーで微調整できます。';

  @override
  String get zoom => 'ズーム';

  @override
  String zoomLevel(String amount) => '$amount 倍';

  @override
  String get straighten => '傾き補正';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => '左に回転';

  @override
  String get rotateRight => '右に回転';

  @override
  String get flipHorizontal => '左右反転';

  @override
  String get flipVertical => '上下反転';

  @override
  String get useImage => 'この画像を使用';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    other:
        'ライセンスを取得するとライブラリに追加され、ダウンロード枠を '
        '${number(downloads)} 回分使用します',
  );

  @override
  String get selectImageToLicense => 'ライセンスを取得する画像を選択してください';

  @override
  String get findStockImages => 'ストック画像を探す';

  @override
  String get noResultsHint => '別の検索語句を試すか、フィルターの条件を緩めてください。';

  @override
  String stockSearchPrompt(String provider) =>
      'キーワードを入力して、$provider の数百万点の画像を検索できます。';

  @override
  String providerResults(String provider) => '$provider の検索結果';

  @override
  String resultCount(int count) =>
      plural(count, other: '検索結果 ${number(count)} 件');

  @override
  String resultsShown(int shown, int total) =>
      '${resultCount(total)}中 ${number(shown)} 件';

  @override
  String searchProvider(String provider) => '$provider で検索';

  @override
  String get orientation => '向き';

  @override
  String get anyOrientation => 'すべての向き';

  @override
  String get horizontal => '横長';

  @override
  String get vertical => '縦長';

  @override
  String get square => '正方形';

  @override
  String get imageType => '画像の種類';

  @override
  String get anyType => 'すべての種類';

  @override
  String get photos => '写真';

  @override
  String get illustrations => 'イラスト';

  @override
  String get vectors => 'ベクター';

  @override
  String licenseFrom(String provider) => '$provider からライセンスを取得';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    other:
        '画像をライブラリに追加し、$provider プランのダウンロード枠を '
        '${number(downloads)} 回分使用します。',
  );

  @override
  String get couldNotLicense => 'この画像のライセンスを取得できませんでした';

  @override
  String get licenseAndAdd => 'ライセンスを取得して追加';

  @override
  String get couldNotLoadSizes => 'サイズを読み込めませんでした';

  @override
  String editItem(String name) => '$name を編集';

  @override
  String get done => '完了';

  @override
  String get couldNotLoadPreview => 'プレビューを読み込めませんでした';

  @override
  String get uploading => 'アップロード中';

  @override
  String get replace => '置き換え';

  @override
  String get choose => '選択';

  @override
  String get editCrop => 'トリミングを編集';

  @override
  String get cropAndFocalPoint => 'トリミングとフォーカルポイント';

  @override
  String get imagesOnly => '画像のみ';

  @override
  String get typeText => 'テキスト';

  /// The MIME family stays as it is written, in Latin letters.
  @override
  String familyFiles(String family) => '$family ファイル';

  @override
  String upTo(String size) => '最大 $size';

  /// The ideographic comma, with no space after it.
  @override
  String get listSeparator => '、';

  @override
  String refusedNotImage(String names, int count) =>
      plural(count, other: '$names は画像ではないため、追加できませんでした。');

  @override
  String refusedNotSupported(String names, int count) =>
      plural(count, other: '$names は対応していないファイル形式のため、追加できませんでした。');

  @override
  String refusedTooLarge(String names, int count, String limit) =>
      plural(count, other: '$names は $limit を超えているため、追加できませんでした。');

  @override
  String refusedFolder(String names, int count) =>
      plural(count, other: '$names はフォルダーのため、追加できませんでした。');

  @override
  String refusedMixed(String items) => '$itemsを追加できませんでした。';

  @override
  String refusedItemNotImage(String name) => '$name（画像以外のファイル）';

  @override
  String refusedItemNotSupported(String name) => '$name（未対応のファイル形式）';

  @override
  String refusedItemTooLarge(String name, String limit) => '$name（$limit 超）';

  @override
  String refusedItemFolder(String name) => '$name（フォルダー）';
}
