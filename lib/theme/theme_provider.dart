import 'package:flutter/material.dart';

/// Holds the current theme mode and notifies listeners on change.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({bool isDarkMode = true}) : _isDarkMode = isDarkMode;

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  void toggle() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDark(bool dark) {
    if (_isDarkMode == dark) return;
    _isDarkMode = dark;
    notifyListeners();
  }
}

/// Provides [ThemeNotifier] to the widget tree via [InheritedNotifier].
class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()!
        .notifier!;
  }
}
