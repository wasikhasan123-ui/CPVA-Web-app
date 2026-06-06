import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PasswordService {
  static const _collection = 'passwords';

  Future<void> setPassword(String memberId, String hash) async {
    if (!kIsWeb) return;
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(memberId)
        .set({'hash': hash, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<String?> getPasswordHash(String memberId) async {
    if (!kIsWeb) return null;
    final doc =
        await FirebaseFirestore.instance.collection(_collection).doc(memberId).get();
    if (!doc.exists) return null;
    return doc.data()?['hash']?.toString();
  }

  Future<void> deletePassword(String memberId) async {
    if (!kIsWeb) return;
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(memberId)
        .delete();
  }
}
