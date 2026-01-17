import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:useful_pavlok/presentation/pages/home_screen.dart';
import 'package:useful_pavlok/presentation/theme/theme_data.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'useful_pavlok',
      theme: AppTheme.themeData,
      home: const HomeScreen(),
    );
  }
}

