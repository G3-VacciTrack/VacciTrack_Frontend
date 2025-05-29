import 'package:flutter/material.dart';
import '../components/custom_vaccine_accordion.dart';

class EducationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const EducationDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List sections = data['sections'] ?? [];
    final String? reference = data['Reference'];

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['cover'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['cover'],
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text(
              data['description'] ?? '',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),

            ...sections.map((section) => CustomVaccineAccordion(section: section)).toList(),

            SizedBox(height: 32),
            if (reference != null && reference.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    'Reference',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    reference,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
