class HistoryRecord {
  final String id;
  final String date;
  final int dose;
  final String location;
  final String vaccineName;
  final int totalDose;
  final String description;
  final String diseaseName;
  final String memberName;
  final String memberId;

  HistoryRecord({
    required this.memberName,
    required this.id,
    required this.date,
    required this.dose,
    required this.location,
    required this.vaccineName,
    required this.totalDose,
    required this.description,
    required this.diseaseName,
    required this.memberId
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      dose: json['dose'],
      location: json['location'] ?? '',
      vaccineName: json['vaccineName'] ?? '',
      totalDose: json['totalDose'],
      description: json['description'] ?? '',
      diseaseName: json['diseaseName'] ?? '',
    );
  }
}
