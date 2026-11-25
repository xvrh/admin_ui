// AdminIcons: the glyphs the kit draws on its own, a theme's to replace.

import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('value semantics', () {
    const icons = AdminIcons();
    final own = icons.copyWith(close: Icons.cancel);
    expect(icons.copyWith(), icons);
    expect(icons.copyWith().hashCode, icons.hashCode);
    expect(own, isNot(icons));
    expect(own.check, icons.check);
    expect(AdminIcons.lerp(icons, own, 0.4), icons);
    expect(AdminIcons.lerp(icons, own, 0.5), own);
    expect('$icons', "AdminIcons(the kit's)");
    expect('$own', 'AdminIcons(close U+E139 MaterialIcons)');
  });

  testWidgets("an app's glyphs reach the kit's controls", (tester) async {
    final own = const AdminIcons().copyWith(
      close: Icons.cancel,
      check: Icons.done_all,
      error: Icons.report,
      lock: Icons.key,
      diffAdded: Icons.add_box,
    );
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          AdminTokens.from(palette: irisPalette, icons: own),
        ),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return ListView(
                children: [
                  IconAction.close(onPressed: () {}),
                  const Check(value: true),
                  const ErrorState(),
                  const PasswordField(),
                  const PasswordField(icon: null),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(context.icons, own);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.report), findsOneWidget);
    // The default lock follows the theme; null still drops it.
    expect(find.byIcon(Icons.key), findsOneWidget);
    expect(DiffOpStyle.of(context, DiffOp.added).icon, Icons.add_box);
    expect(
      assetGlyph(AssetType.video, icons: own.copyWith(fileVideo: Icons.tv)),
      Icons.tv,
    );
    expect(assetGlyph(AssetType.video), const AdminIcons().fileVideo);
  });

  // Both constructors must set every slot, or the class does not compile;
  // copyWith and the list that ==, hashCode and toString read are not
  // checked that way, so a slot added and missed there is caught here.
  test('every slot is in the constructors, copyWith and the slot list', () {
    final source = File('lib/src/theme/icons.dart').readAsStringSync();
    final slots = [
      for (final m in RegExp(r'final IconData (\w+);').allMatches(source))
        m[1]!,
    ];
    expect(slots, hasLength(greaterThan(100)));
    final missing = [
      for (final slot in slots)
        for (final form in [
          'this.$slot = Icons.',
          'required this.$slot,',
          'IconData? $slot,',
          '$slot: $slot ?? this.$slot,',
          "('$slot', $slot),",
        ])
          if (!source.contains(form)) '$slot: $form',
    ];
    expect(missing, isEmpty);
  });
}
