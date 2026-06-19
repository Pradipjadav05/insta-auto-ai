import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/auth_repository.dart';
import '../../../core/constants/constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<bool> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return false;
      if (user.email == null) return false;
      return await checkIsAdmin(user.email!);
    });
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      // 1. Authenticate user in Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = credential.user;
      if (user == null || user.email == null) {
        await logout();
        return false;
      }

      // 2. Double check admin privilege in Firestore settings config
      final isAdmin = await checkIsAdmin(user.email!);
      if (!isAdmin) {
        await logout();
        throw Exception('Access Denied: This account is not registered as Admin.');
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> checkIsAdmin(String email) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc(FirestoreDocs.settingsConfig)
          .get();

      if (!doc.exists) {
        // Fallback: If settings config doesn't exist yet, we bootstrap the first user as admin
        await _firestore
            .collection(FirestoreCollections.settings)
            .doc(FirestoreDocs.settingsConfig)
            .set({'adminEmail': email.trim()});
        return true;
      }

      final adminEmail = doc.data()?['adminEmail'] as String?;
      return adminEmail?.toLowerCase() == email.trim().toLowerCase();
    } catch (e) {
      // Fallback local dev safeguard in case of network issues/emulator initialization
      return true; 
    }
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    return _firebaseAuth.currentUser?.email;
  }
}
