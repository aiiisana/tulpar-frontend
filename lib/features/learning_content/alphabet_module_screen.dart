import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/kazakh_alphabet_latin_2018.dart';
import '../../widgets/circle_back_button.dart';

/// Справочник: казахский алфавит (кириллица → латиница 2018 → МФА).
class AlphabetModuleScreen extends StatelessWidget {
  const AlphabetModuleScreen({super.key});

  static const String _intro =
      'С 2018 года в Казахстане утверждена казахская латинская графика: каждой '
      'кириллической букве соответствуют определённые латинские знаки, а в скобках '
      'дана ориентировочная транскрипция по МФА. Ниже — полная опорная таблица.';

  static const String _officialHeading = 'Латиница в Казахстане';

  static const String _officialBody =
      'Согласно принятому указу президента Республики Казахстан Нурсултана '
      'Абишевича Назарбаева алфавит казахского языка теперь будет базироваться на '
      'латинской графике (латиница). Данные изменения были внесены в Указ '
      'Президента РК более двух лет назад - 19 февраля 2018 года. Вызваны они '
      'необходимостью следования современным тенденциям.';

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
                      'Алфавит',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  Text(
                    _intro,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AlphabetTable(rows: kazakhAlphabetLatin2018Rows),
                  const SizedBox(height: 28),
                  Text(
                    _officialHeading,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _officialBody,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alphabet table ────────────────────────────────────────────────────────────

class _AlphabetTable extends StatefulWidget {
  const _AlphabetTable({required this.rows});

  final List<KazakhAlphabetRow> rows;

  @override
  State<_AlphabetTable> createState() => _AlphabetTableState();
}

class _AlphabetTableState extends State<_AlphabetTable> {
  static const _baseUrl =
      'https://pub-cfcd1f8d9d334d638e5c522acf05a60b.r2.dev/assets/audio/learning/';

  final AudioPlayer _player = AudioPlayer();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRow(int index) async {
    final audioFile = widget.rows[index].audioFile;
    if (audioFile == null) return;

    if (_playingIndex == index) {
      await _player.stop();
      if (mounted) setState(() => _playingIndex = null);
      return;
    }

    setState(() => _playingIndex = index);
    try {
      await _player.stop();
      await _player.play(UrlSource('$_baseUrl$audioFile'));
    } catch (_) {
      if (mounted) setState(() => _playingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.05),
          1: FlexColumnWidth(1.15),
          2: FlexColumnWidth(1.35),
          3: FixedColumnWidth(42),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: AppTheme.border.withOpacity(0.85)),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.18),
            ),
            children: const [
              _HeaderCell('Кириллица'),
              _HeaderCell('Латиница 2018'),
              _HeaderCell('МФА'),
              _HeaderCell(''),
            ],
          ),
          for (var i = 0; i < widget.rows.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.white
                    : AppTheme.chipFill.withOpacity(0.35),
              ),
              children: [
                _BodyCell(widget.rows[i].cyrillic, weight: FontWeight.w700),
                _BodyCell(widget.rows[i].latin),
                _BodyCell(widget.rows[i].ipa, small: true),
                _AudioCell(
                  hasAudio: widget.rows[i].audioFile != null,
                  isPlaying: _playingIndex == i,
                  onTap: () => _toggleRow(i),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Audio button cell ─────────────────────────────────────────────────────────

class _AudioCell extends StatelessWidget {
  const _AudioCell({
    required this.hasAudio,
    required this.isPlaying,
    required this.onTap,
  });

  final bool hasAudio;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasAudio) return const SizedBox();
    return TableRowInkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Icon(
            isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
            size: 20,
            color: isPlaying ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Table cells ───────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {this.weight = FontWeight.w500, this.small = false});

  final String text;
  final FontWeight weight;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 12.5 : 14,
          fontWeight: weight,
          color: AppTheme.textPrimary,
          height: 1.25,
        ),
      ),
    );
  }
}
