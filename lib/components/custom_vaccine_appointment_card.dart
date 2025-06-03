import 'package:flutter/material.dart';

class VaccineAppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String date;
  final String description;
  final String vaccineName;
  final String hospital;
  final int dose;
  final String diseaseName;

  const VaccineAppointmentCard({
    super.key,
    required this.appointmentId,
    required this.diseaseName,
    required this.date,
    required this.description,
    required this.vaccineName,
    required this.hospital,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  "Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date ',
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
