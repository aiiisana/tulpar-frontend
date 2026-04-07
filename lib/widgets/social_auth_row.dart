import 'dart:io';
import 'package:flutter/material.dart';
import '../app/theme.dart';

class SocialAuthRow extends StatelessWidget {
  final Future<void> Function() onGoogle;
  final Future<void> Function()? onApple;
  final String title;

  const SocialAuthRow({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final showApple = Platform.isIOS || Platform.isMacOS;

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialPillButton(
              onTap: onGoogle,
              child: Image.asset(
                'assets/icons/google.png',
                width: 22,
                height: 22,
              ),
            ),
            const SizedBox(width: 14),
            _SocialPillButton(
              onTap: showApple ? (onApple ?? () async {}) : null,
              disabled: !showApple,
              child: Image.asset(
                'assets/icons/apple.png',
                width: 22,
                height: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _OrDivider(),
      ],
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  final Future<void> Function()? onTap;
  final Widget child;
  final bool disabled;

  const _SocialPillButton({
    required this.onTap,
    required this.child,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: disabled ? null : () async => await onTap?.call(),
        child: Container(
          width: 92,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.chipFill,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 6),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppTheme.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('или', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppTheme.border, height: 1)),
      ],
    );
  }
}
