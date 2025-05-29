import 'package:flutter/material.dart';

class CustomVaccineAccordion extends StatelessWidget {
  final Map<String, dynamic> section;

  const CustomVaccineAccordion({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final vaccines = section['vaccines'] ?? [];

    return ExpansionTile(
      title: Text(
        section['title'] ?? '',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      shape: Border.all(color: Colors.transparent),
      tilePadding: EdgeInsets.zero,
      collapsedIconColor: Colors.black,
      expandedAlignment: Alignment.centerLeft,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(vaccines.length, (vIndex) {
              final vaccine = vaccines[vIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ${vaccine['name']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (vaccine['doses'] != null)
                      Text(
                        vaccine['doses'],
                      ),
                    if (vaccine['importance'] != null)
                      Text(
                        "Why important: ${vaccine['importance']}",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
