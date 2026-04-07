import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/flashcard_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late Future<List<FlashcardModel>> _flashcardsFuture;
  List<FlashcardModel> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  void _loadFlashcards() {
    _flashcardsFuture = FlashcardService.getAll().then((flashcards) {
      setState(() {
        _flashcards = flashcards;
        _currentIndex = 0;
        _isFlipped = false;
      });
      return flashcards;
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    }
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточки'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.background,
      body: FutureBuilder<List<FlashcardModel>>(
        future: _flashcardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || _flashcards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Карточки недоступны',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _loadFlashcards();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final card = _flashcards[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleFlip,
                  child: Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isFlipped) ...[
                          Text(
                            card.wordRu,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нажмите чтобы перевернуть',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            card.wordKz,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (card.transcription != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '[${card.transcription}]',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          if (card.exampleSentence != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                card.exampleSentence!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Карточка ${_currentIndex + 1} из ${_flashcards.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: _currentIndex > 0 ? _goToPrevious : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _currentIndex > 0
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        '← Назад',
                        style: TextStyle(
                          color: _currentIndex > 0
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _currentIndex < _flashcards.length - 1
                          ? _goToNext
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _currentIndex < _flashcards.length - 1
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        'Вперёд →',
                        style: TextStyle(
                          color: _currentIndex < _flashcards.length - 1
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
