import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'data/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'widgets/theme_effects.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MindTunesApp(),
    ),
  );
}

class MindTunesApp extends ConsumerWidget {
  const MindTunesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorProfile = ref.watch(colorProfileProvider);
    final appStyle = ref.watch(appStyleProvider);

    return MaterialApp(
      title: 'Mind Tunes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        profile: colorProfile,
        style: appStyle,
        isDark: false,
      ),
      darkTheme: AppTheme.getTheme(
        profile: colorProfile,
        style: appStyle,
        isDark: true,
      ),
      themeMode: themeMode,
      builder: (context, child) {
        return ThemeEffectsOverlay(
          child: child ?? const SizedBox(),
        );
      },
      home: const HomeScreen(),
    );
  }
}