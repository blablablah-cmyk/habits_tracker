import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/habits_provider.dart';
import 'screens/home_page.dart';
import 'screens/add_habits_page.dart';
import 'screens/habit_details_page.dart';
import 'screens/settings_page.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(Duration(seconds: 1));
  final notiService = NotificationService();
  await notiService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HabitsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // Set default locale to en_US to prevent weird text issues
            locale: Locale('en', 'US'),
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            title: 'Habits Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => HomePage(),
              '/add-habits': (context) => AddHabitsPage(),
              '/habit-details': (context) => HabitDetailsPage(),
              '/settings': (context) => SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
