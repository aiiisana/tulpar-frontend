import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/content_assets.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../services/daily_challenge_service.dart';

/// Daily task tab — "4 pictures, 1 word".
///
/// Loads today's challenge from the backend.
/// Falls back to a placeholder UI when no challenge is available.
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  DailyChallengeModel? _challenge;
  bool _loading = true;
  bool _noChallenge = false;

  // Letter-pick state
  List<String> _slots = [];
  late List<String> _pool;

  // Result state
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _noChallenge = false;
      _slots = [];
      _submitted = false;
    });

    final challenge = await DailyChallengeService.getToday();
    if (!mounted) return;

    if (challenge == null) {
      setState(() {
        _loading = false;
        _noChallenge = true;
      });
      return;
    }

    setState(() {
      _challenge = challenge;
      _pool = List.from(challenge.letters);
      _slots = [];
      _submitted = false;
      _loading = false;
    });
  }

  // ── Letter interaction ────────────────────────────────────────────────────────

  void _tapLetter(int index) {
    if (_submitted) return;
    setState(() {
      _slots.add(_pool[index]);
      _pool.removeAt(index);
    });
  }

  void _backspace() {
    if (_slots.isEmpty || _submitted) return;
    setState(() {
      _pool.add(_slots.removeLast());
    });
  }

  void _check() {
    if (_slots.isEmpty) return;
    final answer = _slots.join().toLowerCase();
    final correct = (_challenge?.correctWord ?? '').toLowerCase();
    setState(() {
      _submitted = true;
      _isCorrect = correct.isNotEmpty && answer == correct;
    });
  }

  void _reset() {
    final ch = _challenge;
    if (ch == null) return;
    setState(() {
      _pool = List.from(ch.letters);
      _slots = [];
      _submitted = false;
      _isCorrect = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_noChallenge) {
      return _noTaskState(s);
    }

    return _challengeBody(s);
  }

  // ── No task available state ───────────────────────────────────────────────────

  Widget _noTaskState(AppStr s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.taskOfTheDay,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            s.taskOfTheDayHint,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Icon(Icons.event_busy_outlined,
                color: AppTheme.textSecondary, size: 64),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Задание на сегодня ещё не добавлено',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary),
              child: const Text('Обновить',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main challenge body ───────────────────────────────────────────────────────

  Widget _challengeBody(AppStr s) {
    final ch = _challenge!;
    final targetLen = ch.wordLength > 0 ? ch.wordLength : ch.letters.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.taskOfTheDay,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            s.taskOfTheDayHint,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35),
          ),
          const SizedBox(height: 18),

          // ── Image grid ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E7E2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 4 image cells
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: List.generate(4, (i) {
                    final url = i < ch.imageUrls.length
                        ? ch.imageUrls[i]
                        : null;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: url != null && url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  ContentAssets.dailyTaskCell(i),
                            )
                          : ContentAssets.dailyTaskCell(i),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // ── Answer slots ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(targetLen, (i) {
                    final filled = i < _slots.length;
                    final ch2 = filled ? _slots[i] : '';
                    return Container(
                      width: 36,
                      height: 44,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _submitted
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: _submitted ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        ch2.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // ── Keyboard ───────────────────────────────────────────
                if (!_submitted)
                  LayoutBuilder(
                    builder: (context, c) {
                      const gap = 4.0;
                      final w = c.maxWidth;
                      final count = _pool.length + 1; // +1 for backspace
                      final keySize =
                          ((w - gap * (count - 1)) / count)
                              .clamp(28.0, 40.0);

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < _pool.length; i++)
                            _KeyCircle(
                              size: keySize,
                              onTap: () => _tapLetter(i),
                              child: Text(
                                _pool[i].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ),
                          _KeyCircle(
                            size: keySize,
                            onTap: _backspace,
                            child: const Icon(
                                Icons.backspace_outlined,
                                size: 17),
                          ),
                        ],
                      );
                    },
                  ),

                // ── Result ─────────────────────────────────────────────
                if (_submitted)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isCorrect ? Colors.green : Colors.red),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _isCorrect ? Colors.green : Colors.red,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isCorrect ? 'Дұрыс! 🎉' : 'Дұрыс емес',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _isCorrect
                                  ? Colors.green
                                  : Colors.red),
                        ),
                        if (!_isCorrect &&
                            (_challenge?.correctWord ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Дұрыс жауап: ${_challenge!.correctWord!.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _reset,
                          child: const Text('Қайталау',
                              style:
                                  TextStyle(color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  ),

                // ── Check / reset buttons ──────────────────────────────
                if (!_submitted) ...[
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: (_slots.length == targetLen) ? _check : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Проверить',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  if (_slots.isNotEmpty)
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Сбросить',
                          style: TextStyle(
                              color: AppTheme.textSecondary)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Key circle widget ─────────────────────────────────────────────────────────

class _KeyCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _KeyCircle({
    required this.onTap,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
