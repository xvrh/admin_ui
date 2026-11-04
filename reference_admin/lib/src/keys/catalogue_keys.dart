import 'package:flutter/foundation.dart';

/// Keys of this area's controls, as `ValueKey('<area>.<thing>')`.
abstract final class CatalogueKeys {
  static const productsPage = ValueKey('catalogue.productsPage');
  static const newProductPage = ValueKey('catalogue.newProductPage');
  static const productPage = ValueKey('catalogue.productPage');

  // The list
  static const newProduct = ValueKey('catalogue.newProduct');
  static const collection = ValueKey('catalogue.collection');
  static const columns = ValueKey('catalogue.columns');
  static const savedViews = ValueKey('catalogue.savedViews');
  static const filters = ValueKey('catalogue.filters');

  /// A row's product link (its identity cell, or its card).
  static ValueKey<String> product(String id) => ValueKey('catalogue.row.$id');

  /// A row's stock cell, which edits in place.
  static ValueKey<String> stock(String id) => ValueKey('catalogue.stock.$id');

  /// The stock editor open in the table.
  static const stockEditor = ValueKey('catalogue.stockEditor');

  // The editor
  static const editor = ValueKey('catalogue.editor');
  static const tabs = ValueKey('catalogue.tabs');
  static const localeTabs = ValueKey('catalogue.localeTabs');
  static const presence = ValueKey('catalogue.presence');
  static const summary = ValueKey('catalogue.summary');
  static const saveBar = ValueKey('catalogue.saveBar');
  static const readOnly = ValueKey('catalogue.readOnly');
  static const notFound = ValueKey('catalogue.notFound');
  static const name = ValueKey('catalogue.name');
  static const description = ValueKey('catalogue.description');
  static const sku = ValueKey('catalogue.sku');
  static const price = ValueKey('catalogue.price');
  static const compareAt = ValueKey('catalogue.compareAt');
  static const stockField = ValueKey('catalogue.stockField');
  static const lowStockAt = ValueKey('catalogue.lowStockAt');
  static const category = ValueKey('catalogue.category');
  static const status = ValueKey('catalogue.status');
  static const tags = ValueKey('catalogue.tags');
  static const supplier = ValueKey('catalogue.supplier');
  static const featured = ValueKey('catalogue.featured');
  static const availableFrom = ValueKey('catalogue.availableFrom');
  static const labelColor = ValueKey('catalogue.labelColor');
  static const care = ValueKey('catalogue.care');
  static const variants = ValueKey('catalogue.variants');
  static const photos = ValueKey('catalogue.photos');

  // History
  static const history = ValueKey('catalogue.history');
  static const timeline = ValueKey('catalogue.timeline');
  static const diff = ValueKey('catalogue.diff');

  // New product
  static const newName = ValueKey('catalogue.new.name');
  static const newSku = ValueKey('catalogue.new.sku');
  static const newCategory = ValueKey('catalogue.new.category');
  static const newPrice = ValueKey('catalogue.new.price');
  static const newStock = ValueKey('catalogue.new.stock');
  static const newStatus = ValueKey('catalogue.new.status');
}
