import 'package:material_ui/material_ui.dart';

import '../../keys/access_keys.dart';
import '../../routing/routes.dart';
import 'set_password_page.dart';
import 'sign_in_page.dart';

Widget signInPage(BuildContext context, SignIn route) =>
    SignInPage(key: AccessKeys.signInPage, route: route);

Widget setPasswordPage(BuildContext context, SetPassword route) =>
    SetPasswordPage(key: AccessKeys.setPasswordPage, route: route);
