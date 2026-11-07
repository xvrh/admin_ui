import 'package:admin_ui/forms.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import 'shop_form.dart';

/// `/setup`: the first run of a blank shop, in three steps over one form
/// (details, shipping, review). Nothing is saved before Finish, which
/// completes the setup in one call.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final AppServices _services = context.services;
  late RefStrings _strings;

  /// The shop as loaded: what the form starts from and saves over.
  ShopSettings? _shop;
  ShopError? _error;

  /// The shop as completed, once Finish went through.
  ShopSettings? _ready;

  late final _form = ValueFormController<ShopSettings>(
    read: (s) => ShopFields(s).read(_shop ?? ShopSettings.blank),
    write: (s, shop) => ShopFields(s).fill(shop),
    initial: _startingPoint(ShopSettings.blank),
    rules: (s) => shopRules(ShopFields(s), () => _strings.access),
    onSubmit: _complete,
    requireChanges: false,
  );

  ShopFields get _fields => ShopFields(_form.scope);

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

  /// A blank shop opens on one empty shipping zone to fill in.
  static ShopSettings _startingPoint(ShopSettings shop) =>
      shop.shippingZones.isNotEmpty
      ? shop
      : shop.copyWith(
          shippingZones: const [
            ShippingZone(name: '', countries: [], rateCents: 0),
          ],
        );

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final shop = await _services.api.shop();
      if (!mounted) return;
      _form.seed(_startingPoint(shop));
      setState(() => _shop = shop);
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _complete(ShopSettings shop) async {
    try {
      final done = await _services.api.completeSetup(shop);
      _services.session.shopRenamed(done.name);
      if (mounted) setState(() => _ready = done);
    } on ValidationError catch (error) {
      throw shopSubmitError(error, _fields, _strings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final shop = _shop;
    final error = _error;
    final ready = _ready ?? (shop != null && shop.setupComplete ? shop : null);
    final Widget body;
    if (error != null) {
      body = ErrorState(
        message: context.strings.shell.error(error),
        onRetry: _load,
      );
    } else if (shop == null) {
      body = const Center(child: Spinner());
    } else if (ready != null) {
      body = _Ready(shop: ready);
    } else {
      body = FormWizard(
        key: AccessKeys.wizard,
        controller: _form,
        finishLabel: strings.finishSetup,
        summary: const ValidationSummary(key: AccessKeys.summary),
        steps: _steps(context),
      );
    }
    return UnsavedChangesGuard(
      controller: _form,
      enabled: ready == null,
      child: PageScaffold(
        key: AccessKeys.setupPage,
        title: strings.setupTitle,
        subtitle: ready == null ? strings.setupSubtitle : null,
        maxWidth: 820,
        body: body,
      ),
    );
  }

  List<FormWizardStep> _steps(BuildContext context) {
    final strings = context.strings.access;
    final f = _fields;
    return [
      FormWizardStep(
        title: strings.stepDetails,
        subtitle: strings.stepDetailsSubtitle,
        fields: [f.name, f.supportEmail, f.currency, f.taxRate, f.languages],
        builder: (context) => ShopDetailsFields(fields: f),
      ),
      FormWizardStep(
        title: strings.stepShipping,
        subtitle: strings.stepShippingSubtitle,
        fields: [
          f.zones,
          for (final zone in f.zones.elements) ...[
            zone.name,
            zone.countries,
            zone.rate,
          ],
        ],
        builder: (context) => ShippingZonesField(fields: f),
      ),
      FormWizardStep(
        title: strings.stepReview,
        subtitle: strings.stepReviewSubtitle,
        fields: const [],
        builder: (context) => ListenableBuilder(
          listenable: _form,
          builder: (context, _) =>
              ShopReview(shop: f.read(_shop ?? ShopSettings.blank)),
        ),
      ),
    ];
  }
}

/// The wizard's last step: every value entered, to check before finishing.
class ShopReview extends StatelessWidget {
  final ShopSettings shop;

  const ShopReview({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final symbol = currencySymbol(shop.currency);
    final formats = context.adminFormats;
    String rate(int cents) =>
        '$symbol${formats.decimal(cents / 100, fractionDigits: 2)}';
    return Column(
      key: AccessKeys.review,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.access.reviewIntro, style: context.type.bodyMuted),
        const Gap(AdminSpacing.xl),
        Panel(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: DescriptionList(
            items: [
              DescriptionItem(strings.access.shopName, value: shop.name),
              DescriptionItem(
                strings.access.supportEmail,
                value: bidiIsolate(shop.supportEmail),
              ),
              DescriptionItem(
                strings.access.currency,
                value: strings.access.currencyName(shop.currency),
              ),
              DescriptionItem(
                strings.access.taxRate,
                value: formats.percent(shop.taxRatePercent / 100, decimals: 1),
              ),
              DescriptionItem(
                strings.access.languages,
                value: [
                  for (final code in shop.languages)
                    strings.shell.languageName(code),
                ].join(', '),
              ),
              for (final zone in shop.shippingZones)
                DescriptionItem(
                  zone.name,
                  value: strings.access.zoneSummary(
                    bidiIsolate(zone.countries.join(', ')),
                    rate(zone.rateCents),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The shop once set up: where to go next.
class _Ready extends StatelessWidget {
  final ShopSettings shop;
  const _Ready({required this.shop});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    return Panel(
      // FRICTION(F-107): EmptyState has no tone, so this success reads in
      // the muted grey of an empty list.
      child: EmptyState(
        key: AccessKeys.ready,
        icon: Icons.check_circle_outline_rounded,
        title: strings.readyTitle,
        message: strings.readyMessage(bidiIsolate(shop.name)),
        minHeight: 360,
        action: Wrap(
          alignment: WrapAlignment.center,
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.primary(
              strings.goToDashboard,
              key: AccessKeys.goToDashboard,
              onPressed: () => context.go(const Dashboard()),
            ),
            if (context.services.session.can(Permission.editCatalogue))
              Button(
                strings.addFirstProduct,
                icon: Icons.add_rounded,
                onPressed: () => context.go(const NewProduct()),
              ),
          ],
        ),
      ),
    );
  }
}
