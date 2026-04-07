import 'package:flutter/material.dart';
import '../../app/app_storage.dart';
import '../../app/theme.dart';
import '../../widgets/circle_back_button.dart';

class SavedWordsScreen extends StatefulWidget {
  const SavedWordsScreen({super.key});

  @override
  State<SavedWordsScreen> createState() => _SavedWordsScreenState();
}

class _SavedWordsScreenState extends State<SavedWordsScreen> {
  late Future<List<_SavedRow>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<_SavedRow>> _fetch() async {
    final list = await AppStorage.getSavedWords();
    list.sort((a, b) => b.savedAtMs.compareTo(a.savedAtMs));
    return list
        .map(
          (w) => _SavedRow(
            id: w.id,
            kazakh: w.kazakh,
            pronunciation: w.pronunciation,
            russian: w.russian,
          ),
        )
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _load = _fetch());
  }

  Future<void> _remove(String id) async {
    await AppStorage.removeSavedFlashcard(id);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Удалено из сохранённых')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Expanded(
                    child: Text(
                      'Сохраненные слова',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_SavedRow>>(
                future: _load,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  final rows = snap.data ?? [];
                  if (rows.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Пока нет сохранённых слов.\nОткройте карточки и нажмите звёздочку на карточке.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade700),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return Dismissible(
                        key: ValueKey(r.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                        ),
                        onDismissed: (_) => _remove(r.id),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.kazakh,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              if (r.pronunciation.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  r.pronunciation,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                r.russian,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRow {
  final String id;
  final String kazakh;
  final String pronunciation;
  final String russian;

  _SavedRow({
    required this.id,
    required this.kazakh,
    required this.pronunciation,
    required this.russian,
  });
}
