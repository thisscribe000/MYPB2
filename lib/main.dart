import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/app_shell.dart';
import 'services/prayer_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hive init
  await Hive.initFlutter();

  // ✅ Global prayer session
  final session = PrayerSessionController();
  await session.init();

  runApp(MyPrayerBankApp(session: session));
}

class MyPrayerBankApp extends StatelessWidget {
  final PrayerSessionController session;

  const MyPrayerBankApp({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Prayer Bank',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: AppShell(session: session), // ✅ fixed
    );
  }
}
