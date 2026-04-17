import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: 'c:/Users/User/sayfoods_mobile-1/sayfoods_app/.env.local');
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANNON_KEY']!,
  );
  
  try {
    // get a UUID
    final list = await supabase.from('products').select().limit(1);
    if (list.isEmpty) {
      print('No products found');
      return;
    }
    final productId = list.first['id'];
    print('Testing update on product $productId');

    final res = await supabase.from('products').update({'stock_quantity': 55}).eq('id', productId).select();
    print('Update result: $res');
  } catch (e) {
    print('Error: $e');
  }
}
