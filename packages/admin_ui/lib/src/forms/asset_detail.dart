/// @docImport '../assets/external_provider.dart';
/// @docImport '../common/ui/field_presence.dart';
/// @docImport 'field_binder.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../assets/asset_source.dart';
import '../assets/ui/asset_library.dart';
import '../assets/ui/media_tile.dart';
import '../common/ui/button.dart';
import '../common/ui/copy_button.dart';
import '../common/ui/description_list.dart';
import '../common/ui/modal_anchor.dart';
import '../common/ui/side_sheet.dart';
import '../fields/ui/help_button.dart';
import '../i18n/lang_scope.dart';
import '../i18n/locale_status.dart';
import '../l10n/admin_ui_localizations.dart';
import '../l10n/sections/assets_messages.dart';
import '../theme/sizes.dart';
import '../theme/spacing.dart';
import '../theme/tokens.dart';
import 'cell.dart' show LocalScope, TranslatedCell;
import 'relayed_scopes.dart';
import 'value_fields.dart' show Field;

/// Opens [asset] in a side sheet at the end edge of [modals]: a large
/// preview, its metadata, the app's [actions] (in the header) and
/// [footerActions], and (when [onDelete] is supplied) a delete action.
/// [onDelete] runs *after* the sheet closes, so the host owns confirmation
/// and the actual removal. [onSaveAlt] enables the default-alt editor (see
/// [AssetDetailView]), which needs a [LangScope].
///
/// The sheet sees the scopes above [modals]'s anchor. When that anchor sits
/// above the page that provides them, as `AdminScope`'s does around the
/// whole frame, pass the page's [context]: the sheet then sees the
/// [LangScope], [AssetSourceScope], [ExternalProviderScope],
/// [FieldPresenceScope] and [FieldBinderScope] that [context] sees, as
/// `showAssetEditor` does, so the page needs no anchor of its own below them
/// and an editor opened from the sheet finds them too. A language shown or
/// hidden in the alt lanes goes to the page's [LangScope], which the sheet
/// then follows.
///
/// The sheet mounts a [ModalAnchor] of its own, so an action in it can open
/// a modal on `ModalAnchor.of` over it.
Future<void> showAssetDetail(
  ModalAnchorController modals, {
  required Asset asset,
  VoidCallback? onDelete,
  Future<Asset?> Function(Map<String, String> alt)? onSaveAlt,
  List<Widget> actions = const [],
  List<Widget> footerActions = const [],
  BuildContext? context,
}) {
  final opener = context == null ? null : OpenerScopes.of(context);
  return modals.showSheet<void>(
    width: 460,
    builder: (_) {
      final Widget sheet = ModalAnchor(
        child: AssetDetailView(
          asset: asset,
          onSaveAlt: onSaveAlt,
          actions: actions,
          footerActions: footerActions,
          onDismiss: () => modals.close(),
          onDelete: onDelete == null
              ? null
              : () {
                  modals.close();
                  onDelete();
                },
        ),
      );
      if (opener == null) return sheet;
      return RelayedScopes(opener: opener, child: sheet);
    },
  );
}

