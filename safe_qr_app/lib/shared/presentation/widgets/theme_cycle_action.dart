import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme_mode_controller.dart';

class ThemeCycleAction extends StatelessWidget {
  const ThemeCycleAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeController>(
      builder: (BuildContext context, AppThemeModeController t, _) {
        return IconButton(
          tooltip: 'Aparência',
          onPressed: () => t.cycle(),
          icon: switch (t.mode) {
            ThemeMode.system => const Icon(Icons.brightness_auto_rounded),
            ThemeMode.light => const Icon(Icons.dark_mode_outlined),
            ThemeMode.dark => const Icon(Icons.light_mode_outlined),
          },
        );
      },
    );
  }
}
