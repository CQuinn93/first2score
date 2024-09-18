import 'package:application/dashboard_screen.dart';
import 'package:application/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tdbezgjqthdvrtxgvoao.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkYmV6Z2pxdGhkdnJ0eGd2b2FvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMxMTY1NjQsImV4cCI6MjAzODY5MjU2NH0.xjZo1L99E99-VDB-5PvPM_lbqWmbtz0h4LWMNji1ejk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First2Score',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define routes for navigation
      routes: {
        '/': (context) => const LoginScreen(), // Home is the login screen
        '/dashboard': (context) => const DashboardScreen(), // Dashboard route
      },
      initialRoute: '/', // Start with the login screen
    );
  }
}
