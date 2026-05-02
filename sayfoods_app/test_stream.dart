import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final supabase = SupabaseClient('https://mock.supabase.co', 'mock');
  final builder = supabase.from('orders').stream(primaryKey: ['id']);
  
  var test = builder.eq('status', 'delivering').eq('rider_id', '123');
}
