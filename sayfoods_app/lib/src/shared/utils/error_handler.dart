import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHelper {
  /// Converts a raw exception into a user-friendly message.
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      // Supabase Auth errors
      if (error.message.contains('Invalid login credentials')) {
        return 'Incorrect email or password. Please try again.';
      } else if (error.message.contains('User already registered')) {
        return 'An account with this email already exists.';
      }
      return error.message; // Fallback to safe Supabase messages if needed, or customize more
    } else if (error is PostgrestException) {
      // Show actual DB error in debug so it's visible without logcat
      assert(() {
        debugPrint('[DB ERROR] code=${error.code}  message=${error.message}  details=${error.details}  hint=${error.hint}');
        return true;
      }());
      // In debug builds expose the raw message so it's readable on-device
      if (kDebugMode) {
        return 'DB error (${error.code}): ${error.message}';
      }
      return 'We encountered an issue communicating with our database. Please try again later.';
    } else if (error.toString().contains('SocketException') || error.toString().contains('ClientException')) {
      // Network errors
      return 'Network connection failed. Please check your internet and try again.';
    }
    
    // Generic fallback for any other errors (hides implementation details)
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Displays a premium error snackbar or notification.
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    
    // We can replace this with elegant_notification or custom Toast down the line
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935), // AppColors.error
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  /// Displays a premium success snackbar.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047), // AppColors.success
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }
}
