class AppointmentRecord {
  final String vaccineName;
  final String date;
  final String location;
  final String description;
  final String id;
  final int dose;
  final int totalDose;
  final String diseaseName;
  final String memberId;
  final String memberName;

  AppointmentRecord({
    required this.vaccineName,
    required this.date,
    required this.location,
    required this.description,
    required this.id,
    required this.dose,
    required this.totalDose,
    required this.diseaseName,
    required this.memberId,
    required this.memberName,
  });

  factory AppointmentRecord.fromJson(Map<String, dynamic> json) {
    final dateMap = json['date'];
    DateTime parsedDate;

    if (dateMap is Map && dateMap['_seconds'] != null) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(
        dateMap['_seconds'] * 1000,
      );
    } else {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    }

    return AppointmentRecord(
      id: json['id'] ?? '',
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      date: parsedDate.toIso8601String(),
      description: json['description'] ?? '',
      vaccineName: json['vaccineName'] ?? '',
      location: json['location'] ?? '',
      dose: json['dose'] ?? 1,
      totalDose: json['totalDose'] ?? 1,
      diseaseName: json['diseaseName'] ?? '',
    );
  }
}
