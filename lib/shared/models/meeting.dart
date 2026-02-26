class Meeting {
  final String id;
  final String title;
  final DateTime date;
  final String? locationName;
  final double? locationLat;
  final double? locationLng;
  final String? virtualLink;
  final String? agenda;
  final String? minutes;
  final Map<String, String> rsvps; // userId -> "yes" | "no" | "maybe"
  final String createdBy;
  final DateTime createdAt;

  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.virtualLink,
    this.agenda,
    this.minutes,
    this.rsvps = const {},
    required this.createdBy,
    required this.createdAt,
  });

  bool get isVirtual => virtualLink != null && virtualLink!.isNotEmpty;
  bool get isInPerson => locationName != null && locationName!.isNotEmpty;

  int get yesCount =>
      rsvps.values.where((v) => v == 'yes').length;
  int get noCount =>
      rsvps.values.where((v) => v == 'no').length;
  int get maybeCount =>
      rsvps.values.where((v) => v == 'maybe').length;

  factory Meeting.fromJson(Map<String, dynamic> json, String id) {
    return Meeting(
      id: id,
      title: json['title'] as String,
      date: (json['date'] as dynamic).toDate() as DateTime,
      locationName: json['locationName'] as String?,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      virtualLink: json['virtualLink'] as String?,
      agenda: json['agenda'] as String?,
      minutes: json['minutes'] as String?,
      rsvps: Map<String, String>.from(json['rsvps'] ?? {}),
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as dynamic).toDate() as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'locationName': locationName,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'virtualLink': virtualLink,
      'agenda': agenda,
      'minutes': minutes,
      'rsvps': rsvps,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  Meeting copyWith({
    String? title,
    DateTime? date,
    String? locationName,
    double? locationLat,
    double? locationLng,
    String? virtualLink,
    String? agenda,
    String? minutes,
    Map<String, String>? rsvps,
  }) {
    return Meeting(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      virtualLink: virtualLink ?? this.virtualLink,
      agenda: agenda ?? this.agenda,
      minutes: minutes ?? this.minutes,
      rsvps: rsvps ?? this.rsvps,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
