import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> collectionStream(String collection) {
    return _db
        .collection(collection)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['docId'] = d.id;
              data['id'] = data['id'] ?? d.id;
              return data;
            }).toList());
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final snap = await _db.collection(collection).get();
    return snap.docs.map((d) {
      final data = d.data();
      data['docId'] = d.id;
      data['id'] = data['id'] ?? d.id;
      return data;
    }).toList();
  }

  /// Read a single document by ID. Returns null if it doesn't exist.
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    final doc = await _db.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    data['docId'] = doc.id;
    data['id'] = data['id'] ?? doc.id;
    return data;
  }

  Future<void> setDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id).set(data);
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<void> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).add(data);
  }

  Stream<List<Map<String, dynamic>>> collectionStreamWhere(
    String collection,
    String field,
    Object value,
  ) {
    return _db
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['docId'] = d.id;
              data['id'] = data['id'] ?? d.id;
              return data;
            }).toList());
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String collection,
    String field,
    Object value,
  ) async {
    final snap = await _db
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['docId'] = d.id;
      data['id'] = data['id'] ?? d.id;
      return data;
    }).toList();
  }
}
