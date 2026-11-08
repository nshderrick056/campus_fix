import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../logic/theme/theme_cubit.dart';

/// Sun/moon button that flips between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? Symbols.light_mode_rounded : Symbols.dark_mode_rounded),
      onPressed: () => context.read<ThemeCubit>().toggle(Theme.of(context).brightness),
    );
  }
}
