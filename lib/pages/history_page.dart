import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3001/api';
  String errorMessage = '';
  List<dynamic> history = [];
  late Future<List<dynamic>> futureHistory;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<List<dynamic>> fetchHistory() async {
    final uid = await getUserId();
    if (uid == null) return [];

    final url = Uri.parse('$baseUrl/history/all?uid=$uid');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['history'] != null &&
            jsonResponse['history'] is List) {
          return jsonResponse['history'] as List<dynamic>;
        } else {
          setState(() {
            errorMessage = 'No history data found';
          });
          return [];
        }
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    futureHistory = fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No vaccination history found.'));
          } else {
            history = snapshot.data!;
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return ListTile(
                  title: Text(record['vaccineName'] ?? 'Unknown Vaccine'),
                  subtitle: Text('Date: ${record['date'] ?? 'Unknown'}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class HistoryRecord {
  final String id;
  final String date;
  final String dose;
  final String location;
  final String vaccineName;

  HistoryRecord({
    required this.id,
    required this.date,
    required this.dose,
    required this.location,
    required this.vaccineName,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      dose: json['dose'] ?? '',
      location: json['location'] ?? '',
      vaccineName: json['vaccineName'] ?? '',
    );
  }
}
