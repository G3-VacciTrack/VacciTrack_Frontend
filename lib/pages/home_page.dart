import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './education_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? educationData;
  bool isLoading = true;
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';
  @override
  void initState() {
    super.initState();
    fetchEducationData();
  }

  Future<void> fetchEducationData() async {
    try {
      final url = Uri.parse('$baseUrl/education/all');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          educationData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (educationData == null || educationData!['education'] == null) {
      return const Center(child: Text('No data available'));
    }

    final List educations = educationData!['education'];

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccination Tracker')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: educations.length,
        itemBuilder: (context, index) {
          final item = educations[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EducationDetailPage(data: item),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 24),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['cover'] != null)
                    Image.asset(
                      'assets/images/${item['cover']}.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
