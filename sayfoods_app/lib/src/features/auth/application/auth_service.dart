import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  Future<void> signInWithGoogle() async {
    // PASTE YOUR REAL WEB CLIENT ID HERE:
    const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

    // 1. Initialize the instance
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);

    try {
      // 2. Trigger the Google popup
      // Note: This no longer returns null. If canceled, it throws an exception.
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3. Extract the ID token
      // Note: 'authentication' is synchronous in v7, so we removed the 'await' here
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      // 4. Extract the Access token
      final googleAuthorization = await googleUser.authorizationClient
          .authorizationForScopes([]);
      final accessToken = googleAuthorization?.accessToken;

      if (idToken == null) {
        throw 'Missing Google ID Token';
      }

      // 5. Pass the tokens to Supabase
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on GoogleSignInException catch (e) {
      // This is the new v7 way of handling user cancellations!
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return; // User closed the popup, so we just exit silently.
      }
      rethrow; // If it's a real error, throw it back to the UI to show a snackbar.
    }
  }
}
