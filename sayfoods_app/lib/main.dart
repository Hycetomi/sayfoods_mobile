import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/features/auth/auth_gate.dart';

Future<void> main() async {
  // Ensure Flutter bindings are ready before initializing
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env.local
  await dotenv.load(fileName: '.env.local');

  // Initialize Supabase using values from .env.local
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANNON_KEY']!,
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
