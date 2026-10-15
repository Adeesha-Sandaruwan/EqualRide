// Handles account creation, sign-in, and sign-out.
import 'package:firebase_auth/firebase_auth.dart';

// Keeps Firebase account actions together.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Creates an account with the entered email and password.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Signs in with the entered email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Signs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }
}