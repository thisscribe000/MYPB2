import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyPrayerBankApp());
}

class MyPrayerBankApp extends StatelessWidget {
  const MyPrayerBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Prayer Bank',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
