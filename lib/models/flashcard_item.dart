class FlashcardItem {
  final String id;
  final String kazakh;
  final String pronunciation;
  final String russian;
  final String? audioUrl;

  const FlashcardItem({
    required this.id,
    required this.kazakh,
    required this.pronunciation,
    required this.russian,
    required this.audioUrl
  });
}
