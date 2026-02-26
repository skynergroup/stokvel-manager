import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> create(
    String collection,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collection).add(data);
  }

  Future<void> set(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return _db.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> read(String path) {
    return _db.doc(path).get();
  }

  Future<void> update(String path, Map<String, dynamic> data) {
    return _db.doc(path).update(data);
  }

  Future<void> delete(String path) {
    return _db.doc(path).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(
    String collection, {
    Object? field,
    Object? isEqualTo,
    Object? arrayContains,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (field != null && isEqualTo != null) {
      query = query.where(field as String, isEqualTo: isEqualTo);
    }
    if (field != null && arrayContains != null) {
      query = query.where(field as String, arrayContains: arrayContains);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collection, {
    Object? field,
    Object? isEqualTo,
    Object? arrayContains,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (field != null && isEqualTo != null) {
      query = query.where(field as String, isEqualTo: isEqualTo);
    }
    if (field != null && arrayContains != null) {
      query = query.where(field as String, arrayContains: arrayContains);
    }
    return query.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(String path) {
    return _db.doc(path).snapshots();
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _db.doc(path);
  }

  WriteBatch batch() {
    return _db.batch();
  }
}
