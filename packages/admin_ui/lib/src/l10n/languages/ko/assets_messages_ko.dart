import '../../sections/assets_messages.dart';

/// Korean [AssetsMessages].
class AssetsMessagesKo extends AssetsMessages {
  const AssetsMessagesKo([super.localeName = 'ko']);

  @override
  String get assets => '미디어';

  @override
  String get loadingAssets => '미디어 불러오는 중…';

  @override
  String get couldNotLoadAssets => '미디어를 불러올 수 없음';

  @override
  String get noMatchingAssets => '일치하는 미디어 없음';

  @override
  String get noMatchingAssetsHint => '다른 검색어나 필터를 사용해 보세요.';

  @override
  String get noAssetsYet => '아직 미디어가 없습니다';

  @override
  String get noAssetsYetHint => '이미지와 파일을 업로드하여 라이브러리를 만드세요.';

  @override
  String assetCount(int count) => plural(count, other: '미디어 ${number(count)}개');

  @override
  String assetsShown(int shown, int total) =>
      '${assetCount(total)} 중 ${number(shown)}개';

  @override
  String get searchAssets => '미디어 검색';

  @override
  String get filterByType => '유형별 필터';

  @override
  String filterChoice(String filter, String choice) => '$filter: $choice';

  @override
  String get allTypes => '모든 유형';

  @override
  String get typeImages => '이미지';

  @override
  String get typeVideos => '동영상';

  @override
  String get typeAudio => '오디오';

  @override
  String get typeDocuments => '문서';

  @override
  String get typeOther => '기타';

  @override
  String get kindImage => '이미지';

  @override
  String get kindVideo => '동영상';

  @override
  String get kindAudio => '오디오';

  @override
  String get kindDocument => '문서';

  @override
  String get kindOther => '기타';

  @override
  String get view => '보기';

  @override
  String get gridView => '그리드 보기';

  @override
  String get listView => '목록 보기';

  @override
  String get libraryTab => '라이브러리';

  @override
  String get uploadTab => '업로드';

  @override
  String get pickerTitle => '미디어 선택';

  @override
  String get select => '선택';

  @override
  String get loadingMore => '더 불러오는 중…';

  @override
  String get dropToUpload => '놓아서 업로드';

  @override
  String couldNotLoadMore(String reason) => '더 불러올 수 없습니다. $reason';

  @override
  String get uploadIncomplete => '업로드가 완료되지 않았습니다. 다시 시도하세요.';

  @override
  String get asset => '미디어';

  @override
  String get type => '유형';

  @override
  String get size => '크기';

  @override
  String get dimensions => '해상도';

  @override
  String pixelSize(int width, int height) => '$width × $height';

  @override
  String get id => 'ID';

  @override
  String get altText => '대체 텍스트';

  @override
  String get defaultAltText => '기본 대체 텍스트';

  @override
  String get defaultAltTextHelp =>
      '사용하는 곳에서 따로 지정하지 않으면 이 미디어가 표시되는 모든 곳에 사용됩니다.';

  @override
  String get saveAltText => '대체 텍스트 저장';

  @override
  String get url => 'URL';

  @override
  String get copyUrl => 'URL 복사';

  @override
  String get aspectFree => '자유';

  @override
  String get imageUnavailable => '이미지를 불러올 수 없음';

  @override
  String get cropArea => '이미지 자르기 영역';

  @override
  String get cropAreaHint =>
      '핸들을 드래그하여 자르세요. 화살표 키로 미세 조정하고, Shift 키를 누른 채 '
      '더 크게 이동합니다.';

  @override
  String get positionArea => '이미지 위치 조정 영역';

  @override
  String get positionAreaHint =>
      '드래그하여 위치를 조정하고 스크롤하여 확대/축소하세요. 화살표 키로 미세 '
      '조정합니다.';

  @override
  String get zoom => '확대/축소';

  @override
  String zoomLevel(String amount) => '$amount×';

  @override
  String get straighten => '수평 맞추기';

  @override
  String degrees(String amount) => '$amount°';

  @override
  String get rotateLeft => '왼쪽으로 회전';

  @override
  String get rotateRight => '오른쪽으로 회전';

