import '../../sections/display_messages.dart';

/// Japanese [DisplayMessages].
class DisplayMessagesJa extends DisplayMessages {
  const DisplayMessagesJa([super.localeName = 'ja']);

  /// Japanese joins the parts with an ideographic comma.
  @override
  String joinParts(List<String> parts) => parts.join('、');

  @override
  String get loadingLabel => '読み込み中';

  @override
  String get errorTimeout => 'サーバーからの応答がタイムアウトしました。もう一度お試しください。';

  @override
  String get errorUnreachable => 'サーバーに接続できません。ネットワーク接続を確認して、もう一度お試しください。';

  @override
  String get errorUnreadable => 'サーバーからの応答を読み取れませんでした。もう一度お試しください。';

  @override
  String get errorUnauthorized => 'セッションの有効期限が切れました。ログインして、もう一度お試しください。';

  @override
  String get errorPaymentRequired => 'この操作には有料プランまたは追加のクレジットが必要です。';

  @override
  String get errorForbidden => 'この操作を行う権限がありません。';

  @override
  String get errorNotFound => '見つかりませんでした。移動または削除された可能性があります。';

  @override
  String get errorConflict => '別の場所で変更されています。再読み込みして、もう一度お試しください。';

  @override
  String get errorTooLarge => 'サイズが大きすぎるため、サーバーで受け付けられません。';

  @override
  String get errorRateLimited => 'リクエストが多すぎます。しばらく待ってから、もう一度お試しください。';

  @override
  String get errorServer => 'サーバーで問題が発生しました。しばらくしてから、もう一度お試しください。';

  @override
  String get errorRequestFailed => 'サーバーでリクエストを完了できませんでした。';

  @override
  String get breadcrumb => 'パンくずリスト';

  @override
  String currentPage(String label) => '$label、現在のページ';

  @override
  String get switchPage => 'ページを切り替え';

  @override
  String showMore(int count) =>
      plural(count, other: 'さらに ${number(count)} 件を表示');

  @override
  String pageNumber(int page) => '${number(page)} ページ';

  @override
  String jsonKeys(int count) => plural(count, other: '${number(count)} 個のキー');

  @override
  String jsonItems(int count) => plural(count, other: '${number(count)} 個の要素');

  @override
  String get expandAll => 'すべて展開';

  @override
  String get collapseAll => 'すべて折りたたむ';

  @override
  String get copyJson => 'JSON をコピー';

  @override
  String get copyValue => '値をコピー';

  @override
  String get copyPath => 'パスをコピー';

  @override
  String invalidJson(String detail) => '無効な JSON：$detail';

  @override
  String get logEmpty => 'まだ出力はありません';

  @override
  String get zoomArea => 'ズーム可能な領域';

  @override
  String get zoomAreaHint =>
      'スクロールでズーム、ドラッグで移動します。+ と − でズーム、0 で全体表示、'
      '矢印キーで移動します。';

  @override
  String get zoomIn => '拡大';

  @override
  String get zoomOut => '縮小';

  @override
  String get zoomToFit => '全体を表示';

  @override
  String get qrCode => 'QR コード';

  @override
  String uploadDone(int total) =>
      plural(total, other: '${number(total)} 件のアップロードが完了しました');

  @override
  String uploadProgress(int done, int total, int failed) => failed == 0
      ? '${number(done)} / ${number(total)} 件をアップロード済み'
      : '${number(done)} / ${number(total)} 件をアップロード済み · '
            '${number(failed)} 件失敗';

  @override
  String get clearCompleted => '完了済みをクリア';

  @override
  String get queued => '待機中';

  @override
  String get retryUpload => 'アップロードを再試行';

  @override
  String get removeFile => 'ファイルを削除';

  @override
  String get cancelUpload => 'アップロードをキャンセル';

  @override
  String get chartEmpty => 'この期間のデータはありません';

  @override
  String get heatLess => '少ない';

  @override
  String get heatMore => '多い';

  @override
  String statValue(String label, String value) => '$label：$value';

  @override
  String trendUp(String delta) => '$delta 増加';

  @override
  String trendDown(String delta) => '$delta 減少';

  @override
  String get needsAttention => '要対応';

  @override
  String get recentActivity => '最近のアクティビティ';

  @override
  String get contentMix => 'コンテンツの内訳';

  @override
  String itemsUnit(int count) => plural(count, other: '件');

  @override
  String get allCaughtUp => '対応が必要な項目はありません。';

