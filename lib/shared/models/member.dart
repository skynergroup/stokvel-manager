enum MemberRole {
  chairperson,
  treasurer,
  secretary,
  member;

  String get displayName {
    switch (this) {
      case MemberRole.chairperson:
        return 'Chairperson';
      case MemberRole.treasurer:
        return 'Treasurer';
      case MemberRole.secretary:
        return 'Secretary';
      case MemberRole.member:
        return 'Member';
    }
  }
}

enum MemberStatus {
  active,
  suspended,
  left;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.suspended:
        return 'Suspended';
      case MemberStatus.left:
        return 'Left';
    }
  }
}

class StokvelMember {
  final String id;
  final String userId;
  final String displayName;
  final String phone;
  final MemberRole role;
  final int? rotationOrder;
  final DateTime joinedAt;
  final MemberStatus status;

  const StokvelMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.phone,
    this.role = MemberRole.member,
    this.rotationOrder,
    required this.joinedAt,
    this.status = MemberStatus.active,
  });

  factory StokvelMember.fromJson(Map<String, dynamic> json, String id) {
    return StokvelMember(
      id: id,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      phone: json['phone'] as String,
      role: MemberRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MemberRole.member,
      ),
      rotationOrder: json['rotationOrder'] as int?,
      joinedAt: (json['joinedAt'] as dynamic).toDate() as DateTime,
      status: MemberStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MemberStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'rotationOrder': rotationOrder,
      'joinedAt': joinedAt,
      'status': status.name,
    };
  }

  StokvelMember copyWith({
    MemberRole? role,
    int? rotationOrder,
    MemberStatus? status,
  }) {
    return StokvelMember(
      id: id,
      userId: userId,
      displayName: displayName,
      phone: phone,
      role: role ?? this.role,
      rotationOrder: rotationOrder ?? this.rotationOrder,
      joinedAt: joinedAt,
      status: status ?? this.status,
    );
  }
}