/// Detail panel for one [Asset]: preview, name, metadata, the app's
/// [actions] and [footerActions], and an optional delete action. View-pure
/// — render it via [showAssetDetail] or inline in the catalog. When
/// [onSaveAlt] is supplied, the library default alt text is editable per
/// language (requires a [LangScope] ancestor — languages and lane chrome
/// follow the admin's global switcher, and each lane's status says whether
/// the asset has alt text in it); otherwise any existing alt shows
/// read-only.
class AssetDetailView extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onDelete;

  /// Close handler for the sheet's × button (see [SideSheet.onDismiss]).
  final VoidCallback? onDismiss;

  /// Persists the edited default alt; returns the updated [Asset] (null =
  /// failed, the editor stays dirty).
  final Future<Asset?> Function(Map<String, String> alt)? onSaveAlt;

  /// The header's own controls, before its close button: an `IconAction`
  /// that downloads the file, say (see [SideSheet.actions]).
  final List<Widget> actions;

  /// The app's actions on the asset, such as Crop, in the footer at its end
  /// edge, in order; a short note may stand beside them. Delete keeps the
  /// start. They wrap onto a second line when the sheet is too narrow.
  final List<Widget> footerActions;

  const AssetDetailView({
    super.key,
    required this.asset,
    this.onDelete,
    this.onDismiss,
    this.onSaveAlt,
    this.actions = const [],
    this.footerActions = const [],
  });

  bool get _altEditable => onSaveAlt != null;

  Widget? _footer(BuildContext context) {
    final delete = onDelete;
    if (delete == null && footerActions.isEmpty) return null;
    return Row(
      children: [
        if (delete != null)
          Button.danger(
            MaterialLocalizations.of(context).deleteButtonTooltip,
            icon: Icons.delete_outline_rounded,
            onPressed: delete,
          ),
        if (delete != null && footerActions.isNotEmpty)
          const Gap(AdminSpacing.md),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AdminSpacing.sm,
            runSpacing: AdminSpacing.sm,
            children: footerActions,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    final dims = asset.dimsOf(context);
    return SideSheet(
      title: strings.asset,
      actions: actions,
      onDismiss: onDismiss,
      footer: _footer(context),
      child: ListView(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        children: [
          _Preview(asset: asset),
          const Gap(AdminSpacing.xl),
          Text(
            asset.name,
            style: context.type.heading.copyWith(
              color: context.colors.foreground,
            ),
          ),
          const Gap(AdminSpacing.xl),
          DescriptionList(
            layout: DescriptionLayout.stacked,
            columns: 2,
            items: [
              DescriptionItem(
                strings.type,
                value: _typeLabel(strings, asset.type),
              ),
              DescriptionItem(strings.size, value: asset.sizeOf(context)),
              if (dims != null)
                DescriptionItem(strings.dimensions, value: dims),
              DescriptionItem(strings.id, value: asset.id),
              if (!_altEditable && asset.alt.isNotEmpty)
                DescriptionItem(
                  strings.altText,
                  value: [
                    for (final e in asset.alt.entries) '${e.key}: ${e.value}',
                  ].join('\n'),
                  span: true,
                ),
            ],
          ),
          if (_altEditable) ...[
            const Gap(AdminSpacing.xl),
            _AltEditor(
              key: ValueKey('alt-${asset.id}'),
              initial: asset.alt,
              onSave: onSaveAlt!,
            ),
          ],
          if (asset.url != null) ...[
            const Gap(AdminSpacing.xl),
            _UrlRow(url: asset.url!),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final Asset asset;
  const _Preview({required this.asset});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(context.radii.radius);
    final image = asset.type == AssetType.image;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: radius,
        ),
        child: DecoratedBox(
          // The edge over the picture, so a light image keeps one.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: MediaThumb(
              image: image ? asset.thumbnail : null,
              swatch: image ? asset.swatch : null,
              icon: image && asset.swatch != null
                  ? Icons.image_outlined
                  : assetGlyph(asset.type),
              iconSize: 44,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-language editor for the library default alt text: a [Field] over a
/// local (non-CRDT) translated cell, so it gets the standard lane chrome and
/// follows the global language switcher. Edits stay local until the explicit
/// Save — this touches a live library record, not a draft — and [onSave]
/// returning null keeps the edits dirty so nothing is silently lost.
class _AltEditor extends StatefulWidget {
  final Map<String, String> initial;
  final Future<Asset?> Function(Map<String, String> alt) onSave;

  const _AltEditor({super.key, required this.initial, required this.onSave});

  @override
  State<_AltEditor> createState() => _AltEditorState();
}

class _AltEditorState extends State<_AltEditor> {
  final _scope = LocalScope();
  late Map<String, String> _saved = Map.of(widget.initial);
  bool _saving = false;

  TranslatedCell<String> get _cell => _scope.translated('alt');

  @override
  void initState() {
    super.initState();
    for (final e in widget.initial.entries) {
      _cell.lane(e.key).set(e.value);
    }
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  Future<void> _save(Set<String> languages) async {
    final alt = {
      for (final lang in languages)
        if (_cell.lane(lang).value.trim().isNotEmpty)
          lang: _cell.lane(lang).value.trim(),
    };
    setState(() => _saving = true);
    final updated = await widget.onSave(alt);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (updated != null) _saved = Map.of(updated.alt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = LangScope.of(context);
    // Dirty tracking and save span every lane — hidden languages keep their
    // text, and languages no longer in the project still round-trip.
    final languages = {
      for (final l in scope.locales) l.code,
      ...widget.initial.keys,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Each lane says whether the library holds alt text in its language,
        // whatever the page's scope says of its own content there.
        LangScope(
          locales: [
            for (final l in scope.locales)
              l.copyWith(
                status: l.code == scope.sourceLocale
                    ? LocaleStatus.source
                    : (_saved[l.code]?.isNotEmpty ?? false)
                    ? LocaleStatus.translated
                    : LocaleStatus.missing,
              ),
          ],
          visibleLocales: scope.visibleLocales,
          sourceLocale: scope.sourceLocale,
          activeLocale: scope.activeLocale,
          onVisibleLocalesChanged: scope.onVisibleLocalesChanged,
          child: Field(
            _cell,
            label: context.adminL10n.assets.defaultAltText,
            help: HelpButton(text: context.adminL10n.assets.defaultAltTextHelp),
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            for (final lang in languages) _cell.lane(lang),
          ]),
          builder: (context, _) {
            // Trimmed compare, matching what a save would persist — so a
            // successful save reads clean even though the lane keeps the
            // user's whitespace.
            final dirty = languages.any(
              (lang) => _cell.lane(lang).value.trim() != (_saved[lang] ?? ''),
            );
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Button(
                _saving
                    ? context.adminL10n.saving
                    : context.adminL10n.assets.saveAltText,
                variant: ButtonVariant.secondary,
                size: ControlSize.small,
                onPressed: dirty && !_saving ? () => _save(languages) : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UrlRow extends StatelessWidget {
  final String url;
  const _UrlRow({required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.adminL10n.assets.url,
          style: context.type
              .weighted(context.type.caption, FontWeight.w600)
              .copyWith(color: context.colors.foregroundMuted),
        ),
        const Gap(AdminSpacing.xs),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AdminSpacing.md,
            AdminSpacing.xs,
            AdminSpacing.xs,
            AdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Physical: a URL reads left to right in any language.
                    textDirection: TextDirection.ltr,
                    style: context.type.caption.copyWith(
                      color: context.colors.foregroundSecondary,
                    ),
                  ),
                ),
              ),
              const Gap(AdminSpacing.sm),
              CopyButton(url, tooltip: context.adminL10n.assets.copyUrl),
            ],
          ),
        ),
      ],
    );
  }
}

String _typeLabel(AssetsMessages strings, AssetType t) => switch (t) {
  AssetType.image => strings.kindImage,
  AssetType.video => strings.kindVideo,
  AssetType.audio => strings.kindAudio,
  AssetType.document => strings.kindDocument,
  AssetType.other => strings.kindOther,
};
