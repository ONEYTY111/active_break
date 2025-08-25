import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:active_break/main.dart';
import 'package:active_break/providers/user_provider.dart';
import 'package:active_break/providers/theme_provider.dart';
import 'package:active_break/providers/language_provider.dart';
import 'package:active_break/providers/activity_provider.dart';
import 'package:active_break/providers/tips_provider.dart';

void main() {
  group('Active Break App Tests', () {
    testWidgets('App should show login screen when not logged in', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => ActivityProvider()),
            ChangeNotifierProvider(create: (_) => TipsProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that login screen is shown
      expect(
        find.byType(TextField),
        findsAtLeast(2),
      ); // Email and password fields
      expect(find.text('登录'), findsOneWidget); // Login button in Chinese
    });

    testWidgets('Theme provider should work correctly', (
      WidgetTester tester,
    ) async {
      final themeProvider = ThemeProvider();

      // Test initial theme mode
      expect(themeProvider.themeMode, ThemeMode.system);

      // Test theme change
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
    });

    testWidgets('Language provider should work correctly', (
      WidgetTester tester,
    ) async {
      final languageProvider = LanguageProvider();

      // Test initial language
      expect(languageProvider.locale.languageCode, 'en');
      expect(languageProvider.isChinese, false);
      expect(languageProvider.isEnglish, true);

      // Test language change
      await languageProvider.setLanguage('zh');
      expect(languageProvider.locale.languageCode, 'zh');
      expect(languageProvider.isChinese, true);
      expect(languageProvider.isEnglish, false);
    });

    testWidgets('Activity provider should initialize correctly', (
      WidgetTester tester,
    ) async {
      final activityProvider = ActivityProvider();

      // Test initial state
      expect(activityProvider.activities, isEmpty);
      expect(activityProvider.recentRecords, isEmpty);
      expect(activityProvider.isLoading, false);
      expect(activityProvider.isTimerRunning, false);
    });

    testWidgets('Tips provider should initialize correctly', (
      WidgetTester tester,
    ) async {
      final tipsProvider = TipsProvider();

      // Test initial state
      expect(tipsProvider.todayTips, isEmpty);
      expect(tipsProvider.isLoading, false);
    });
  });
}
