import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_mode_controller.dart';

class ThemeCycleAction extends StatelessWidget {
  const ThemeCycleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeController>(
      builder: (BuildContext context, AppThemeModeController t, _) {
        final bool isDark = t.mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? AppStrings.themeLight : AppStrings.themeDark,
          onPressed: t.cycle,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        );
      },
    );
  }
}
