import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Light / dark / follow-system, chosen from the Profile screen.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void set(ThemeMode mode) => emit(mode);
}
