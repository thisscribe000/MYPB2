import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'HomeScreen is no longer used.\nGo to AppShell tabs (Projects).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
