import 'package:flutter/material.dart';

import '../../../core/theme/app_color_tokens.dart';

class AppBusyOverlay extends StatelessWidget {
  const AppBusyOverlay({super.key, required this.show, this.message});

  final bool show;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4)),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.safeColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  if (message != null) ...<Widget>[
                    const SizedBox(width: 12),
                    Text(message!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
