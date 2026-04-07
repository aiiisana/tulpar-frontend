import 'package:flutter/foundation.dart';

import 'flashcard_item.dart';

@immutable
class SavedFlashcard {
  final String id;
  final String kazakh;
  final String pronunciation;
  final String russian;
  final int savedAtMs;

  const SavedFlashcard({
    required this.id,
    required this.kazakh,
    required this.pronunciation,
    required this.russian,
    required this.savedAtMs,
  });

  factory SavedFlashcard.fromFlashcard(FlashcardItem item) {
    return SavedFlashcard(
      id: item.id,
      kazakh: item.kazakh,
      pronunciation: item.pronunciation,
      russian: item.russian,
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kk': kazakh,
        'pron': pronunciation,
        'ru': russian,
        'at': savedAtMs,
      };

  factory SavedFlashcard.fromJson(Map<String, dynamic> j) {
    return SavedFlashcard(
      id: j['id'] as String,
      kazakh: j['kk'] as String,
      pronunciation: j['pron'] as String? ?? '',
      russian: j['ru'] as String,
      savedAtMs: j['at'] as int? ?? 0,
    );
  }
}
