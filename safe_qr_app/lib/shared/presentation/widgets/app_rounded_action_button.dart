import 'package:flutter/material.dart';

import '../../../core/theme/app_color_tokens.dart';

class AppRoundedActionButton extends StatelessWidget {
  const AppRoundedActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.leading,
    this.filled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? leading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final b = onPressed;
    if (b == null) {
      return const SizedBox.shrink();
    }
    if (filled) {
      return FilledButton(
        onPressed: b,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _ButtonChild(leading: leading, label: label, color: Theme.of(context).colorScheme.onPrimary),
      );
    }
    return OutlinedButton(
      onPressed: b,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: t.brand.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _ButtonChild(leading: leading, label: label, color: t.brand),
    );
  }
}

final class _ButtonChild extends StatelessWidget {
  const _ButtonChild({required this.leading, required this.label, required this.color});
  final Widget? leading;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (leading == null) {
      return Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        leading!,
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
