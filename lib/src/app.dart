import 'package:flutter/material.dart';

import 'brand.dart';

/// The app's frame. Light and dark follow the computer's setting.
class SlopeCalculatorApp extends StatelessWidget {
  const SlopeCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const StartScreen(),
    );
  }

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.navyLight,
      brightness: brightness,
      secondary: BrandColors.gold,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}

/// A placeholder start screen until the calculator screens arrive (phase 3).
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/icon-512.png', width: 112, height: 112, semanticLabel: '$appName logo'),
              const SizedBox(height: 20),
              Text(appName, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(appTagline, style: text.titleMedium),
              const SizedBox(height: 18),
              Text('Version $appVersion · $appPublisher', style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
