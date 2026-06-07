import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSubmission {
  final String id;
  final String memberId;
  final String memberAuthUid;
  final String memberName;
  final String memberMobile;
  final String memberEmail;
  final String amount;
  final String paymentMethod;
  final String transactionId;
  final String screenshotUrl;
  final String type;
  final String status;
  final String submittedAt;
  final String reviewedAt;
  final String reviewedBy;
  final String rejectionReason;

  const PaymentSubmission({
    required this.id,
    required this.memberId,
    required this.memberAuthUid,
    required this.memberName,
    required this.memberMobile,
    required this.memberEmail,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.screenshotUrl,
    this.type = 'renewal',
    this.status = 'pending',
    required this.submittedAt,
    this.reviewedAt = '',
    this.reviewedBy = '',
    this.rejectionReason = '',
  });

  factory PaymentSubmission.fromJson(Map<String, dynamic> json) {
    String dateToString(dynamic value) {
      if (value == null) return '';
      if (value is Timestamp) return value.toDate().toIso8601String();
      return value.toString();
    }

    return PaymentSubmission(
      id: (json['id'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      memberAuthUid: (json['memberAuthUid'] ?? '').toString(),
      memberName: (json['memberName'] ?? '').toString(),
      memberMobile: (json['memberMobile'] ?? '').toString(),
      memberEmail: (json['memberEmail'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      screenshotUrl: (json['screenshotUrl'] ?? '').toString(),
      type: (json['type'] ?? 'renewal').toString(),
      status: (json['status'] ?? 'pending').toString(),
      submittedAt: dateToString(json['submittedAt']),
      reviewedAt: dateToString(json['reviewedAt']),
      reviewedBy: (json['reviewedBy'] ?? '').toString(),
      rejectionReason: (json['rejectionReason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'memberAuthUid': memberAuthUid,
        'memberName': memberName,
        'memberMobile': memberMobile,
        'memberEmail': memberEmail,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'screenshotUrl': screenshotUrl,
        'type': type,
        'status': status,
        'submittedAt': submittedAt,
        'reviewedAt': reviewedAt,
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      };

  PaymentSubmission copyWith({
    String? id,
    String? memberId,
    String? memberAuthUid,
    String? memberName,
    String? memberMobile,
    String? memberEmail,
    String? amount,
    String? paymentMethod,
    String? transactionId,
    String? screenshotUrl,
    String? type,
    String? status,
    String? submittedAt,
    String? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return PaymentSubmission(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberAuthUid: memberAuthUid ?? this.memberAuthUid,
      memberName: memberName ?? this.memberName,
      memberMobile: memberMobile ?? this.memberMobile,
      memberEmail: memberEmail ?? this.memberEmail,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
