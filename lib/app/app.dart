import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_gate.dart';
import 'app_storage.dart';
import 'ui_locale.dart';

class TulparApp extends StatefulWidget {
  const TulparApp({super.key});

  @override
  State<TulparApp> createState() => _TulparAppState();
}

class _TulparAppState extends State<TulparApp> {
  final ValueNotifier<String> _locale = ValueNotifier<String>('ru');

  @override
  void initState() {
    super.initState();
    AppStorage.getUiLang().then((l) {
      if (mounted) _locale.value = l;
    });
  }

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _locale,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Tulpar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) {
            return UiLocaleScope(
              locale: lang,
              applyLocale: (newLocale) async {
                await AppStorage.setUiLang(newLocale);
                _locale.value = newLocale;
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppGate(),
        );
      },
    );
  }
}
