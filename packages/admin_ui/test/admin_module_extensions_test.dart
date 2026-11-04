// AdminModule.extensions: a module contributes extensions of any type, and
// an app collects the kind it knows with extensionsOf.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Provider extends ExternalAssetProvider {
  @override
  final String id;

  _Provider(this.id);

  @override
  String get label => id;

  @override
  IconData get icon => Icons.image_outlined;

  @override
  bool get choosesSize => false;

  @override
  Future<ProviderSearchResult> search({
    String? query,
    int page = 1,
    ProviderFilters filters = const ProviderFilters(),
  }) async => ProviderSearchResult.empty;

  @override
  Future<List<ProviderSize>> sizesFor(ProviderItem item) async => const [];

  @override
  Future<String> import(ProviderItem item, {ProviderSize? size}) async =>
      item.id;
}

Widget _screen(BuildContext context) => const SizedBox();

AdminModule _module({List<Object>? extensions}) => AdminModule(
  route: 'stock',
  navLabel: 'Stock',
  navIcon: Icons.image_search_outlined,
  builder: _screen,
  extensions: extensions ?? const [],
);

void main() {
  test('extensionsOf keeps the extensions of a type, in order', () {
    final first = _Provider('first');
    final second = _Provider('second');
    final module = _module(extensions: [first, 'a command', second, 42]);
    expect(module.extensions, [first, 'a command', second, 42]);
    expect(module.extensionsOf<ExternalAssetProvider>(), [first, second]);
    expect(module.extensionsOf<String>(), ['a command']);
    expect(module.extensionsOf<int>(), [42]);
    expect(module.extensionsOf<DateTime>(), isEmpty);
  });

  test('a module contributes nothing by default', () {
    final module = _module();
    expect(module.extensions, isEmpty);
    expect(module.extensionsOf<ExternalAssetProvider>(), isEmpty);
  });
}