  @override
  String get flipHorizontal => '좌우 반전';

  @override
  String get flipVertical => '상하 반전';

  @override
  String get useImage => '이미지 사용';

  @override
  String licenseNotice(int downloads) => plural(
    downloads,
    other:
        '라이선스를 구매하면 라이브러리에 추가되며 다운로드 '
        '${number(downloads)}회가 사용됩니다',
  );

  @override
  String get selectImageToLicense => '라이선스를 구매할 이미지를 선택하세요';

  @override
  String get findStockImages => '스톡 이미지 찾기';

  @override
  String get noResultsHint => '다른 검색어를 사용하거나 필터를 줄여 보세요.';

  @override
  String stockSearchPrompt(String provider) => '$provider에서 수백만 개의 이미지를 검색하세요.';

  @override
  String providerResults(String provider) => '$provider 검색 결과';

  @override
  String resultCount(int count) => plural(count, other: '결과 ${number(count)}개');

  @override
  String resultsShown(int shown, int total) =>
      '${resultCount(total)} 중 ${number(shown)}개';

  @override
  String searchProvider(String provider) => '$provider 검색';

  @override
  String get orientation => '방향';

  @override
  String get anyOrientation => '모든 방향';

  @override
  String get horizontal => '가로';

  @override
  String get vertical => '세로';

  @override
  String get square => '정사각형';

  @override
  String get imageType => '이미지 유형';

  @override
  String get anyType => '모든 유형';

  @override
  String get photos => '사진';

  @override
  String get illustrations => '일러스트';

  @override
  String get vectors => '벡터';

  @override
  String licenseFrom(String provider) => '$provider 라이선스';

  @override
  String licenseDetail(String provider, int downloads) => plural(
    downloads,
    other:
        '이미지를 라이브러리에 추가하고 $provider 요금제에서 다운로드 '
        '${number(downloads)}회를 사용합니다.',
  );

  @override
  String get couldNotLicense => '이 이미지의 라이선스를 구매할 수 없음';

  @override
  String get licenseAndAdd => '라이선스 구매 및 추가';

  @override
  String get couldNotLoadSizes => '크기를 불러올 수 없음';

  @override
  String editItem(String name) => '$name 수정';

  @override
  String get done => '완료';

  @override
  String get couldNotLoadPreview => '미리보기를 불러올 수 없음';

  @override
  String get uploading => '업로드 중';

  @override
  String get replace => '교체';

  @override
  String get choose => '선택';

  @override
  String get editCrop => '자르기 수정';

  @override
  String get cropAndFocalPoint => '자르기 및 초점';

  @override
  String get imagesOnly => '이미지만';

  @override
  String get typeText => '텍스트';

  /// Korean has no capital letters: the MIME family stays as it is.
  @override
  String familyFiles(String family) => family.isEmpty ? '파일' : '$family 파일';

  @override
  String upTo(String size) => '최대 $size';

  @override
  String get listSeparator => ', ';

  /// 파일 and 폴더 carry the particle, which would otherwise depend on how
  /// the last of [names] ends.
  @override
  String refusedNotImage(String names, int count) =>
      plural(count, other: '$names 파일은 이미지가 아니어서 추가할 수 없습니다.');

  @override
  String refusedNotSupported(String names, int count) =>
      plural(count, other: '$names 파일은 지원되지 않는 형식이어서 추가할 수 없습니다.');

  @override
  String refusedTooLarge(String names, int count, String limit) =>
      plural(count, other: '$names 파일은 $limit보다 커서 추가할 수 없습니다.');

  @override
  String refusedFolder(String names, int count) =>
      plural(count, other: '$names 폴더는 추가할 수 없습니다.');

  @override
  String refusedMixed(String items) => '다음 항목을 추가할 수 없습니다: $items.';

  @override
  String refusedItemNotImage(String name) => '$name (이미지 아님)';

  @override
  String refusedItemNotSupported(String name) => '$name (지원되지 않는 형식)';

  @override
  String refusedItemTooLarge(String name, String limit) => '$name ($limit 초과)';

  @override
  String refusedItemFolder(String name) => '$name (폴더)';
}
