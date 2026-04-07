import 'package:flutter/material.dart';
import '../app/theme.dart';

class DotsIndicator extends StatelessWidget {
  final int count;
  final int index;

  const DotsIndicator({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          width: active ? 10 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.border,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
