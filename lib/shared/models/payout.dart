enum PayoutType {
  rotation,
  burialClaim,
  grocery,
  savings,
  investmentReturn;

  String get displayName {
    switch (this) {
      case PayoutType.rotation:
        return 'Rotation';
      case PayoutType.burialClaim:
        return 'Burial Claim';
      case PayoutType.grocery:
        return 'Grocery';
      case PayoutType.savings:
        return 'Savings';
      case PayoutType.investmentReturn:
        return 'Investment Return';
    }
  }

  String get firestoreValue {
    switch (this) {
      case PayoutType.rotation:
        return 'rotation';
      case PayoutType.burialClaim:
        return 'burial_claim';
      case PayoutType.grocery:
        return 'grocery';
      case PayoutType.savings:
        return 'savings';
      case PayoutType.investmentReturn:
        return 'investment_return';
    }
  }

  static PayoutType fromFirestore(String value) {
    switch (value) {
      case 'rotation':
        return PayoutType.rotation;
      case 'burial_claim':
        return PayoutType.burialClaim;
      case 'grocery':
        return PayoutType.grocery;
      case 'savings':
        return PayoutType.savings;
      case 'investment_return':
        return PayoutType.investmentReturn;
      default:
        return PayoutType.rotation;
    }
  }
}

enum PayoutStatus {
  scheduled,
  approved,
  paid,
  disputed;

  String get displayName {
    switch (this) {
      case PayoutStatus.scheduled:
        return 'Scheduled';
      case PayoutStatus.approved:
        return 'Approved';
      case PayoutStatus.paid:
        return 'Paid';
      case PayoutStatus.disputed:
        return 'Disputed';
    }
  }
}

class Payout {
  final String id;
  final String recipientId;
  final String recipientName;
  final double amount;
  final DateTime payoutDate;
  final PayoutType type;
  final PayoutStatus status;
  final List<String> approvedBy;
  final String? notes;
  final DateTime createdAt;

  const Payout({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    required this.payoutDate,
    required this.type,
    this.status = PayoutStatus.scheduled,
    this.approvedBy = const [],
    this.notes,
    required this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json, String id) {
    return Payout(
      id: id,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String,
      amount: (json['amount'] as num).toDouble(),
      payoutDate: (json['payoutDate'] as dynamic).toDate() as DateTime,
      type: PayoutType.fromFirestore(json['type'] as String),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PayoutStatus.scheduled,
      ),
      approvedBy: List<String>.from(json['approvedBy'] ?? []),
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as dynamic).toDate() as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'recipientName': recipientName,
      'amount': amount,
      'payoutDate': payoutDate,
      'type': type.firestoreValue,
      'status': status.name,
      'approvedBy': approvedBy,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  Payout copyWith({
    PayoutStatus? status,
    List<String>? approvedBy,
    String? notes,
  }) {
    return Payout(
      id: id,
      recipientId: recipientId,
      recipientName: recipientName,
      amount: amount,
      payoutDate: payoutDate,
      type: type,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
