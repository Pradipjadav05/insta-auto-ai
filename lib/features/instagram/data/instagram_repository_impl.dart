import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_settings.dart';
import '../domain/instagram_account.dart';
import '../domain/instagram_repository.dart';
import '../../../core/constants/constants.dart';

class InstagramRepositoryImpl implements InstagramRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<InstagramAccount> getConnectedAccount() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.instagramAccount)
          .doc(FirestoreDocs.activeInstagramAccount)
          .get();

      if (doc.exists && doc.data() != null) {
        return InstagramAccount.fromJson(doc.data()!);
      }
      return InstagramAccount.empty();
    } catch (_) {
      return InstagramAccount.empty();
    }
  }

  @override
  Stream<InstagramAccount> watchConnectedAccount() {
    return _firestore
        .collection(FirestoreCollections.instagramAccount)
        .doc(FirestoreDocs.activeInstagramAccount)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return InstagramAccount.fromJson(snapshot.data()!);
      }
      return InstagramAccount.empty();
    });
  }

  @override
  Future<void> connectAccount(InstagramAccount account) async {
    await _firestore
        .collection(FirestoreCollections.instagramAccount)
        .doc(FirestoreDocs.activeInstagramAccount)
        .set(account.toJson());
  }

  @override
  Future<void> disconnectAccount() async {
    await _firestore
        .collection(FirestoreCollections.instagramAccount)
        .doc(FirestoreDocs.activeInstagramAccount)
        .set(InstagramAccount.empty().toJson());
  }

  @override
  Future<AppSettings> getSettings() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc(FirestoreDocs.settingsConfig)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppSettings.fromJson(doc.data()!);
      }
      return AppSettings.empty();
    } catch (_) {
      return AppSettings.empty();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _firestore
        .collection(FirestoreCollections.settings)
        .doc(FirestoreDocs.settingsConfig)
        .set(settings.toJson(), SetOptions(merge: true));
  }
}
