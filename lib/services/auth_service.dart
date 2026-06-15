import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential> signInWithGoogle() async {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.setCustomParameters({
      'prompt': 'select_account',
    });

    return await _auth.signInWithPopup(googleProvider);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}