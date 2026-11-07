import 'package:admin_ui/fields.dart' show FormColumns, FormGrid;
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';

typedef RefundValue = ({double amount, String reason});

/// The order as the dialog last heard of it, and what this dialog refunded:
/// nothing when it only learnt of a change made elsewhere.
typedef RefundOutcome = ({Order order, int refundedCents});

extension type RefundFields(FormScope _s) {
  ValueCell<double> get amount => _s.decimal('amount');
  ValueCell<String> get reason => _s.text('reason');
}

/// Refunds part or all of [order]. Resolves to the order as it now stands,
/// refunded or as the shop reported it on refusing (someone refunded part
/// of it meanwhile), or to null when nothing changed.
Future<RefundOutcome?> showRefundDialog(BuildContext context, Order order) =>
    showModal<RefundOutcome>(
      context,
      barrierDismissible: false,
      builder: (context) => RefundDialog(order: order),
    );

class RefundDialog extends StatefulWidget {
  final Order order;
  const RefundDialog({super.key, required this.order});

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final ShopApi _api = context.api;

  /// The order as last heard from the shop.
  late Order _order = widget.order;

  /// Set once the shop told of a change this dialog did not make.
  Order? _changed;

  late final _form = ValueFormController<RefundValue>(
    initial: (amount: widget.order.refundableCents / 100, reason: ''),
    requireChanges: false,
    read: (s) {
      final f = RefundFields(s);
      return (amount: f.amount.value, reason: f.reason.value);
    },
    write: (s, v) => RefundFields(s)
      ..amount.set(v.amount)
      ..reason.set(v.reason),
    rules: (s) {
      final f = RefundFields(s);
      return [
        FieldRules(
          f.amount,
          validators: [
            Validators.required(),
            (v, l10n) => Validators.min(
              0.01,
              message: context.strings.orders.refundInvalid,
            )(v, l10n),
            // Made again at each check: the refundable amount moves when the
            // shop reports a refund made meanwhile.
            (v, l10n) => Validators.max(
              _order.refundableCents / 100,
              message: context.strings.orders.refundTooHigh,
            )(v, l10n),
          ],
        ),
        FieldRules(f.reason, validators: [Validators.maxLength(120)]),
      ];
    },
    onSubmit: _refund,
  );

  String _hint(BuildContext context) => context.strings.orders.refundableHint(
    formatMoney(context, _order.refundableCents),
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _refund(RefundValue value) async {
    final cents = (value.amount * 100).round();
    final amountId = RefundFields(_form.scope).amount.id;
    try {
      final refunded = await _api.refund(
        _order.number,
        cents,
        value.reason.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop((order: refunded, refundedCents: cents));
      }
    } on ValidationError catch (error) {
      if (!mounted) rethrow;
      final strings = context.strings.orders;
      if (error.fields['amount'] == ValidationCodes.tooHigh) {
        await _reload();
      }
      if (!mounted) return;
      // The shop names the refused field by the call's parameter; the form
      // files it under the cell's id, which is its field name here.
      final tooHigh = error.fields['amount'] == ValidationCodes.tooHigh;
      throw FormSubmitException(
        message: tooHigh ? strings.refundChanged : null,
        fieldErrors: {
          amountId: tooHigh ? strings.refundTooHigh : strings.refundInvalid,
        },
      );
    }
  }

  void _close() =>
      Navigator.of(context)
          .pop(_changed == null ? null : (order: _changed!, refundedCents: 0));

  Future<void> _reload() async {
    try {
      final fresh = await _api.order(_order.number);
      if (!mounted) return;
      setState(() => _order = _changed = fresh);
    } on ShopError {
      // The refusal still stands; the hint keeps the amount it had.
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final kit = MaterialLocalizations.of(context);
    final compact = AdminBreakpoint.of(context).isCompact;
    final f = RefundFields(_form.scope);
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) {
        final submitting = _form.status == FormStatus.submitting;
        final error =
            _form.submitError ??
            switch (_form.submitFailure) {
              final failure? => ErrorTextScope.describe(context, failure),
              null => null,
            };
        return Modal(
          key: OrdersKeys.refundDialog,
          title: strings.refundTitle(bidiIsolate(_order.label)),
          description: strings.refundDescription,
          size: compact ? ModalSize.fullscreen : ModalSize.medium,
          onDismiss: submitting ? null : () => _close(),
          body: ValueForm(
            controller: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  Alert(error, severity: Severity.danger),
                  const Gap(AdminSpacing.lg),
                ],
                FormGrid(
                  columns: const FormColumns.fixed(1),
                  children: [
                    // FRICTION(F-009): DecimalField has a prefix and no
                    // currency mode, so the euro sign leads in every locale.
                    DecimalField(
                      f.amount,
                      key: OrdersKeys.refundAmount,
                      label: strings.amount,
                      prefix: '€',
                      description: _hint(context),
                    ),
                    Field(
                      f.reason,
                      key: OrdersKeys.refundReason,
                      label: strings.reason,
                      hint: strings.reasonHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Button.ghost(
              kit.cancelButtonLabel,
              onPressed: submitting ? null : () => _close(),
            ),
            Button.primary(
              strings.refundAction,
              key: OrdersKeys.refundConfirm,
              icon: Icons.undo,
              loading: submitting,
              onPressed: _form.canSubmit ? _form.requestSubmit : null,
            ),
          ],
        );
      },
    );
  }
}
