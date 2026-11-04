import 'package:material_ui/material_ui.dart';

import '../../common/ui/alert.dart';
import '../../common/ui/button.dart';
import '../../common/ui/error_text.dart';
import '../../common/ui/modal.dart';
import '../../common/ui/severity.dart';
import '../../common/ui/spinner.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../external_provider.dart';
import 'media_tile.dart';

/// Confirms licensing one [item] from a provider and runs the import inside the
/// modal. When [choosesSize] is true a size chooser is loaded via [loadSizes]
/// and the confirm stays disabled until a size is picked. The action runs
/// [onImport] with the chosen size: the button spins, a thrown error surfaces
/// inline as a danger [Alert] worded by [ErrorTextScope.describe] (so the
/// user can retry), and on success the modal pops the new local asset id.
/// Resolves null on cancel/dismiss.
Future<String?> showProviderImport(
  BuildContext context, {
  required ProviderItem item,
  required String providerLabel,
  required bool choosesSize,
  required Future<List<ProviderSize>> Function() loadSizes,
  required Future<String> Function(ProviderSize? size) onImport,
}) {
  return showModal<String>(
    context,
    barrierDismissible: false,
    builder: (_) => _ImportSheet(
      item: item,
      providerLabel: providerLabel,
      choosesSize: choosesSize,
      loadSizes: loadSizes,
      onImport: onImport,
    ),
  );
}

class _ImportSheet extends StatefulWidget {
  final ProviderItem item;
  final String providerLabel;
  final bool choosesSize;
  final Future<List<ProviderSize>> Function() loadSizes;
  final Future<String> Function(ProviderSize? size) onImport;

  const _ImportSheet({
    required this.item,
    required this.providerLabel,
    required this.choosesSize,
    required this.loadSizes,
    required this.onImport,
  });

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  List<ProviderSize>? _sizes;
  ProviderSize? _selected;
  Object? _sizesError;
  bool _importing = false;
  Object? _importError;

  @override
  void initState() {
    super.initState();
    if (widget.choosesSize) _loadSizes();
  }

  Future<void> _loadSizes() async {
    setState(() => _sizesError = null);
    try {
      final sizes = await widget.loadSizes();
      if (!mounted) return;
      setState(() {
        _sizes = sizes;
        _selected = sizes.isNotEmpty ? sizes.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sizesError = e);
    }
  }

  bool get _canConfirm {
    if (_importing) return false;
    if (!widget.choosesSize) return true;
    return _selected != null;
  }

  Future<void> _confirm() async {
    setState(() {
      _importing = true;
      _importError = null;
    });
    try {
      final id = await widget.onImport(_selected);
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _importError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    return Modal(
      title: strings.licenseFrom(widget.providerLabel),
      maxWidth: 460,
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Preview(item: widget.item),
              const Gap(AdminSpacing.lg),
              if (widget.choosesSize) _sizeChooser(context),
              Padding(
                padding: const EdgeInsets.only(top: AdminSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: context.iconSizes.md,
                      color: context.colors.foregroundMuted,
                    ),
                    const Gap(AdminSpacing.sm),
                    Expanded(
                      child: Text(
                        strings.licenseDetail(widget.providerLabel, 1),
                        style: context.type.caption.copyWith(
                          color: context.colors.foregroundMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_importError case final error?) ...[
                const Gap(AdminSpacing.lg),
                Alert(
                  ErrorTextScope.describe(context, error),
                  title: strings.couldNotLicense,
                  severity: Severity.danger,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Button(
          MaterialLocalizations.of(context).cancelButtonLabel,
          variant: ButtonVariant.ghost,
          onPressed: _importing ? null : () => Navigator.of(context).pop(),
        ),
        Button.primary(
          strings.licenseAndAdd,
          loading: _importing,
          onPressed: _canConfirm ? _confirm : null,
        ),
      ],
    );
  }

  Widget _sizeChooser(BuildContext context) {
    if (_sizesError case final error?) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
        child: Alert(
          ErrorTextScope.describe(context, error),
          title: context.adminL10n.assets.couldNotLoadSizes,
          severity: Severity.danger,
          action: Button(
            context.adminL10n.retry,
            variant: ButtonVariant.secondary,
            size: ControlSize.small,
            onPressed: _loadSizes,
          ),
        ),
      );
    }
    if (_sizes == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AdminSpacing.lg),
        child: Center(child: Spinner()),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
            child: Text(
              context.adminL10n.assets.size,
              style: context.type
                  .weighted(context.type.caption, FontWeight.w600)
                  .copyWith(color: context.colors.foregroundMuted),
            ),
          ),
          for (final size in _sizes!)
            _SizeRow(
              size: size,
              selected: size.id == _selected?.id,
              onTap: _importing ? null : () => setState(() => _selected = size),
            ),
        ],
      ),
    );
  }
}

/// One licensable size: a radio row whose hover, press and focus paint over
/// its fill, chosen or not.
class _SizeRow extends StatelessWidget {
  final ProviderSize size;
  final bool selected;
  final VoidCallback? onTap;

  const _SizeRow({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radius;
    final base = selected ? colors.primarySubtle : colors.background;
    final dims = [
      if ((size.width, size.height) case (final w?, final h?))
        context.adminL10n.assets.pixelSize(w, h),
      size.format?.toUpperCase(),
    ].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: Tappable.states(
        onTap: onTap,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        semanticLabel: dims.isEmpty ? size.label : '${size.label}, $dims',
        excludeSemantics: true,
        focusRadius: radius,
        builder: (context, states) {
          final overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : states.contains(WidgetState.hovered)
              ? colors.hoverOverlay
              : null;
          final fill = overlay == null ? base : Color.alphaBlend(overlay, base);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected
                    ? context.stroke.controlStrong
                    : context.stroke.control,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: context.iconSizes.lg,
                  color: selected ? colors.primaryText : colors.controlBorder,
                ),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: Text(
                    size.label,
                    style: context.type
                        .weighted(context.type.body, FontWeight.w600)
                        .copyWith(color: colors.foreground),
                  ),
                ),
                Text(
                  dims,
                  style: context.type.caption.copyWith(
                    color: colors.readableOn(
                      colors.foregroundMuted,
                      surfaces: [fill],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final ProviderItem item;
  const _Preview({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.radii.radius),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: MediaThumb(
          image: item.preview,
          swatch: item.swatch,
          iconSize: 28,
        ),
      ),
    );
  }
}
