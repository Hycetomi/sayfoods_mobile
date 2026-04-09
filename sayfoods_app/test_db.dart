import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: 'c:/Users/User/sayfoods_mobile-1/sayfoods_app/.env.local');
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANNON_KEY']!,
  );
  
  try {
    final res = await supabase.from('products').select().limit(1);
    print('Products schema check: $res');
  } catch (e) {
    print('Error: $e');
  }
}
