import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/payment_submission_model.dart';
import 'remote/firestore_service.dart';

class PaymentRemoteDataSource {
  final FirestoreService _firestore;
  static const _collection = 'payments';

  PaymentRemoteDataSource(this._firestore);

  Future<void> submitPayment(PaymentSubmission payment) async {
    if (!kIsWeb) return;
    await _firestore.setDocument(
      _collection,
      payment.id,
      payment.toJson(),
    );
  }

  Stream<List<PaymentSubmission>> streamAllPayments() {
    if (!kIsWeb) return Stream.value(const <PaymentSubmission>[]);

    return _firestore.collectionStream(_collection).map((data) {
      final list = data
          .map((d) => PaymentSubmission.fromJson(Map<String, dynamic>.from(d)))
          .toList();

      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  Stream<List<PaymentSubmission>> streamPendingPayments() {
    return streamAllPayments().map(
      (items) => items.where((p) => p.status == 'pending').toList(),
    );
  }

  Stream<List<PaymentSubmission>> streamPaymentsForUser(String authUid) {
    if (!kIsWeb || authUid.isEmpty) {
      return Stream.value(const <PaymentSubmission>[]);
    }

    return _firestore
        .collectionStreamWhere(_collection, 'memberAuthUid', authUid)
        .map((data) {
      final list = data
          .map((d) => PaymentSubmission.fromJson(Map<String, dynamic>.from(d)))
          .toList();

      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  Future<PaymentSubmission?> getLatestForUser(String authUid) async {
    if (!kIsWeb || authUid.isEmpty) return null;

    final data = await _firestore.queryWhere(
      _collection,
      'memberAuthUid',
      authUid,
    );

    final list = data
        .map((d) => PaymentSubmission.fromJson(Map<String, dynamic>.from(d)))
        .toList();

    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    if (list.isEmpty) return null;
    return list.first;
  }

  Future<void> updateStatus({
    required String paymentId,
    required String status,
    required String reviewedBy,
    String rejectionReason = '',
  }) async {
    if (!kIsWeb) return;

    await _firestore.updateDocument(
      _collection,
      paymentId,
      {
        'status': status,
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      },
    );
  }

  Future<void> deletePayment(String paymentId) async {
    if (!kIsWeb) return;
    await _firestore.deleteDocument(_collection, paymentId);
  }
}
