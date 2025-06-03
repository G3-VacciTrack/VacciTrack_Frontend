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
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF33354C),
            size: 35,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          data['title'] ?? 'Details',
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        titleSpacing: 0.0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/${data['cover'] ?? 'placeholder'}.png',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                data['description'] ?? '',
                style: const TextStyle(color: Color(0xFF33354C), fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children:
                    sections
                        .map(
                          (section) => CustomVaccineAccordion(section: section),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (reference != null && reference.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                      color: Color(0xFF33354C),
                      thickness: 0.5,
                      height: 20,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reference',
                      style: TextStyle(
                        color: Color(0xFF33354C),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      style: const TextStyle(
                        color: Color(0xFF33354C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
