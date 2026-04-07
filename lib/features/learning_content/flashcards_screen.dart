import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/theme.dart';
import '../../data/flashcard_deck.dart';
import '../../models/flashcard_item.dart';
import '../../models/saved_flashcard.dart';
import '../../services/flashcard_service.dart';
import '../../widgets/circle_back_button.dart';
import 'saved_words_screen.dart';

/// Converts a [FlashcardModel] from the backend to the local [FlashcardItem]
/// so the UI layer stays unchanged.
FlashcardItem _modelToItem(FlashcardModel m) => FlashcardItem(
      id: m.id,
      kazakh: m.wordKz,
      pronunciation: m.transcription ?? '',
      russian: m.wordRu,
    );

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final PageController _pageController = PageController();

  List<FlashcardItem> _deck = [];
  bool _loading = true;

  int _index = 0;
  bool _showTranslation = false;
  bool _starFilled = false;
  bool _starBusy = false;

  FlashcardItem get _current => _deck[_index];

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadDeck() async {
    final models = await FlashcardService.getAll(size: 100);
    if (!mounted) return;

    // Use backend data; fall back to the bundled deck when the server returns nothing.
    final items = models.isNotEmpty
        ? models.map(_modelToItem).toList()
        : kFlashcardDeck;

    setState(() {
      _deck = items;
      _loading = false;
    });
    if (items.isNotEmpty) _syncStar();
  }

  // ── Star (save word) ─────────────────────────────────────────────────────────

  Future<void> _syncStar() async {
    if (_deck.isEmpty) return;
    final saved = await AppStorage.isFlashcardSaved(_current.id);
    if (!mounted) return;
    setState(() => _starFilled = saved);
  }

  void _onPageChanged(int i) {
    setState(() {
      _index = i;
      _showTranslation = false;
    });
    _syncStar();
  }

  Future<void> _toggleStar() async {
    if (_starBusy) return;
    setState(() => _starBusy = true);
    try {
      if (_starFilled) {
        await AppStorage.removeSavedFlashcard(_current.id);
        if (!mounted) return;
        setState(() => _starFilled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Убрано из сохранённых')),
        );
      } else {
        await AppStorage.saveFlashcard(SavedFlashcard.fromFlashcard(_current));
        if (!mounted) return;
        setState(() => _starFilled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
      }
    } finally {
      if (mounted) setState(() => _starBusy = false);
    }
  }

  Future<void> _openSaved() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SavedWordsScreen()),
    );
    if (mounted) await _syncStar();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  static const _pageAnim = Duration(milliseconds: 280);
  static const _pageCurve = Curves.easeOutCubic;

  void _goPrev() {
    if (_index <= 0) return;
    _pageController.previousPage(duration: _pageAnim, curve: _pageCurve);
  }

  void _goNext() {
    if (_index >= _deck.length - 1) return;
    _pageController.nextPage(duration: _pageAnim, curve: _pageCurve);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_deck.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [CircleBackButton()]),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Карточки пока не добавлены',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      'Карточки ${_index + 1}/${_deck.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _deck.length,
                  (i) => Container(
                    width: i == _index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:
                          i == _index ? AppTheme.primary : AppTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _DeckNavArrow(
                        icon: Icons.chevron_left_rounded,
                        enabled: _index > 0,
                        onTap: _goPrev,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _deck.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, pageIndex) {
                          final item = _deck[pageIndex];
                          final isCurrent = pageIndex == _index;
                          final showBack = isCurrent && _showTranslation;
                          return Center(
                            child: GestureDetector(
                              onTap: isCurrent
                                  ? () => setState(
                                      () => _showTranslation = !showBack)
                                  : null,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: showBack
                                    ? _cardBack(item, pageIndex == _index)
                                    : _cardFront(item, pageIndex == _index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Center(
                      child: _DeckNavArrow(
                        icon: Icons.chevron_right_rounded,
                        enabled: _index < _deck.length - 1,
                        onTap: _goNext,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _openSaved,
                icon: const Icon(Icons.star_outline,
                    color: AppTheme.textPrimary, size: 20),
                label: const Text('Сохраненные слова'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardFront(FlashcardItem item, bool interactive) {
    return Container(
      key: ValueKey<String>('f-${item.id}'),
      alignment: Alignment.center,
      child: _FlashCard(
        starFilled: interactive ? _starFilled : false,
        onStar: interactive ? _toggleStar : null,
        starBusy: interactive && _starBusy,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.kazakh,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (item.pronunciation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '[${item.pronunciation}]',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardBack(FlashcardItem item, bool interactive) {
    return Container(
      key: ValueKey<String>('b-${item.id}'),
      alignment: Alignment.center,
      child: _FlashCard(
        starFilled: interactive ? _starFilled : false,
        onStar: interactive ? _toggleStar : null,
        starBusy: interactive && _starBusy,
        child: Text(
          item.russian,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final Widget child;
  final bool starFilled;
  final VoidCallback? onStar;
  final bool starBusy;

  const _FlashCard({
    required this.child,
    required this.starFilled,
    required this.onStar,
    required this.starBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
          maxWidth: 268, minHeight: 138, maxHeight: 220),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: child),
          Positioned(
            right: 6,
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundIcon(
                    icon: Icons.volume_up_outlined, onPressed: () {}),
                const SizedBox(width: 6),
                _RoundIcon(
                  icon: starFilled
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  onPressed:
                      (onStar != null && !starBusy) ? onStar : null,
                  iconColor:
                      starFilled ? Colors.amber.shade800 : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckNavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DeckNavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppTheme.primary
          : AppTheme.primary.withOpacity(0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const _RoundIcon({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.textPrimary;
    return Material(
      color: const Color(0xFFF0EFEA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 20,
              color: onPressed == null
                  ? color.withOpacity(0.45)
                  : color),
        ),
      ),
    );
  }
}
