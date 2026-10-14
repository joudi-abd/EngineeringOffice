import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/core/widgets/states.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [Palette.night]),
  home: child,
);

void main() {
  testWidgets('Reveal plays for a block that crosses the line on the last '
      'frame of a scroll', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 1600),
                Reveal(child: Container(key: const Key('late'), height: 200)),
                const SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      ),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.byKey(const Key('late')),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    expect(opacity(), 0);

    // One jump, then nothing else scrolls: the block must still appear.
    controller.jumpTo(1000);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(opacity(), 1);
  });

  testWidgets('ErrorState draws its text on a Material (no debug underline)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ErrorState(
          title: 'Connection lost',
          text: 'Try again',
          action: 'Retry',
          onRetry: () {},
        ),
      ),
    );
    final material = find.ancestor(
      of: find.text('Connection lost'),
      matching: find.byType(Material),
    );
    expect(material, findsWidgets);
  });
}
