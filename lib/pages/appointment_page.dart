import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/appointment_record.dart';
import '../components/custom_vaccine_appointment_card.dart';
import '../components/custom_create_appointment_dialog.dart'; 
import '../components/custom_appointment_detail_dialog.dart'; 
import 'package:intl/intl.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  String errorMessage = '';
  late Future<List<AppointmentRecord>> futureAppointments;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      futureAppointments = fetchAppointments();
    });
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<List<AppointmentRecord>> fetchAppointments() async {
    final uid = await getUserId();
    if (uid == null) {
      setState(() {
        errorMessage = 'User not logged in.';
      });
      return [];
    }

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
          setState(() {
            errorMessage = '';
          });
          return (jsonResponse['appointment'] as List)
              .map((item) => AppointmentRecord.fromJson(item))
              .toList();
        } else {
          setState(() {
            errorMessage = 'No Appointment found.';
          });
          return [];
        }
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      setState(() {
        errorMessage = 'No Appointment Found.';
      });
      return [];
    }
  }

  String formatDate(String dateTimeString) {
    try {
      final dt = DateTime.parse(dateTimeString);
      final formatter = DateFormat('d MMM y');
      return formatter.format(dt);
    } catch (_) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  'Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0.0,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                floating: false,
              ),
              SliverFillRemaining(
                child: FutureBuilder<List<AppointmentRecord>>(
                  future: futureAppointments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}\n$errorMessage'),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'No upcoming appointments.',
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final appointments = snapshot.data!;
                      appointments.sort(
                        (a, b) => DateTime.parse(
                          a.date,
                        ).compareTo(DateTime.parse(b.date)),
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appt = appointments[index];
                          return GestureDetector(
                            onTap: () {
                              showAppointmentDetailsDialog(
                                context,
                                appointment: appt,
                                onAppointmentUpdated: () {
                                  _fetchAppointments(); 
                                },
                              );
                            },
                            child: VaccineAppointmentCard(
                              appointmentId: appt.id,
                              vaccineName: appt.vaccineName,
                              hospital: appt.location,
                              date: formatDate(appt.date),
                              description: appt.description,
                              dose: appt.dose,
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(child: Text('No data available.'));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddAppointmentDialog(context, onAppointmentAdded: () {
            _fetchAppointments();
          });
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Appointment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF6CC2A8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
