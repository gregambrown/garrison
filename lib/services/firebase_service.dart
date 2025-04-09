import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initFirebase() async {
    await Firebase.initializeApp();
  }

  static Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  static String get currentUserId => _auth.currentUser?.uid ?? '';

  static String get displayName => _auth.currentUser?.displayName ?? 'Player';
}
