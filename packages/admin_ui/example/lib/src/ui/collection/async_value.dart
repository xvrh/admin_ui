import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import 'sample.dart';

/// The state the demo is pinned in, picked with its "State" knob so each one
/// is a static preview.
enum _State {
  live('Live'),
  firstLoad('First load'),
  refreshing('Refreshing'),
  error('Error');

  final String label;
  const _State(this.label);
}

/// Demo — one value loaded outside a table: an [AsyncValueController] over a
/// fake fetch of one product, drawn by an [AsyncValueBuilder]. Live, the
/// fetch takes 450ms and fails while "Fail next load" is on; the "State"
/// knob pins the first load, a refresh that keeps the product on screen,
/// and a failed load.
class AsyncValueDemo extends StatelessWidget {
  @Preview(name: 'One value (controller + builder)', wrapper: adminUiPreview)
  const AsyncValueDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.knobs.picker('State', {
      for (final s in _State.values) s.label: s,
    }, _State.live);
    return _Demo(key: ValueKey(state), state: state);
  }
}

class _Demo extends StatefulWidget {
  final _State state;
  const _Demo({super.key, required this.state});

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _product = sampleProducts(3)[2];
  final _never = Completer<Product>();
  var _loads = 0;
  var _failNext = false;

  late final _controller = AsyncValueController<Product>(fetcher: _fetch);

  Future<Product> _fetch() async {
    _loads++;
    switch (widget.state) {
      case _State.firstLoad:
        return _never.future;
      case _State.refreshing when _loads > 1:
        return _never.future;
      case _State.error:
        throw Exception('Connection refused');
      case _State.live:
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (_failNext) throw Exception('Connection refused');
      case _State.refreshing:
    }
    return _product;
  }

  @override
  void initState() {
    super.initState();
    if (widget.state == _State.refreshing) {
      void refresh() {
        if (!_controller.hasValue) return;
        _controller.removeListener(refresh);
        scheduleMicrotask(_controller.refresh);
      }

      _controller.addListener(refresh);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        Row(
          children: [
            Toggle(
              value: _failNext,
              onChanged: (v) => setState(() => _failNext = v),
              label: 'Fail next load',
            ),
            const Spacer(),
            Button(
              'Refresh',
              icon: Icons.refresh,
              onPressed: _controller.refresh,
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),
        Panel(
          child: AsyncValueBuilder<Product>(
            controller: _controller,
            builder: (context, product) => _Summary(product),
          ),
        ),
      ],
    );
  }
}

/// A product in a few lines: what the builder draws once it has landed.
class _Summary extends StatelessWidget {
  final Product product;
  const _Summary(this.product);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product.name, style: context.type.heading)),
              Tag(product.status, severity: product.tone, dot: true),
            ],
          ),
          const Gap(AdminSpacing.lg),
          DescriptionList(
            items: [
              DescriptionItem('SKU', value: product.sku),
              DescriptionItem('Category', value: product.category),
              DescriptionItem(
                'Price',
                value: context.adminFormats.decimal(
                  product.price,
                  fractionDigits: 2,
                ),
              ),
              DescriptionItem(
                'Stock',
                value: product.stock == null
                    ? null
                    : context.adminFormats.integer(product.stock!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
