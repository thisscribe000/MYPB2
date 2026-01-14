import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyPrayerBankApp());
}

class MyPrayerBankApp extends StatelessWidget {
  const MyPrayerBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Prayer Bank',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
