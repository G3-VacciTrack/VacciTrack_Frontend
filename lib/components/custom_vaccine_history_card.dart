import 'package:flutter/material.dart';

class VaccineHistoryCard extends StatelessWidget {
  final String historyId;
  final String memberName;
  final String vaccineName;
  final String hospital;
  final int dose;
  final int totalDose;
  final String description;
  final String diseaseName;

  const VaccineHistoryCard({
    super.key,
    required this.memberName,
    required this.historyId,
    required this.diseaseName,
    required this.vaccineName,
    required this.hospital,
    required this.dose,
    required this.totalDose,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF33354C).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vaccineName.isNotEmpty
                            ? vaccineName
                            : 'Unknown Vaccine',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 160,
                        child: Text(
                          diseaseName.isNotEmpty ? ': $diseaseName' : '',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$memberName', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    hospital.isNotEmpty ? hospital : 'Unknown Hospital',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "Dose",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dose / $totalDose',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
