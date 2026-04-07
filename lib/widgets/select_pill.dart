import 'package:flutter/material.dart';
import '../app/theme.dart';

class SelectPill extends StatelessWidget {
  final String text;
  final String? leading;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const SelectPill({
    super.key,
    required this.text,
    required this.leading,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.chipFill : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (leading != null) ...[
              Text(leading!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
