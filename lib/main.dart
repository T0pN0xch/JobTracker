import 'package:flutter/material.dart';

import 'db/database_helper.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.seedIfEmpty();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Tracker',
      theme: AppTheme.light(),
      home: const MainScreen(),
    );
  }
}
