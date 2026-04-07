import 'package:flutter/material.dart';
import '../app/theme.dart';

class ProgressHeader extends StatelessWidget {
  final int progressIndex; // 1..N
  final int progressTotal;
  final VoidCallback onBack;

  const ProgressHeader({
    super.key,
    required this.progressIndex,
    required this.progressTotal,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: List.generate(progressTotal, (i) {
              final filled = (i + 1) <= progressIndex;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i == progressTotal - 1 ? 0 : 10),
                  decoration: BoxDecoration(
                    color: filled ? AppTheme.primary : AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
