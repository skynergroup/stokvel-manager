enum StokvelType {
  rotational,
  savings,
  burial,
  grocery,
  investment,
  hybrid;

  String get displayName {
    switch (this) {
      case StokvelType.rotational:
        return 'Rotational';
      case StokvelType.savings:
        return 'Savings';
      case StokvelType.burial:
        return 'Burial Society';
      case StokvelType.grocery:
        return 'Grocery';
      case StokvelType.investment:
        return 'Investment';
      case StokvelType.hybrid:
        return 'Hybrid';
    }
  }
}

class Stokvel {
  final String id;
  final String name;
  final StokvelType type;
  final String? constitutionUrl;
  final double contributionAmount;
  final String contributionFrequency;
  final String currency;
  final String createdBy;
  final DateTime createdAt;
  final int memberCount;
  final double totalCollected;
  final String? whatsappGroupId;
  final bool nasasaRegistered;
  final String? description;

  const Stokvel({
    required this.id,
    required this.name,
    required this.type,
    this.constitutionUrl,
    required this.contributionAmount,
    this.contributionFrequency = 'monthly',
    this.currency = 'ZAR',
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
    this.totalCollected = 0,
    this.whatsappGroupId,
    this.nasasaRegistered = false,
    this.description,
  });

  factory Stokvel.fromJson(Map<String, dynamic> json, String id) {
    return Stokvel(
      id: id,
      name: json['name'] as String,
      type: StokvelType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StokvelType.savings,
      ),
      constitutionUrl: json['constitutionUrl'] as String?,
      contributionAmount: (json['contributionAmount'] as num).toDouble(),
      contributionFrequency:
          json['contributionFrequency'] as String? ?? 'monthly',
      currency: json['currency'] as String? ?? 'ZAR',
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as dynamic).toDate() as DateTime,
      memberCount: json['memberCount'] as int? ?? 0,
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0,
      whatsappGroupId: json['whatsappGroupId'] as String?,
      nasasaRegistered: json['nasasaRegistered'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'constitutionUrl': constitutionUrl,
      'contributionAmount': contributionAmount,
      'contributionFrequency': contributionFrequency,
      'currency': currency,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'memberCount': memberCount,
      'totalCollected': totalCollected,
      'whatsappGroupId': whatsappGroupId,
      'nasasaRegistered': nasasaRegistered,
      'description': description,
    };
  }

  Stokvel copyWith({
    String? name,
    StokvelType? type,
    String? constitutionUrl,
    double? contributionAmount,
    String? contributionFrequency,
    int? memberCount,
    double? totalCollected,
    String? whatsappGroupId,
    bool? nasasaRegistered,
    String? description,
  }) {
    return Stokvel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      constitutionUrl: constitutionUrl ?? this.constitutionUrl,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      contributionFrequency:
          contributionFrequency ?? this.contributionFrequency,
      currency: currency,
      createdBy: createdBy,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
      totalCollected: totalCollected ?? this.totalCollected,
      whatsappGroupId: whatsappGroupId ?? this.whatsappGroupId,
      nasasaRegistered: nasasaRegistered ?? this.nasasaRegistered,
      description: description ?? this.description,
    );
  }
}
