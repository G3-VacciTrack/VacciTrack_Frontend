import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaccitrack_frontend/pages/appointment_page.dart';
import 'package:vaccitrack_frontend/pages/history_page.dart';
import 'package:intl/intl.dart';

import '../models/appointment_record.dart';
import '../components/custom_vaccine_appointment_card.dart';
import './education_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? educationData;
  List<AppointmentRecord> upcomingAppointments = [];
  bool isLoading = true;
  bool isLoadingAppointments = true;
  String name = "";
  String errorMessage = '';
  int currentPage = 0;
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchEducationData();
    fetchUpcomingAppointments();
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
      debugPrint("Error fetching education data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUpcomingAppointments() async {
    setState(() {
      isLoadingAppointments = true;
    });
    try {
      final uid = await getUserId();
      if (uid == null) {
        setState(() {
          errorMessage = 'User not logged in.';
          isLoadingAppointments = false;
        });
        return;
      }
      final url = Uri.parse('$baseUrl/appointment/upcoming?uid=$uid');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['appointment'] != null &&
            jsonResponse['appointment'] is List) {
          setState(() {
            upcomingAppointments =
                (jsonResponse['appointment'] as List)
                    .map((item) => AppointmentRecord.fromJson(item))
                    .toList();
            upcomingAppointments.sort((a, b) {
              DateTime dateA = DateTime.parse(a.date);
              DateTime dateB = DateTime.parse(b.date);
              return dateA.compareTo(dateB);
            });
            errorMessage = '';
          });
        } else {
          setState(() {
            upcomingAppointments = [];
            errorMessage = 'No upcoming appointments found.';
          });
        }
      } else {
        setState(() {
          upcomingAppointments = [];
          errorMessage =
              'Failed to load upcoming appointments';
        });
      }
    } catch (e) {
      debugPrint("Error fetching upcoming appointments: $e");
      setState(() {
        errorMessage =
            'Failed to connect to server or no upcoming appointments.';
        upcomingAppointments = [];
      });
    } finally {
      setState(() {
        isLoadingAppointments = false;
      });
    }
  }

  Future<void> fetchUserName() async {
    try {
      final uid = await getUserId();
      if (uid == null) {
        setState(() {
          errorMessage = 'User not logged in.';
        });
        return;
      }
      final url = Uri.parse('$baseUrl/user/name?uid=$uid');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          name = json.decode(response.body)['name'] ?? 'User';
        });
      }
    } catch (e) {
      setState(() {
        name = 'User';
      });
    }
  }

  String formatDate(String dateTimeString) {
    try {
      if (dateTimeString.contains('_seconds') &&
          dateTimeString.contains('_nanoseconds')) {
        final Map<String, dynamic> dateMap = json.decode(dateTimeString);
        final int seconds = dateMap['_seconds'];
        final int nanoseconds = dateMap['_nanoseconds'];
        final dt = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
        return DateFormat('d MMM y').format(dt);
      } else {
        final dt = DateTime.parse(dateTimeString);
        return DateFormat('d MMM y').format(dt);
      }
    } catch (e) {
      debugPrint("Error parsing date: $e for string: $dateTimeString");
      return dateTimeString;
    }
  }

  Widget renderPageContent() {
    if (isLoading || isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (educationData == null || educationData!['education'] is! List) {
      return const Center(child: Text('No education data available'));
    }

    final List educations = educationData!['education'] as List;

    if (currentPage == 1) return const HistoryPage();
    if (currentPage == 2) return const AppointmentPage();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 9),
          const Text(
            'Upcoming Vaccine',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF33354C),
            ),
          ),
          const SizedBox(height: 9),
          if (upcomingAppointments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 60,
                      color: const Color.fromARGB(255, 186, 235, 221),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage.isNotEmpty
                          ? errorMessage
                          : 'No upcoming appointments scheduled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children:
                  upcomingAppointments.map((appt) {
                    return GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: VaccineAppointmentCard(
                          memberName: appt.memberName,
                          appointmentId: appt.id,
                          diseaseName: appt.diseaseName,
                          vaccineName: appt.vaccineName,
                          hospital: appt.location,
                          date: formatDate(appt.date),
                          description: appt.description,
                          dose: appt.dose,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentPage(),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
          const SizedBox(height: 12),
          const Text(
            'Manage Your Vaccines',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF33354C),
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 350,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF33354C).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33354C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Easily keep track of your past vaccinations by adding them to your history. Just enter the vaccine name, date, and any notes to build a complete and organized record—all in one place.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F6F6F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6CC2A8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Add Vaccine History',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 350,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF33354C).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33354C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Stay on top of upcoming vaccines with our appointment system. Schedule future vaccination dates and receive timely reminders, so you never miss an important shot again.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F6F6F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6CC2A8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Create Appointment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Recommended Vaccines by Age',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF33354C),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  educations.map((item) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EducationDetailPage(data: item),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 10,
                          left: 7,
                          right: 16,
                          bottom: 16,
                        ),
                        width: 180,
                        height: 210,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF33354C).withOpacity(0.1),
                              offset: const Offset(0, 0),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (item['cover'] != null)
                                  Image.asset(
                                    'assets/images/${item['cover']}.png',
                                    width: double.infinity,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  item['title'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 130,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF33354C),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['subtitle'] ?? 'Subtitle here',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Scaffold(
        appBar: AppBar(
          title:
              currentPage == 0
                  ? Text(
                    'Hello $name!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  )
                  : const Text(''),
          leading:
              currentPage != 0
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        currentPage = 0;
                      });
                    },
                  )
                  : null,
        ),
        body: renderPageContent(),
      ),
    );
  }
}
