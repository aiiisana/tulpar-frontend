class AppStr {
  AppStr._(this.lang);

  final String lang;
  bool get en => lang == 'en';

  factory AppStr.fromContext(String lang) => AppStr._(lang);

  String get dailyPractice => en ? 'Daily practice' : 'Ежедневная практика';
  String get startLesson => en ? 'Start lesson' : 'Начать урок';

  String streakLine(int n) {
    if (en) {
      if (n <= 0) return "You've been learning for: 0 days";
      if (n == 1) return "You've been learning for: 1 day";
      return "You've been learning for: $n days";
    }
    if (n <= 0) return 'Вы занимаетесь уже: 0 дней';
    final m100 = n % 100;
    final m10 = n % 10;
    if (m100 >= 11 && m100 <= 19) return 'Вы занимаетесь уже: $n дней';
    if (m10 == 1) return 'Вы занимаетесь уже: $n день';
    if (m10 >= 2 && m10 <= 4) return 'Вы занимаетесь уже: $n дня';
    return 'Вы занимаетесь уже: $n дней';
  }

  List<String> get weekDayLabels => en
      ? const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
      : const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  String get tabHome => en ? 'Home' : 'Дом';
  String get tabLearn => en ? 'Learn' : 'Обучение';
  String get tabTask => en ? 'Task' : 'Задание';
  String get tabProfile => en ? 'Profile' : 'Профиль';

  String get profileTitle => en ? 'Profile' : 'Профиль';
  String get userPlaceholder => en ? 'User' : 'Пользователь';
  String get beginner => en ? 'Beginner' : 'Начинающий';
  String get edit => en ? 'Edit' : 'Редактировать';
  String get progress => en ? 'Progress' : 'Прогресс';
  String get achievements => en ? 'Achievements' : 'Достижения';
  String get firstLessonAchievement => en ? 'Complete your first lesson' : 'Пройди первый урок';

  String streakShort(int n) {
    if (en) {
      if (n <= 0) return '0-day streak';
      if (n == 1) return '1-day streak';
      return '$n-day streak';
    }
    if (n <= 0) return '0 дней подряд';
    final m100 = n % 100;
    final m10 = n % 10;
    if (m100 >= 11 && m100 <= 19) return '$n дней подряд';
    if (m10 == 1) return '$n день подряд';
    if (m10 >= 2 && m10 <= 4) return '$n дня подряд';
    return '$n дней подряд';
  }

  String lessonsDoneLine(int n) {
    if (en) {
      if (n <= 0) return '0 lessons completed';
      if (n == 1) return '1 lesson completed';
      return '$n lessons completed';
    }
    if (n <= 0) return '0 уроков пройдено';
    final m100 = n % 100;
    final m10 = n % 10;
    if (m100 >= 11 && m100 <= 19) return '$n уроков пройдено';
    if (m10 == 1) return '$n урок пройден';
    if (m10 >= 2 && m10 <= 4) return '$n урока пройдено';
    return '$n уроков пройдено';
  }

  String studyTimeLine(int h, int m) =>
      en ? '$h h $m min of study' : '$h ч $m мин занятий';

  String get dailyGoal => en ? 'Daily goal' : 'Ежедневная цель';
  String minutesValue(int m) => en ? '$m min' : '$m минут';
  String get appLanguage => en ? 'App language' : 'Язык приложения';
  String get russian => en ? 'Russian' : 'Русский';
  String get english => 'English';

  String get editNameTitle => en ? 'Edit name' : 'Редактировать имя';
  String get firstName => en ? 'First name' : 'Имя';
  String get lastName => en ? 'Last name' : 'Фамилия';
  String get cancel => en ? 'Cancel' : 'Отмена';
  String get save => en ? 'Save' : 'Сохранить';

  String get pickDailyGoalTitle => en ? 'Daily goal' : 'Ежедневная цель';
  String get pickDailyGoalSubtitle => en ? 'Choose minutes per day' : 'Выберите время в день';

  String get langSheetTitle => en ? 'App language' : 'Язык приложения';
  String get langSheetSubtitle => en ? 'Interface language' : 'Язык интерфейса';

  String get learningTitle => en ? 'Learn' : 'Обучение';
  String get learnFlashcards => en ? 'Flashcards' : 'Карточки';
  String get learnClubs => en ? 'Speaking clubs' : 'Разговорные клубы';
  String get learnArticles => en ? 'Articles' : 'Статьи';
  String get learnAi => en ? 'AI assistant' : 'ИИ помощник';
  String get learnGrammar => en ? 'Grammar' : 'Грамматика';
  String get learnSample => en ? 'Alphabet' : 'Алфавит';

  String get taskOfTheDay => en ? 'Task of the day' : 'Задание дня';
  String get taskOfTheDayHint =>
      en ? 'The pictures are a hint — build the word from the letters' : 'Картинки подскажут — собери слово из предложенных букв';

  String get settings => en ? 'Settings' : 'Настройки';
  String get logout => en ? 'Log out' : 'Выйти';
  String get account => en ? 'Account' : 'Аккаунт';
  String get notifications => en ? 'Notifications' : 'Уведомления';
  String get privacySecurity => en ? 'Privacy & security' : 'Конфиденциальность и\nбезопасность';
  String get privacySecurityOneLine => en ? 'Privacy & security' : 'Конфиденциальность и безопасность';
  String get helpSupport => en ? 'Help & support' : 'Помощь и поддержка';
  String get terms => en ? 'Terms of use' : 'Условия использования';

  String get accountTitle => en ? 'Account' : 'Аккаунт';
  String get email => en ? 'Email' : 'Электронная почта';
  String get password => en ? 'Password' : 'Пароль';
  String get changePassword => en ? 'Change password' : 'Сменить пароль';
  String get editProfile => en ? 'Edit profile' : 'Редактировать профиль';
  String get accountEditHint =>
      en ? 'Name and photo can be changed from the Profile tab.' : 'Имя и отображение можно изменить во вкладке «Профиль».';
  String get soon => en ? 'Coming soon' : 'Скоро';
  String get passwordChangeSoon =>
      en ? 'Password change will be available in a future update.' : 'Смена пароля появится в следующих версиях.';

  String get notifTitle => en ? 'Notifications' : 'Уведомления';
  String get notifLessonReminders => en ? 'Lesson reminders' : 'Напоминания об уроках';
  String get notifLessonRemindersSub =>
      en ? 'Remind me to practice if I skip a day' : 'Напомнить о занятии, если пропустил день';
  String get notifStreak => en ? 'Streak alerts' : 'Серия занятий';
  String get notifStreakSub => en ? 'Notify me before my streak breaks' : 'Уведомить, когда серия может оборваться';
  String get notifSounds => en ? 'Sounds' : 'Звуки';
  String get notifSoundsSub => en ? 'Play sounds for answers and streaks' : 'Звуки ответов и достижений';

  String get pinCode => en ? 'Change PIN' : 'Сменить PIN-код';
  String get analytics => en ? 'Usage analytics' : 'Аналитика использования';
  String get analyticsSub =>
      en ? 'Help improve the app with anonymous statistics' : 'Помочь улучшить приложение анонимной статистикой';
  String get downloadData => en ? 'Download my data' : 'Скачать мои данные';
  String get downloadDataSub => en ? 'Export a copy of your profile and progress' : 'Экспорт копии профиля и прогресса';

  String get helpTitle => en ? 'Help & support' : 'Помощь и поддержка';
  String get faq => en ? 'FAQ' : 'Частые вопросы';
  String get faqAnswer => en
      ? 'Lessons unlock in order. Streak counts days you opened the app. Kazakh content is always in Kazakh.'
      : 'Уроки открываются по порядку. Серия считает дни, когда вы заходили в приложение. Казахский контент всегда на казахском.';
  String get contact => en ? 'Contact us' : 'Связаться с нами';
  String get contactEmail => 'support@tulpar.app';
  String get reportBug => en ? 'Report a bug' : 'Сообщить об ошибке';

  String get termsTitle => en ? 'Terms of use' : 'Условия использования';
  String get userAgreement => en ? 'User agreement' : 'Пользовательское соглашение';
  String get privacyPolicy => en ? 'Privacy policy' : 'Политика конфиденциальности';
  String termsBody(bool enUi) => enUi
      ? 'By using Tulpar you agree to learn responsibly and keep your account secure. We process your data to provide lessons and sync progress. Kazakh learning content is shown in Kazakh regardless of interface language.'
      : 'Используя Tulpar, вы соглашаетесь учиться добросовестно и беречь аккаунт. Мы обрабатываем данные для уроков и синхронизации прогресса. Учебный казахский контент отображается на казахском независимо от языка интерфейса.';

  String get enterCurrentPin => en ? 'Enter current PIN' : 'Введите текущий PIN';
  String get wrongPin => en ? 'Wrong PIN' : 'Неверный PIN-код';
  String get next => en ? 'Next' : 'Далее';
  String get repeatNewPin => en ? 'Repeat new PIN' : 'Повторите новый PIN';
  String get enterNewPin => en ? 'Enter new PIN' : 'Введите новый PIN';
  String get pinMismatch => en ? 'PINs do not match' : 'PIN-коды не совпадают';
  String get saveButton => en ? 'Save' : 'Сохранить';
}
