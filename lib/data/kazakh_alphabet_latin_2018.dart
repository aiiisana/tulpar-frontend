/// Строка справочной таблицы: кириллица → латиница (2018) → МФА.
class KazakhAlphabetRow {
  const KazakhAlphabetRow({
    required this.cyrillic,
    required this.latin,
    required this.ipa,
    this.audioFile,
  });

  final String cyrillic;
  final String latin;
  final String ipa;

  /// Filename (e.g. 'alphabet_aa.mp3') served from the CDN.
  /// Null means no audio available for this letter.
  final String? audioFile;
}

/// Утверждённая латиница 2018 + МФА (по справочным таблицам проекта).
const List<KazakhAlphabetRow> kazakhAlphabetLatin2018Rows = [
  KazakhAlphabetRow(cyrillic: 'Аа',  latin: 'Aa',     ipa: '[ɑ]',          audioFile: 'alphabet_aa.mp3'),
  KazakhAlphabetRow(cyrillic: 'Әә',  latin: 'Áá',     ipa: '[æ]',          audioFile: 'alphabet_ae.mp3'),
  KazakhAlphabetRow(cyrillic: 'Бб',  latin: 'Bb',     ipa: '[b]',          audioFile: 'alphabet_bb.mp3'),
  KazakhAlphabetRow(cyrillic: 'Вв',  latin: 'Vv',     ipa: '[v]',          audioFile: 'alphabet_vv.mp3'),
  KazakhAlphabetRow(cyrillic: 'Гг',  latin: 'Gg',     ipa: '[ɡ]',          audioFile: 'alphabet_gg.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ғғ',  latin: 'Ǵǵ',     ipa: '[ʁ], [ɣ]',    audioFile: 'alphabet_gh.mp3'),
  KazakhAlphabetRow(cyrillic: 'Дд',  latin: 'Dd',     ipa: '[d]',          audioFile: 'alphabet_dd.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ее',  latin: 'Ee',     ipa: '[e], [je]',    audioFile: 'alphabet_ee.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ёё',  latin: '—',      ipa: '[jo], [jø]',   audioFile: 'alphabet_yo.mp3'),
  KazakhAlphabetRow(cyrillic: 'Жж',  latin: 'Jj',     ipa: '[ʒ], [dʒ]',   audioFile: 'alphabet_zh.mp3'),
  KazakhAlphabetRow(cyrillic: 'Зз',  latin: 'Zz',     ipa: '[z]',          audioFile: 'alphabet_zz.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ии',  latin: 'Iı',     ipa: '[ɯj], [ɪj]',  audioFile: 'alphabet_ii.mp3'),
  KazakhAlphabetRow(cyrillic: 'Йй',  latin: 'Iı',     ipa: '[j]',          audioFile: 'alphabet_yy_short.mp3'),
  KazakhAlphabetRow(cyrillic: 'Кк',  latin: 'Kk',     ipa: '[k]',          audioFile: 'alphabet_kk.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ққ',  latin: 'Qq',     ipa: '[q]',          audioFile: 'alphabet_qq.mp3'),
  KazakhAlphabetRow(cyrillic: 'Лл',  latin: 'Ll',     ipa: '[ɫ]',          audioFile: 'alphabet_ll.mp3'),
  KazakhAlphabetRow(cyrillic: 'Мм',  latin: 'Mm',     ipa: '[m]',          audioFile: 'alphabet_mm.mp3'),
  KazakhAlphabetRow(cyrillic: 'Нн',  latin: 'Nn',     ipa: '[n]',          audioFile: 'alphabet_nn.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ңң',  latin: 'Ńń',     ipa: '[ŋ]',          audioFile: 'alphabet_ng.mp3'),
  KazakhAlphabetRow(cyrillic: 'Оо',  latin: 'Oo',     ipa: '[o]',          audioFile: 'alphabet_oo.mp3'),
  KazakhAlphabetRow(cyrillic: 'Өө',  latin: 'Óó',     ipa: '[ø]',          audioFile: 'alphabet_oe.mp3'),
  KazakhAlphabetRow(cyrillic: 'Пп',  latin: 'Pp',     ipa: '[p]',          audioFile: 'alphabet_pp.mp3'),
  KazakhAlphabetRow(cyrillic: 'Рр',  latin: 'Rr',     ipa: '[r]',          audioFile: 'alphabet_rr.mp3'),
  KazakhAlphabetRow(cyrillic: 'Сс',  latin: 'Ss',     ipa: '[s]',          audioFile: 'alphabet_ss.mp3'),
  KazakhAlphabetRow(cyrillic: 'Тт',  latin: 'Tt',     ipa: '[t]',          audioFile: 'alphabet_tt.mp3'),
  KazakhAlphabetRow(cyrillic: 'Уу',  latin: 'Ýý',     ipa: '[w], [ʊw], [ʉw]', audioFile: 'alphabet_uu.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ұұ',  latin: 'Uu',     ipa: '[ʊ]',          audioFile: 'alphabet_uu_long.mp3'),
  KazakhAlphabetRow(cyrillic: 'Үү',  latin: 'Úú',     ipa: '[ʉ]',          audioFile: 'alphabet_ue.mp3'),
  KazakhAlphabetRow(cyrillic: 'Фф',  latin: 'Ff',     ipa: '[f]',          audioFile: 'alphabet_ff.mp3'),
  KazakhAlphabetRow(cyrillic: 'Хх',  latin: 'Hh',     ipa: '[x]',          audioFile: 'alphabet_hh.mp3'),
  KazakhAlphabetRow(cyrillic: 'Һһ',  latin: 'Hh',     ipa: '[h]',          audioFile: 'alphabet_hh_soft.mp3'),
  KazakhAlphabetRow(cyrillic: 'Цц',  latin: '—',      ipa: '[ts]',         audioFile: 'alphabet_ts.mp3'),
  KazakhAlphabetRow(cyrillic: 'Чч',  latin: 'Ch ch',  ipa: '[tʃ]',         audioFile: 'alphabet_ch.mp3'),
  KazakhAlphabetRow(cyrillic: 'Шш',  latin: 'Sh sh',  ipa: '[ʃ], [s]',     audioFile: 'alphabet_sh.mp3'),
  KazakhAlphabetRow(cyrillic: 'Щщ',  latin: '—',      ipa: '[ʃʃ], [ɕɕ]',  audioFile: 'alphabet_sch.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ъъ',  latin: '—',      ipa: '—',            audioFile: 'alphabet_hard_sign.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ыы',  latin: 'Yy',     ipa: '[ɯ]',          audioFile: 'alphabet_y.mp3'),
  KazakhAlphabetRow(cyrillic: 'Іі',  latin: 'Ii',     ipa: '[ɪ]',          audioFile: 'alphabet_i_soft.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ьь',  latin: '—',      ipa: '—',            audioFile: 'alphabet_soft_sign.mp3'),
  KazakhAlphabetRow(cyrillic: 'Ээ',  latin: '—',      ipa: '[e]',          audioFile: 'alphabet_e.mp3'),
  KazakhAlphabetRow(cyrillic: 'Юю',  latin: '—',      ipa: '[juw], [jøw]', audioFile: 'alphabet_yu.mp3'),
  KazakhAlphabetRow(cyrillic: 'Яя',  latin: '—',      ipa: '[jɑ], [jæ]',   audioFile: 'alphabet_ya.mp3'),
];
