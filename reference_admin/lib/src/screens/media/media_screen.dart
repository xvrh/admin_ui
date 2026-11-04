import 'package:admin_ui/assets.dart';
import 'package:admin_ui/collection.dart' show BoolFilter;
import 'package:admin_ui/fields.dart' show LangScope, LocaleInfo, LocaleStatus;
import 'package:admin_ui/forms.dart' show showAssetDetail, showCropDialog;
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/media_team_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';
import '../../widgets/page_width.dart';

/// Which pictures the library shows, by whether a product uses them.
enum MediaUsage { all, inUse, unused }

/// The field the shop's media browse reads for whether a product uses a
/// picture.
const _inUse = 'inUse';

/// The media library: every picture the catalogue can use, searchable,
/// filtered by type and by use, as a grid or a list. A picture opens in a
/// side sheet with its details, its alt text per language and its crop.
class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  late final AssetLibraryController _library;
  MediaUsage _usage = MediaUsage.all;

  /// How many pictures the shop holds, from a page nothing narrowed.
  int? _libraryTotal;
  Set<String> _visibleLocales = {...shopLanguages};

  // FRICTION(F-403): neither Asset nor AssetSource carries a crop, so a
  // library crop lives as long as this page.
  final _crops = <String, CropValue>{};

  @override
  void initState() {
    super.initState();
    _library = AssetLibraryController(source: context.api.assets)
      ..addListener(_count);
  }

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  void _count() {
    final library = _library;
    final whole =
        library.query.isEmpty &&
        library.filter == null &&
        library.where.isEmpty;
    if (!whole || library.loading || library.error != null) return;
    if (_libraryTotal != library.total) {
      setState(() => _libraryTotal = library.total);
    }
  }

  void _setUsage(MediaUsage usage) {
    setState(() => _usage = usage);
    _library.where = [
      if (usage != MediaUsage.all)
        BoolFilter(_inUse, usage == MediaUsage.inUse),
    ];
  }

  void _toast(String message, Severity severity) =>
      ToastScope.of(context).show(Toast(message, severity: severity));

  /// Opens [asset] from [context], below the page's languages, which the
  /// sheet's alt text is written in.
  void _openAsset(BuildContext context, Asset asset) {
    final strings = context.strings.mediaTeam;
    final canEdit = context.services.session.can(Permission.editCatalogue);
    showAssetDetail(
      ModalAnchor.of(context),
      context: context,
      asset: asset,
      onSaveAlt: canEdit ? (alt) => _saveAlt(asset, alt) : null,
      footerActions: [
        _UsedIn(count: asset.usageCount),
        if (canEdit && asset.thumbnail != null)
          Button(
            strings.crop,
            key: MediaTeamKeys.crop,
            icon: Icons.crop_rounded,
            variant: ButtonVariant.secondary,
            onPressed: () => _crop(asset),
          ),
      ],
    );
  }

  Future<Asset?> _saveAlt(Asset asset, Map<String, String> alt) async {
    final strings = context.strings.mediaTeam;
    try {
      final updated = await context.api.assets.updateAlt(asset.id, alt);
      if (!mounted || updated == null) return updated;
      _library.replace(updated);
      _toast(strings.altSaved(bidiIsolate(asset.name)), Severity.success);
      return updated;
    } catch (error) {
      if (mounted) {
        _toast(ErrorTextScope.describe(context, error), Severity.danger);
      }
      return null;
    }
  }

  Future<void> _crop(Asset asset) async {
    final strings = context.strings.mediaTeam;
    final (width, height) = (asset.width, asset.height);
    final value = await showCropDialog(
      context,
      image: asset.thumbnail!,
      imageAspect: width != null && height != null && height > 0
          ? width / height
          : 1,
      initial: _crops[asset.id] ?? CropValue.full,
    );
    if (value == null || !mounted) return;
    setState(() => _crops[asset.id] = value);
    _toast(strings.cropApplied(bidiIsolate(asset.name)), Severity.success);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.mediaTeam;
    final language = Localizations.localeOf(context).languageCode;
    final libraryTotal = _libraryTotal;
    return PageScaffold(
      maxWidth: pageMaxWidth,
      title: strings.mediaTitle,
      subtitle: libraryTotal == null
          ? null
          : strings.mediaSubtitle(
              libraryTotal,
              context.adminFormats.integer(libraryTotal),
            ),
      scrollable: false,
      // The languages a picture's alt text is written in. The sheet marks
      // each lane by whether the picture has alt text in it.
      body: LangScope(
        locales: [
          for (final code in shopLanguages)
            LocaleInfo(
              code: code,
              status: code == shopLanguages.first
                  ? LocaleStatus.source
                  : LocaleStatus.translated,
            ),
        ],
        visibleLocales: _visibleLocales,
        sourceLocale: shopLanguages.first,
        activeLocale: shopLanguages.contains(language)
            ? language
            : shopLanguages.first,
        onVisibleLocalesChanged: (visible) =>
            setState(() => _visibleLocales = visible),
        child: Builder(
          builder: (context) => AssetLibrary.connected(
            key: MediaTeamKeys.library,
            controller: _library,
            onOpen: (asset) => _openAsset(context, asset),
            toolbarActions: [
              FilterMenuButton<MediaUsage>(
                key: MediaTeamKeys.usageFilter,
                value: _usage,
                tooltip: strings.usage,
                icon: Icons.link_rounded,
                onChanged: _setUsage,
                options: [
                  FilterMenuOption(MediaUsage.all, strings.usageAll),
                  FilterMenuOption(
                    MediaUsage.inUse,
                    strings.usageInUse,
                    icon: Icons.link_rounded,
                  ),
                  FilterMenuOption(
                    MediaUsage.unused,
                    strings.usageUnused,
                    icon: Icons.link_off_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a picture is used, beside the sheet's actions.
class _UsedIn extends StatelessWidget {
  final int count;

  const _UsedIn({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          count == 0 ? Icons.link_off_rounded : Icons.link_rounded,
          size: context.iconSizes.sm,
          color: colors.foregroundMuted,
        ),
        const Gap(AdminSpacing.sm),
        Flexible(
          child: Text(
            context.strings.mediaTeam.usedIn(
              count,
              context.adminFormats.integer(count),
            ),
            style: context.type.caption.copyWith(color: colors.foregroundMuted),
          ),
        ),
      ],
    );
  }
}
