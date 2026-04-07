import 'package:flutter/material.dart';

class UiLocaleScope extends InheritedWidget {
  final String locale;
  final Future<void> Function(String newLocale) applyLocale;

  const UiLocaleScope({
    super.key,
    required this.locale,
    required this.applyLocale,
    required super.child,
  });

  static UiLocaleScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<UiLocaleScope>();
    assert(s != null, 'UiLocaleScope not found');
    return s!;
  }

  static String langOf(BuildContext context) => of(context).locale;

  @override
  bool updateShouldNotify(UiLocaleScope oldWidget) => locale != oldWidget.locale;
}
