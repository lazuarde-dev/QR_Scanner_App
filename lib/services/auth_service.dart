import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream perubahan status auth (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. FUNGSI LOGIN
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Error: ${e.toString()}';
    }
  }

  // 2. FUNGSI REGISTER
  Future<void> signUp({required String email, required String password, required String name}) async {
    try {
      // Create user di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Display Name (Nama Lengkap)
      await result.user?.updateDisplayName(name);
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Error: ${e.toString()}';
    }
  }

  // 3. FUNGSI LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper: Menerjemahkan Error Firebase ke Bahasa Manusia
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah digunakan akun lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}