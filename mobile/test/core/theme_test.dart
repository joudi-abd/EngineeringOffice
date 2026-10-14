import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/theme_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/theme_button.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/review_sheet.dart';

Widget _app(
  ThemeController theme, {
  required void Function(Palette) onPalette,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(value: theme),
      ChangeNotifierProvider<LocaleController>(
        create: (_) => LocaleController(),
      ),
    ],
    child: Builder(
      builder: (context) => MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: const [Palette.day],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          extensions: const [Palette.night],
        ),
        themeMode: context.watch<ThemeController>().mode,
        home: Builder(
          builder: (context) {
            onPalette(context.pal);
            return const Scaffold(body: Center(child: ThemeButton()));
          },
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ThemeController', () {
    test('follows the phone until the visitor chooses', () async {
      final theme = ThemeController();
      await theme.start();
      expect(theme.mode, ThemeMode.system);
      expect(theme.isChosen, isFalse);
    });

    test('remembers the choice and restores it', () async {
      final theme = ThemeController();
      await theme.toggle(currentlyDark: true);
      expect(theme.mode, ThemeMode.light);

      final restored = ThemeController();
      await restored.start();
      expect(restored.mode, ThemeMode.light);

      await restored.toggle(currentlyDark: false);
      expect(restored.mode, ThemeMode.dark);
    });

    test('pressing again so it matches the phone hands control back', () async {
      final theme = ThemeController();
      // phone is dark and the app is dark: first press overrides to light...
      await theme.toggle(currentlyDark: true, systemDark: true);
      expect(theme.mode, ThemeMode.light);
      // ...second press lands on what the phone shows, so the override is dropped
      await theme.toggle(currentlyDark: false, systemDark: true);
      expect(theme.mode, ThemeMode.system);
      expect(theme.isChosen, isFalse);

      final restored = ThemeController();
      await restored.start();
      expect(restored.mode, ThemeMode.system);
    });

    test('can go back to following the phone', () async {
      final theme = ThemeController();
      await theme.toggle(currentlyDark: false);
      await theme.followSystem();
      expect(theme.mode, ThemeMode.system);

      final restored = ThemeController();
      await restored.start();
      expect(restored.mode, ThemeMode.system);
    });
  });

  group('day / night', () {
    testWidgets('starts in the phone\'s mode and follows it live', (
      tester,
    ) async {
      late Palette seen;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(
        _app(ThemeController(), onPalette: (p) => seen = p),
      );
      await tester.pumpAndSettle();
      expect(seen.dark, isFalse);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(seen.dark, isTrue);
    });

    testWidgets('the button overrides the phone and sticks', (tester) async {
      late Palette seen;
      final theme = ThemeController();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_app(theme, onPalette: (p) => seen = p));
      await tester.pumpAndSettle();
      expect(seen.dark, isTrue);

      await tester.tap(find.byType(ThemeButton));
      await tester.pumpAndSettle();
      expect(theme.mode, ThemeMode.light);
      expect(seen.dark, isFalse);

      // the phone going dark again no longer matters
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(seen.dark, isFalse);

      // the second press lands on what the phone shows, so the phone is in charge again
      await tester.tap(find.byType(ThemeButton));
      await tester.pumpAndSettle();
      expect(theme.mode, ThemeMode.system);
      expect(seen.dark, isTrue);
    });
  });

  group('hand-back and open sheets', () {
    testWidgets('a second press returns to following the phone', (
      tester,
    ) async {
      late Palette seen;
      final theme = ThemeController();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_app(theme, onPalette: (p) => seen = p));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ThemeButton)); // dark -> light (chosen)
      await tester.pumpAndSettle();
      expect(theme.mode, ThemeMode.light);

      await tester.tap(find.byType(ThemeButton)); // light -> dark == phone
      await tester.pumpAndSettle();
      expect(theme.mode, ThemeMode.system);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(seen.dark, isFalse, reason: 'follows the phone again');
    });

    testWidgets('an open bottom sheet changes look with the phone', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      const day = Color(0xFFE8E4DA);
      const night = Color(0xFF141414);

      ThemeData theme(Brightness b, Color sheet) => ThemeData(
        brightness: b,
        extensions: [b == Brightness.dark ? Palette.night : Palette.day],
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: sheet,
          modalBackgroundColor: sheet,
          surfaceTintColor: Colors.transparent,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
          child: MaterialApp(
            theme: theme(Brightness.light, day),
            darkTheme: theme(Brightness.dark, night),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      ReviewSheet.show(context, projectId: 1, rating: 4),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Color? sheetColor() => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byType(ReviewSheet),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color;

      expect(find.byType(ReviewSheet), findsOneWidget);
      expect(sheetColor(), day);

      // type something, then the phone goes dark while the sheet is open
      await tester.enterText(find.byType(TextField).first, 'Ahmad');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      expect(find.byType(ReviewSheet), findsOneWidget, reason: 'still open');
      expect(sheetColor(), night, reason: 'sheet followed the phone');
      expect(find.text('Ahmad'), findsOneWidget, reason: 'typed text kept');
    });
  });
}
