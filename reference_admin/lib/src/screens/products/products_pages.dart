import 'package:material_ui/material_ui.dart';

import '../../routing/routes.dart';
import 'new_product.dart';
import 'product_editor.dart';
import 'product_list.dart';

Widget productsPage(BuildContext context, Products route) =>
    ProductListScreen(savedView: route.savedView);

Widget newProductPage(BuildContext context, NewProduct route) =>
    const NewProductScreen();

Widget productDetailPage(BuildContext context, ProductDetail route) =>
    ProductEditorScreen(id: route.id, tab: route.tab);
