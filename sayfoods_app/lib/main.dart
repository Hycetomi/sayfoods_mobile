import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final textTheme = ThemeData.light().textTheme;

    return MaterialApp(
      title: 'Sayfoods',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B1380),
          primary: const Color(0xFF5B1380), // Enforce the exact brand color
        ),
        useMaterial3: true,
        // Default text styling with Montserrat
        textTheme: GoogleFonts.montserratTextTheme(textTheme).copyWith(
          // Specific overrides for Bricolage Grotesque where needed.
          displayLarge: GoogleFonts.bricolageGrotesque(
            textStyle: textTheme.displayLarge,
          ),
          titleLarge: GoogleFonts.bricolageGrotesque(
            textStyle: textTheme.titleLarge,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // The AuthGate decides which screen to show first
      home: const AuthGate(),
    );
  }
}
