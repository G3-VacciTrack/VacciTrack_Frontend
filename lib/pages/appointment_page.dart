// lib/components/appointment_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';
  String errorMessage = '';
  late Future<List<dynamic>> futureAppointments;

  @override
  void initState() {
    super.initState();
    futureAppointments = fetchAppointments();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<List<dynamic>> fetchAppointments() async {
    final uid = await getUserId();
    if (uid == null) return [];

    final url = Uri.parse('$baseUrl/appointment/all?uid=$uid');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['appointment'] != null &&
            jsonResponse['appointment'] is List) {
          return jsonResponse['appointment'] as List<dynamic>;
        } else {
          setState(() {
            errorMessage = 'No appointment data found';
          });
          return [];
        }
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureAppointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments found.'));
          } else {
            final appointments = snapshot.data!;
            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];

                // Parse the UNIX timestamp _seconds to DateTime
                DateTime? dateTime;
                if (appt['date'] != null && appt['date']['_seconds'] != null) {
                  dateTime = DateTime.fromMillisecondsSinceEpoch(
                    appt['date']['_seconds'] * 1000,
                  );
                }

                // Format date string or fallback
                final dateStr =
                    dateTime != null
                        ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
                        : 'Unknown Date';

                final vaccineName = appt['vaccineName'] ?? 'Unknown Vaccine';
                final description = appt['description'] ?? '';
                final location = appt['location'] ?? 'Unknown Location';
                final dose = appt['dose'] ?? '';

                return ListTile(
                  title: Text('$vaccineName - $dose'),
                  subtitle: Text('$dateStr\n$location\n$description'),
                  isThreeLine: true,
                );
              },
            );
          }
        },
      ),
    );
  }
}
