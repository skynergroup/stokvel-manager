enum ContributionStatus {
  pending,
  paid,
  late_,
  excused;

  String get displayName {
    switch (this) {
      case ContributionStatus.pending:
        return 'Pending';
      case ContributionStatus.paid:
        return 'Paid';
      case ContributionStatus.late_:
        return 'Late';
      case ContributionStatus.excused:
        return 'Excused';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ContributionStatus.pending:
        return 'pending';
      case ContributionStatus.paid:
        return 'paid';
      case ContributionStatus.late_:
        return 'late';
      case ContributionStatus.excused:
        return 'excused';
    }
  }

  static ContributionStatus fromFirestore(String value) {
    switch (value) {
      case 'paid':
        return ContributionStatus.paid;
      case 'late':
        return ContributionStatus.late_;
      case 'excused':
        return ContributionStatus.excused;
      default:
        return ContributionStatus.pending;
    }
  }
}

class Contribution {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? proofUrl;
  final ContributionStatus status;
  final String recordedBy;
  final DateTime createdAt;
  final String? notes;

  const Contribution({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.proofUrl,
    this.status = ContributionStatus.pending,
    required this.recordedBy,
    required this.createdAt,
    this.notes,
  });

  factory Contribution.fromJson(Map<String, dynamic> json, String id) {
    return Contribution(
      id: id,
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: (json['dueDate'] as dynamic).toDate() as DateTime,
      paidDate: json['paidDate'] != null
          ? (json['paidDate'] as dynamic).toDate() as DateTime
          : null,
      proofUrl: json['proofUrl'] as String?,
      status: ContributionStatus.fromFirestore(json['status'] as String),
      recordedBy: json['recordedBy'] as String,
      createdAt: (json['createdAt'] as dynamic).toDate() as DateTime,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'dueDate': dueDate,
      'paidDate': paidDate,
      'proofUrl': proofUrl,
      'status': status.firestoreValue,
      'recordedBy': recordedBy,
      'createdAt': createdAt,
      'notes': notes,
    };
  }

  Contribution copyWith({
    DateTime? paidDate,
    String? proofUrl,
    ContributionStatus? status,
    String? notes,
  }) {
    return Contribution(
      id: id,
      memberId: memberId,
      memberName: memberName,
      amount: amount,
      dueDate: dueDate,
      paidDate: paidDate ?? this.paidDate,
      proofUrl: proofUrl ?? this.proofUrl,
      status: status ?? this.status,
      recordedBy: recordedBy,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }
}
