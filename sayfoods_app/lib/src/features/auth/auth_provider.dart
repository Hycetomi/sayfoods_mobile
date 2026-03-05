import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/providers/supabase_provider.dart';

part 'auth_provider.g.dart';

// 1. Stream: Listens to Login/Logout events instantly
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange;
}

// 2. Future: Fetches the User's Role from the profiles table
@riverpod
Future<String?> userRole(UserRoleRef ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  try {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return response['role'] as String?;
  } catch (e) {
    // If they have no profile yet, default to client
    return 'client';
  }
}
