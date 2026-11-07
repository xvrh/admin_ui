import 'package:admin_ui/forms.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';
import '../settings/appearance/settings_tabs.dart';
import '../setup/shop_form.dart';

/// `/settings/shop`: the shop's details and shipping zones, edited with the
/// wizard's own sections and saved whole from the bar under the page.
class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  late final AppServices _services = context.services;
  late RefStrings _strings;

  ShopSettings? _shop;
  ShopError? _error;

  late final _form = ValueFormController<ShopSettings>(
    read: (s) => ShopFields(s).read(_shop ?? ShopSettings.blank),
    write: (s, shop) => ShopFields(s).fill(shop),
    rules: (s) => shopRules(ShopFields(s), () => _strings.access),
    onSubmit: _save,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _strings = context.strings;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final shop = await _services.api.shop();
      if (!mounted) return;
      _shop = shop;
      _form.seed(shop);
      setState(() {});
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save(ShopSettings shop) async {
    try {
      final saved = _shop = await _services.api.saveShop(shop);
      _services.session.shopRenamed(saved.name);
    } on ValidationError catch (error) {
      throw shopSubmitError(error, ShopFields(_form.scope), _strings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final error = _error;
    final shop = _shop;
    final canEdit = _services.session.can(Permission.manageShop);

    final Widget body;
    if (error != null) {
      body = ErrorState(
        title: strings.shopLoadErrorTitle,
        message: context.strings.shell.error(error),
        onRetry: _load,
      );
    } else if (shop == null) {
      body = const Center(child: Spinner());
    } else {
      final f = ShopFields(_form.scope);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            title: strings.stepDetails,
            description: strings.detailsSectionDescription,
            children: [ShopDetailsFields(fields: f)],
          ),
          const Gap(AdminSpacing.xl),
          SettingsCard(
            title: strings.stepShipping,
            description: strings.shippingSectionDescription,
            children: [ShippingZonesField(fields: f)],
          ),
        ],
      );
    }

    return UnsavedChangesGuard(
      controller: _form,
      child: ValueForm(
        controller: _form,
        readOnly: !canEdit,
        child: SettingsScaffold(
          key: AccessKeys.shopSettingsPage,
          section: SettingsSection.shop,
          subtitle: strings.shopSettingsSubtitle,
          body: body,
          bottomBar: shop == null || !canEdit
              ? null
              : FormSaveBar(
                  key: AccessKeys.shopSaveBar,
                  controller: _form,
                  placement: SaveBarPlacement.bottom,
                  showDiscard: true,
                ),
        ),
      ),
    );
  }
}