  @override
  String get noRecentActivity => '最近のアクティビティはありません';

  @override
  String get noRecentActivityHint => '編集、公開、アップロードの履歴がここに表示されます。';

  /// The count follows the label, with a counter, as Japanese counts.
  @override
  String attentionItem(int count, String label, String? caption) =>
      caption == null
      ? '$label ${number(count)} 件'
      : '$label ${number(count)} 件、$caption';

  @override
  String stepOf(int step, int total, String title) =>
      'ステップ ${number(step)}（全 ${number(total)} ステップ）：$title';

  @override
  String get stepCompleted => '完了';

  @override
  String get stepCurrent => '進行中';

  @override
  String get stepUpcoming => '未着手';

  @override
  String get stepError => 'エラー';

  @override
  String get addItem => '項目を追加';

  @override
  String get untitled => '無題';

  @override
  String get treeHeader => 'グループ';

  @override
  String get indent => 'インデントを増やす';

  @override
  String get outdent => 'インデントを減らす';

  @override
  String get addChild => '子項目を追加';

  @override
  String get hideEntry => '非表示にする';

  @override
  String get showEntry => '表示する';

  @override
  String movedUp(String title) => '$title を上に移動しました';

  @override
  String movedDown(String title) => '$title を下に移動しました';

  @override
  String indented(String title) => '$title のインデントを増やしました';

  @override
  String outdented(String title) => '$title のインデントを減らしました';

  @override
  String get rowMovedUp => '上に移動しました';

  @override
  String get rowMovedDown => '下に移動しました';

  @override
  String get rowIndented => 'インデントを増やしました';

  @override
  String get rowOutdented => 'インデントを減らしました';

  @override
  String get resizePanes => 'ペインのサイズを変更';

  @override
  String get moveLeft => '左に移動';

  @override
  String get moveRight => '右に移動';

  @override
  String get preview => 'プレビュー';

  /// Japanese has no upper case.
  @override
  String get previewHeading => 'プレビュー';

  @override
  String get noPreviewHeading => 'プレビューなし';

  @override
  String get insertsInline => 'インラインで挿入されるため、プレビューはありません。';

  @override
  String nothingMatches(String query) => '「$query」に一致する項目はありません';

  @override
  String get choices => '選択肢';

  @override
  String get diffAdded => '追加';

  @override
  String get diffRemoved => '削除';

  @override
  String get diffChanged => '変更';

  @override
  String get diffMoved => '移動';

  @override
  String get diffUnchanged => '変更なし';

  @override
  String addedCount(int count) => '${number(count)} 件追加';

  @override
  String removedCount(int count) => '${number(count)} 件削除';

  @override
  String changedCount(int count) => '${number(count)} 件変更';

  @override
  String movedCount(int count) => '${number(count)} 件移動';

  @override
  String get before => '変更前';

  @override
  String get after => '変更後';

  @override
  String authorAndTime(String author, String time) => '$author · $time';

  @override
  String movedFromTo(int from, int to) =>
      '${number(from)} 番目から ${number(to)} 番目へ';

  @override
  String get unified => '統合表示';

  @override
  String get split => '並べて表示';

  @override
  String get noChanges => '変更はありません';

  @override
  String get versionsIdentical => 'この 2 つのバージョンは同じです。';

  @override
  String get noFieldChanges => 'フィールドの変更はありません。';

  @override
  String get noBlockChanges => 'ブロックの変更はありません。';

  @override
  String get empty => '空欄';

  @override
  String inserted(String text) => '挿入：$text、';

  @override
  String deleted(String text) => '削除：$text、';

  @override
  String get restore => '復元';

  @override
  String get restoreThisVersion => 'このバージョンを復元';

  @override
  String get restoreThisField => 'このフィールドを復元';

  @override
  String get restoreThisItem => 'この項目を復元';

  @override
  String get restoreLiveBlock => 'このブロックの公開版を復元';

  @override
  String get sharedLane => '共通';

  @override
  String get versionCurrent => '現在';

  @override
  String get versionPublished => '公開済み';

  @override
  String get versionRestored => '復元済み';

  @override
  String get versionArchived => 'アーカイブ済み';

  @override
  String versionNumber(int version) => 'v$version';

  @override
  String get mentionSuggestions => 'メンション候補';

  @override
  String mentionMatches(int count) =>
      plural(count, other: 'メンション候補 ${number(count)} 人');
}
