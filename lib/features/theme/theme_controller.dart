import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_constants.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(Prefs.themeMode);
    emit(ThemeState(mode: ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system)));
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(ThemeState(mode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.themeMode, mode.name);
  }

  void toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
