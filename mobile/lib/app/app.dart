import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/app/site_bootstrap.dart';
import 'package:ufuq_imperium/core/localization/copy.dart';
import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/theme_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/grain.dart';
import 'package:ufuq_imperium/core/widgets/states.dart';
import 'package:ufuq_imperium/features/about/presentation/about_screen.dart';
import 'package:ufuq_imperium/features/contact/presentation/contact_screen.dart';
import 'package:ufuq_imperium/features/home/presentation/home_screen.dart';
import 'package:ufuq_imperium/features/projects/presentation/projects_screen.dart';
import 'package:ufuq_imperium/features/services/presentation/services_screen.dart';
import 'package:ufuq_imperium/features/shell/presentation/app_shell.dart';

class UfuqApp extends StatelessWidget {
  const UfuqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final lang = locale.lang;
    final themeMode = context.watch<ThemeController>().mode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: locale.c.brand,
      locale: Locale(lang.name),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(lang, Palette.day),
      darkTheme: _theme(lang, Palette.night),
      themeMode: themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final icons = context.pal.dark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: icons,
            statusBarBrightness: context.pal.dark
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: icons,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MediaQuery(
            // Keep the layout intact for very large system text.
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child ?? const SizedBox.shrink(),
                GrainOverlay(
                  opacity: context.pal.dark ? 0.06 : 0.07,
                  onLight: !context.pal.dark,
                ),
              ],
            ),
          ),
        );
      },
      home: const _Root(),
    );
  }

  ThemeData _theme(Lang lang, Palette pal) {
    final family = lang == Lang.ar ? 'Bukra' : 'NeuePower';
    final brightness = pal.dark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: pal.accent,
      onPrimary: pal.onAccent,
      secondary: pal.accentSoft,
      onSecondary: pal.onAccent,
      surface: pal.bg,
      onSurface: pal.text,
      error: pal.error,
      onError: pal.bg,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [pal],
      scaffoldBackgroundColor: pal.bg,
      canvasColor: pal.bg,
      fontFamily: family,
      fontFamilyFallback: [lang == Lang.ar ? 'NeuePower' : 'Bukra'],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: pal.accentSoft,
        selectionColor: pal.accent.withValues(alpha: 0.35),
        selectionHandleColor: pal.accentSoft,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: pal.accentSoft),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: pal.bg2,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: pal.bg2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pal.bg2,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pal.bg3,
        contentTextStyle: TextStyle(color: pal.text, fontFamily: family),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Chooses between the loader, the error page and the app itself.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final site = context.watch<SiteBootstrap>();
    final Widget child;
    if (site.hasData) {
      child = AppShell(
        key: const ValueKey('shell'),
        onRefresh: site.load,
        pages: const [
          HomeScreen(),
          AboutScreen(),
          ServicesScreen(),
          ProjectsScreen(),
          ContactScreen(),
        ],
      );
    } else if (site.state == LoadState.failed) {
      child = ErrorState(
        key: const ValueKey('error'),
        title: locale.c.retryTitle,
        text: locale.c.retryText,
        action: locale.c.retry,
        onRetry: site.load,
      );
    } else {
      child = const BrandLoader(key: ValueKey('loader'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Brand.ease,
      child: child,
    );
  }
}
