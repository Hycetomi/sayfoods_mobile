import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// We will create this file next
import 'src/features/auth/auth_gate.dart';

Future<void> main() async {
  // Ensure Flutter bindings are ready before initializing Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://iyieqjqhrcaaapncdpkd.supbase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5aWVxanFocmNhYWFwbmNkcGtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwOTIzNTgsImV4cCI6MjA4NDY2ODM1OH0.7fGZaXwVIAAxdfGOmgCOgZzDfkLHxj14GzTNiNbzkFo',
  );

  // Wrap the app in ProviderScope for Riverpod
  runApp(const ProviderScope(child: SayfoodsApp()));
}

class SayfoodsApp extends StatelessWidget {
  const SayfoodsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sayfoods',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // The AuthGate decides which screen to show first
      home: const AuthGate(),
    );
  }
}
