import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  AuthService(this.auth, this.db);
  Stream<User?> get authState => auth.authStateChanges();
  User? get currentUser => auth.currentUser;
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> saveProfile(String first, String last) async {
    final uid = auth.currentUser!.uid;
    final ref = db.collection('users').doc(uid);
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (!existing.exists) {
        tx.set(ref, {
          'uid': uid,
          'firstName': first.trim(),
          'lastName': last.trim(),
          'role': 'member',
          'registrationDateTime': FieldValue.serverTimestamp(),
        });
      }
    });
    await ref.get(const GetOptions(source: Source.server));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile() =>
      db.collection('users').doc(currentUser!.uid).snapshots();
  Future<void> signOut() => auth.signOut();
}

String friendlyError(Object e) {
  if (e is FirebaseException) {
    return switch (e.code) {
      'email-already-in-use' =>
        'This email already has an account. Please sign in.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect.',
      'weak-password' => 'Use a password with at least 6 characters.',
      'permission-denied' => 'This action is not permitted for your account.',
      'network-request-failed' || 'unavailable' =>
        'Connection unavailable. Reconnect and retry; your pending post is preserved.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => 'Could not finish (${e.code}). Please retry.',
    };
  }
  return 'Could not finish. Please check your connection and retry.';
}
