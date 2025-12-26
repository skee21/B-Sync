import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

const String _themeModeKey = 'theme_mode';
const String _colorProfileKey = 'color_profile';
const String _appStyleKey = 'app_style';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final colorProfileProvider = StateNotifierProvider<ColorProfileNotifier, ColorProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ColorProfileNotifier(prefs);
});

final appStyleProvider = StateNotifierProvider<AppStyleNotifier, AppStyle>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppStyleNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final index = prefs.getInt(_themeModeKey);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setInt(_themeModeKey, mode.index);
  }

  void toggleTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

class ColorProfileNotifier extends StateNotifier<ColorProfile> {
  final SharedPreferences _prefs;

  ColorProfileNotifier(this._prefs) : super(_loadColorProfile(_prefs));

  static ColorProfile _loadColorProfile(SharedPreferences prefs) {
    final index = prefs.getInt(_colorProfileKey);
    if (index == null) return ColorProfile.defaultColor;
    return ColorProfile.values[index.clamp(0, ColorProfile.values.length - 1)];
  }

  void setColorProfile(ColorProfile profile) {
    state = profile;
    _prefs.setInt(_colorProfileKey, profile.index);
  }
}

class AppStyleNotifier extends StateNotifier<AppStyle> {
  final SharedPreferences _prefs;

  AppStyleNotifier(this._prefs) : super(_loadAppStyle(_prefs));

  static AppStyle _loadAppStyle(SharedPreferences prefs) {
    final index = prefs.getInt(_appStyleKey);
    if (index == null) return AppStyle.normal;
    return AppStyle.values[index.clamp(0, AppStyle.values.length - 1)];
  }

  void setAppStyle(AppStyle style) {
    state = style;
    _prefs.setInt(_appStyleKey, style.index);
  }
}

const String _themeEffectsKey = 'theme_effects_enabled';

final themeEffectsEnabledProvider = StateNotifierProvider<ThemeEffectsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeEffectsNotifier(prefs);
});

class ThemeEffectsNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  ThemeEffectsNotifier(this._prefs) : super(_prefs.getBool(_themeEffectsKey) ?? true);

  void toggle() {
    state = !state;
    _prefs.setBool(_themeEffectsKey, state);
  }

  void setEnabled(bool enabled) {
    state = enabled;
    _prefs.setBool(_themeEffectsKey, enabled);
  }
}

enum ViewMode { list, grid }

const String _viewModeKey = 'view_mode';

final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ViewModeNotifier(prefs);
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  final SharedPreferences _prefs;

  ViewModeNotifier(this._prefs) : super(_loadViewMode(_prefs));

  static ViewMode _loadViewMode(SharedPreferences prefs) {
    final index = prefs.getInt(_viewModeKey);
    if (index == null) return ViewMode.list;
    return ViewMode.values[index.clamp(0, ViewMode.values.length - 1)];
  }

  void setViewMode(ViewMode mode) {
    state = mode;
    _prefs.setInt(_viewModeKey, mode.index);
  }

  void toggle() {
    final newMode = state == ViewMode.list ? ViewMode.grid : ViewMode.list;
    setViewMode(newMode);
  }
}
