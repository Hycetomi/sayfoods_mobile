import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String phoneNumber;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  // Fetch the extra details from your profiles table
  final data = await supabase
      .from('profiles')
      .select('full_name, phone_number')
      .eq('id', user.id)
      .maybeSingle();

  return UserProfile(
    fullName: data?['full_name'] as String? ?? 'Sayfoods User',
    email: user.email ?? 'No email provided',
    phoneNumber: data?['phone_number'] as String? ?? 'No phone number',
  );
});
