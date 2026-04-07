import 'package:flutter/material.dart';
import '../app/theme.dart';

class CircleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CircleBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
