import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/testing.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Inter's cap height, 1490 of its 2048 units per em. Its ascent less its
/// descent (1984 − 494) is the same, so an evenly led line centres its
/// capitals.
const _interCapHeight = 1490 / 2048;

void main() {
  group('the font each theme names', () {
    test('Iris names Inter in both modes, as shadcn does', () {
      for (final tokens in [irisTheme.tokens, irisTheme.dark!]) {
        final type = tokens.typography;
        expect(type.spec.fontFamily, 'Inter');
        for (final style in [
          type.body,
          type.bodyStrong,
          type.heading,
          type.fieldMessage,
        ]) {
          expect(style.fontFamily, 'Inter');
        }
      }
      expect(shadcnTheme.tokens.typography.spec.fontFamily, 'Inter');
    });

    test('Ant and the default tokens name none, so they never load one', () {
      for (final tokens in [antTheme.tokens, antTheme.dark!, defaultTokens]) {
        final spec = tokens.typography.spec;
        expect(spec.fontFamily, isNull);
        expect(tokens.typography.body.fontFamily, isNull);
      }
    });

    test('the default tokens are Iris in the platform font', () {
      final iris = irisTheme.tokens;
      expect(defaultTokens.palette, iris.palette);
      expect(defaultTokens.typography.spec.ramp, iris.typography.spec.ramp);
      expect(
        defaultTokens.typography.spec.copyWith(fontFamily: 'Inter'),
        iris.typography.spec,
      );
      expect(defaultTokens.sizes, iris.sizes);
      expect(defaultTokens.radii, iris.radii);
    });
  });

  group("Inter keeps Iris's metrics", () {
    test('control heights and the type ramp are the kit\'s own', () {
      for (final tokens in [irisTheme.tokens, irisTheme.dark!]) {
        expect(tokens.sizes, defaultControlSizes);
        expect(
          [
            tokens.sizes.height(ControlSize.small),
            tokens.sizes.height(ControlSize.medium),
            tokens.sizes.height(ControlSize.large),
          ],
          [28, 36, 40],
        );
        expect(tokens.typography.spec.ramp, defaultTypeRamp);
      }
    });

    test('every style keeps its size and line', () {
      final type = irisTheme.tokens.typography;
      final ramp = defaultTypeRamp;
      final styles = {
        'pageTitle': (type.pageTitle, ramp.pageTitle),
        'heading': (type.heading, ramp.heading),
        'sectionLabel': (type.sectionLabel, ramp.sectionLabel),
        'fieldLabel': (type.fieldLabel, ramp.fieldLabel),
        'fieldText': (type.fieldText, ramp.fieldText),
        'fieldDescription': (type.fieldDescription, ramp.fieldDescription),
        'fieldMessage': (type.fieldMessage, ramp.fieldMessage),
        'body': (type.body, ramp.body),
        'bodySmall': (type.bodySmall, ramp.bodySmall),
        'caption': (type.caption, ramp.caption),
        'micro': (type.micro, ramp.micro),
        'button': (type.button, ramp.button),
        'buttonSmall': (type.buttonSmall, ramp.buttonSmall),
      };
      for (final MapEntry(key: role, value: (style, step)) in styles.entries) {
        expect(style.fontSize, step.size, reason: role);
        expect(
          style.fontSize! * style.height!,
          moreOrLessEquals(step.line),
          reason: role,
        );
        expect(
          style.leadingDistribution,
          TextLeadingDistribution.even,
          reason: role,
        );
      }
      expect((ramp.body.size, ramp.body.line), (13, 20));
      expect((ramp.fieldText.size, ramp.fieldText.line), (13, 20));
    });
  });

  testWidgets("Iris's fields draw in Inter, capitals centred in their box", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 400);
    addTearDown(tester.view.reset);
    const medium = ValueKey('medium');
    const small = ValueKey('small');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              children: [
                InputField(key: medium, value: 'SHOP NAME'),
                InputField(
                  key: small,
                  value: 'SHOP NAME',
                  size: ControlSize.small,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(textWithoutFont(), isEmpty);

    final sizes = irisTheme.tokens.sizes;
    for (final (key, height) in [
      (medium, sizes.medium),
      (small, sizes.small),
    ]) {
      final box = tester.getRect(find.byKey(key));
      expect(box.height, height, reason: '$key keeps its control height');
      final editable = _editableUnder(tester.renderObject(find.byKey(key)));
      final style = editable.text!.style!;
      expect(style.fontFamily, 'Inter');
      final painter = TextPainter(
        text: editable.text,
        textDirection: TextDirection.ltr,
        strutStyle: editable.strutStyle,
        textHeightBehavior: editable.textHeightBehavior,
      )..layout();
      final baseline =
          editable.localToGlobal(Offset.zero).dy +
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      painter.dispose();
      final capitals = baseline - _interCapHeight * style.fontSize! / 2;
      expect(
        capitals - box.center.dy,
        moreOrLessEquals(0, epsilon: 0.01),
        reason: 'the capitals of $key sit on its middle',
      );
    }
  });
}

RenderEditable _editableUnder(RenderObject root) {
  RenderEditable? found;
  void visit(RenderObject object) {
    if (object is RenderEditable) {
      found = object;
    } else {
      object.visitChildren(visit);
    }
  }

  root.visitChildren(visit);
  return found!;
}
