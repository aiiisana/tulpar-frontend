/// Строка справочной таблицы: кириллица → латиница (2018) → МФА.
class KazakhAlphabetRow {
  const KazakhAlphabetRow({
    required this.cyrillic,
    required this.latin,
    required this.ipa,
  });

  final String cyrillic;
  final String latin;
  final String ipa;
}

/// Утверждённая латиница 2018 + МФА (по справочным таблицам проекта).
const List<KazakhAlphabetRow> kazakhAlphabetLatin2018Rows = [
  KazakhAlphabetRow(cyrillic: 'Аа', latin: 'Aa', ipa: '[ɑ]'),
  KazakhAlphabetRow(cyrillic: 'Әә', latin: 'Áá', ipa: '[æ]'),
  KazakhAlphabetRow(cyrillic: 'Бб', latin: 'Bb', ipa: '[b]'),
  KazakhAlphabetRow(cyrillic: 'Вв', latin: 'Vv', ipa: '[v]'),
  KazakhAlphabetRow(cyrillic: 'Гг', latin: 'Gg', ipa: '[ɡ]'),
  KazakhAlphabetRow(cyrillic: 'Ғғ', latin: 'Ǵǵ', ipa: '[ʁ], [ɣ]'),
  KazakhAlphabetRow(cyrillic: 'Дд', latin: 'Dd', ipa: '[d]'),
  KazakhAlphabetRow(cyrillic: 'Ее', latin: 'Ee', ipa: '[e], [je]'),
  KazakhAlphabetRow(cyrillic: 'Ёё', latin: '—', ipa: '[jo], [jø]'),
  KazakhAlphabetRow(cyrillic: 'Жж', latin: 'Jj', ipa: '[ʒ], [dʒ]'),
  KazakhAlphabetRow(cyrillic: 'Зз', latin: 'Zz', ipa: '[z]'),
  KazakhAlphabetRow(cyrillic: 'Ии', latin: 'Iı', ipa: '[ɯj], [ɪj]'),
  KazakhAlphabetRow(cyrillic: 'Йй', latin: 'Iı', ipa: '[j]'),
  KazakhAlphabetRow(cyrillic: 'Кк', latin: 'Kk', ipa: '[k]'),
  KazakhAlphabetRow(cyrillic: 'Ққ', latin: 'Qq', ipa: '[q]'),
  KazakhAlphabetRow(cyrillic: 'Лл', latin: 'Ll', ipa: '[ɫ]'),
  KazakhAlphabetRow(cyrillic: 'Мм', latin: 'Mm', ipa: '[m]'),
  KazakhAlphabetRow(cyrillic: 'Нн', latin: 'Nn', ipa: '[n]'),
  KazakhAlphabetRow(cyrillic: 'Ңң', latin: 'Ńń', ipa: '[ŋ]'),
  KazakhAlphabetRow(cyrillic: 'Оо', latin: 'Oo', ipa: '[o]'),
  KazakhAlphabetRow(cyrillic: 'Өө', latin: 'Óó', ipa: '[ø]'),
  KazakhAlphabetRow(cyrillic: 'Пп', latin: 'Pp', ipa: '[p]'),
  KazakhAlphabetRow(cyrillic: 'Рр', latin: 'Rr', ipa: '[r]'),
  KazakhAlphabetRow(cyrillic: 'Сс', latin: 'Ss', ipa: '[s]'),
  KazakhAlphabetRow(cyrillic: 'Тт', latin: 'Tt', ipa: '[t]'),
  KazakhAlphabetRow(cyrillic: 'Уу', latin: 'Ýý', ipa: '[w], [ʊw], [ʉw]'),
  KazakhAlphabetRow(cyrillic: 'Ұұ', latin: 'Uu', ipa: '[ʊ]'),
  KazakhAlphabetRow(cyrillic: 'Үү', latin: 'Úú', ipa: '[ʉ]'),
  KazakhAlphabetRow(cyrillic: 'Фф', latin: 'Ff', ipa: '[f]'),
  KazakhAlphabetRow(cyrillic: 'Хх', latin: 'Hh', ipa: '[x]'),
  KazakhAlphabetRow(cyrillic: 'Һһ', latin: 'Hh', ipa: '[h]'),
  KazakhAlphabetRow(cyrillic: 'Цц', latin: '—', ipa: '[ts]'),
  KazakhAlphabetRow(cyrillic: 'Чч', latin: 'Ch ch', ipa: '[tʃ]'),
  KazakhAlphabetRow(cyrillic: 'Шш', latin: 'Sh sh', ipa: '[ʃ], [s]'),
  KazakhAlphabetRow(cyrillic: 'Щщ', latin: '—', ipa: '[ʃʃ], [ɕɕ]'),
  KazakhAlphabetRow(cyrillic: 'Ъъ', latin: '—', ipa: '—'),
  KazakhAlphabetRow(cyrillic: 'Ыы', latin: 'Yy', ipa: '[ɯ]'),
  KazakhAlphabetRow(cyrillic: 'Іі', latin: 'Ii', ipa: '[ɪ]'),
  KazakhAlphabetRow(cyrillic: 'Ьь', latin: '—', ipa: '—'),
  KazakhAlphabetRow(cyrillic: 'Ээ', latin: '—', ipa: '[e]'),
  KazakhAlphabetRow(cyrillic: 'Юю', latin: '—', ipa: '[juw], [jøw]'),
  KazakhAlphabetRow(cyrillic: 'Яя', latin: '—', ipa: '[jɑ], [jæ]'),
];
