import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_pro_app/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    setUp(() {
      // Set up SharedPreferences mock before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeProvider initial state is dark mode', () {
      final themeProvider = ThemeProvider();

      // Default should be dark mode
      expect(themeProvider.isDarkMode, true);
    });

    test('ThemeProvider toggleTheme switches from dark to light', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': true});
      final themeProvider = ThemeProvider();

      // Initial state is dark
      expect(themeProvider.isDarkMode, true);

      // Toggle to light
      await themeProvider.toggleTheme();

      expect(themeProvider.isDarkMode, false);
    });

    test('ThemeProvider toggleTheme switches from light to dark', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': false});
      final themeProvider = ThemeProvider();
      await themeProvider.setTheme(false); // Set to light mode first

      expect(themeProvider.isDarkMode, false);

      // Toggle to dark
      await themeProvider.toggleTheme();

      expect(themeProvider.isDarkMode, true);
    });

    test('ThemeProvider setTheme sets dark mode correctly', () async {
      final themeProvider = ThemeProvider();

      await themeProvider.setTheme(true);
      expect(themeProvider.isDarkMode, true);

      await themeProvider.setTheme(false);
      expect(themeProvider.isDarkMode, false);
    });

    test('ThemeProvider themeMode returns correct ThemeMode', () async {
      final themeProvider = ThemeProvider();

      await themeProvider.setTheme(true);
      expect(themeProvider.themeMode, ThemeMode.dark);

      await themeProvider.setTheme(false);
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('ThemeProvider notifies listeners on theme change', () async {
      final themeProvider = ThemeProvider();
      int notifyCount = 0;

      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));

      themeProvider.addListener(() {
        notifyCount++;
      });

      await themeProvider.toggleTheme();
      await themeProvider.toggleTheme();

      // Should have been notified twice for two toggles
      expect(notifyCount, 2);
    });

    test('ThemeProvider setTheme notifies listeners', () async {
      final themeProvider = ThemeProvider();
      int notifyCount = 0;

      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));

      themeProvider.addListener(() {
        notifyCount++;
      });

      await themeProvider.setTheme(false);
      await themeProvider.setTheme(true);

      // Should have been notified twice for two setTheme calls
      expect(notifyCount, 2);
    });
  });

  group('AppThemes Tests', () {
    test('AppThemes darkTheme has correct brightness', () {
      expect(AppThemes.darkTheme.brightness, Brightness.dark);
    });

    test('AppThemes lightTheme has correct brightness', () {
      expect(AppThemes.lightTheme.brightness, Brightness.light);
    });

    test('AppThemes darkTheme uses Material 3', () {
      expect(AppThemes.darkTheme.useMaterial3, true);
    });

    test('AppThemes lightTheme uses Material 3', () {
      expect(AppThemes.lightTheme.useMaterial3, true);
    });

    test('AppThemes darkTheme has correct primary color', () {
      expect(AppThemes.darkTheme.primaryColor, const Color(0xFF3B82F6));
    });

    test('AppThemes lightTheme has correct primary color', () {
      expect(AppThemes.lightTheme.primaryColor, const Color(0xFF2563EB));
    });

    test('AppThemes darkTheme has correct scaffold background', () {
      expect(AppThemes.darkTheme.scaffoldBackgroundColor, const Color(0xFF0F172A));
    });

    test('AppThemes lightTheme has correct scaffold background', () {
      expect(AppThemes.lightTheme.scaffoldBackgroundColor, const Color(0xFFF1F5F9));
    });
  });
}
