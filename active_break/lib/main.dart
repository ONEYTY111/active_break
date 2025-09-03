import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/tips_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/achievement_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/favorites_screen.dart';
import 'utils/app_localizations.dart';
import 'services/simple_reminder_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");





  // Initialize simple reminder service
  try {
    final simpleReminderService = SimpleReminderService.instance;
    await simpleReminderService.startReminder();
    
    debugPrint('Simple reminder service initialization completed');
  } catch (e) {
    debugPrint('Failed to initialize simple reminder service: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => TipsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'Active Break',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                print(
                  '=== Main Consumer: isLoggedIn = ${userProvider.isLoggedIn} ===',
                );
                if (userProvider.isLoggedIn) {
                  print('=== Main Consumer: Returning MainScreen ===');
                  return MainScreen(
                    key: ValueKey('main_${userProvider.currentUser?.userId}'),
                  );
                } else {
                  print('=== Main Consumer: Returning LoginScreen ===');
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/main': (context) => const MainScreen(),
              '/favorites': (context) => const FavoritesScreen(),
            },
          );
        },
      ),
    );
  }
}
