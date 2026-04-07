import 'package:flutter/material.dart';

class ContentAssets {
  ContentAssets._();

  static const String profileAvatar = 'assets/images/face2.png';

  static const List<String> dailyTaskGridImages = [
    'assets/images/dailygoal1.png',
    'assets/images/dailygoal2.png',
    'assets/images/dailygoal3.png',
    'assets/images/dailygoal4.png',
  ];

  static Widget profileAvatarWidget({double size = 72}) {
    return ClipOval(
      child: Image.asset(
        profileAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade600),
      ),
    );
  }

  static Widget dailyTaskCell(int index, {BorderRadius? radius}) {
    final path = index >= 0 && index < dailyTaskGridImages.length ? dailyTaskGridImages[index] : null;
    final r = radius ?? BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: r,
      child: SizedBox.expand(
        child: path != null
            ? Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  static Widget _placeholder() {
    return ColoredBox(
      color: const Color(0xFFDEDAD4),
      child: Icon(Icons.edit_note_rounded, size: 42, color: Colors.grey.shade600),
    );
  }
}
