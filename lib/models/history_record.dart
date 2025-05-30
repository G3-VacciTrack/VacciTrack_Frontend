class HistoryRecord {
  final String id;
  final String date;
  final String dose;
  final String location;
  final String vaccineName;
  final String? totalDose;

  HistoryRecord({
    required this.id,
    required this.date,
    required this.dose,
    required this.location,
    required this.vaccineName,
    this.totalDose,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      dose: json['dose'].toString(),
      location: json['location'] ?? '',
      vaccineName: json['vaccineName'] ?? '',
      totalDose: json['totalDose']?.toString(),
    );
  }
}
