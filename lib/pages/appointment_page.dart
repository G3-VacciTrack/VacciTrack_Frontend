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
  List<AppointmentRecord> allAppointments = [];
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
    });
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
          final fetchedAppointments =
              (jsonResponse['appointment'] as List)
                  .map((item) => AppointmentRecord.fromJson(item))
                  .toList();
          setState(() {
            allAppointments = fetchedAppointments;
            errorMessage = '';
          });
          return fetchedAppointments;
        } else {
          setState(() {
            errorMessage = 'No Appointment found.';
            allAppointments = [];
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
    final bool canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                leading:
                    canPop
                        ? IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF33354C),
                            size: 35,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                        : null,
                title: const Text(
                  'Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                titleSpacing: canPop ? 0.0 : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF33354C).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search appointment',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6F6F6F),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF6CC2A8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),
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
                    } else if (snapshot.hasData) {
                      List<AppointmentRecord> displayedAppointments = snapshot.data!;
                      final searchQuery = _searchController.text.toLowerCase();
                      if (searchQuery.isNotEmpty) {
                        displayedAppointments =
                            displayedAppointments.where((record) {
                              return record.vaccineName.toLowerCase().contains(
                                searchQuery,
                              );
                            }).toList();
                      }
                      if (displayedAppointments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
                                size: 80,
                                color: const Color.fromARGB(255, 186, 235, 221),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Text(
                                errorMessage.isNotEmpty
                                    ? errorMessage
                                    : 'No upcoming appointments found.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      displayedAppointments.sort(
                        (a, b) => DateTime.parse(
                          a.date,
                        ).compareTo(DateTime.parse(b.date)),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: displayedAppointments.length,
                          itemBuilder: (context, index) {
                            final appt = displayedAppointments[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: GestureDetector(
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
                                  diseaseName: appt.diseaseName,
                                  vaccineName: appt.vaccineName,
                                  hospital: appt.location,
                                  date: formatDate(appt.date),
                                  description: appt.description,
                                  dose: appt.dose,
                                ),
                              ),
                            );
                          },
                        ),
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
          showAddAppointmentDialog(
            context,
            onAppointmentAdded: () {
              _fetchAppointments();
            },
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Appointment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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