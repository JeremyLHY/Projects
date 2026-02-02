import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:test_app/services/database.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase Auth User to Custom User
  CustomUser? _userFromFirebaseUser(User? firebaseUser) {
    return firebaseUser != null ? CustomUser(uid: firebaseUser.uid) : null;
  }

  // Auth change user stream
  Stream<CustomUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      debugPrint('Error during Login: $e');
      return null;
    }
  }

  Future registerWithEmailAndPassword(String email, String password) async {
    // Password restriction: at least one uppercase, one number, one symbol
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');

    if (!passwordRegex.hasMatch(password)) {
      debugPrint('Password does not meet the required criteria.');
      return null;
    }

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // Initialize user data with default values
        await DatabaseService(uid: firebaseUser.uid).setUserData(
          accountBalance: 0.0,
          transactions: {},
          budgets: {},
          financialGoals: {},
          billReminders: {},
          linkedAccounts: [],
        );
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      debugPrint('Error during registration: $e');
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Error during Signing Out: $e');
      return null;
    }
  }

  Future<void> sendPasswordResetLink(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      log('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      log('Error: ${e.message}');
    }
  }
}
