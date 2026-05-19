import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/features/auth/auth_gate.dart';
import 'src/shared/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter bindings are ready before initializing
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env.local
  await dotenv.load(fileName: '.env.local');

  // Initialise Mapbox with the public access token before runApp
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '');

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
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // The AuthGate decides which screen to show first
      home: const AuthGate(),
    );
  }
}
