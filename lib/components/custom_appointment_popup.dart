import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppointmentPopup {
  static void show({
    required BuildContext context,
    String? appointmentId,
    String? vaccineName,
    String? hospital,
    String? date,
    String? description,
    int? dose,
  }) {
    final vaccineController = TextEditingController(text: vaccineName ?? '');
    final hospitalController = TextEditingController(text: hospital ?? '');
    final detailController = TextEditingController(text: description ?? '');
    final doseController = TextEditingController(text: dose?.toString() ?? '');
    final dateController = TextEditingController(text: date ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appointment Details'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: vaccineController,
                  decoration: const InputDecoration(labelText: 'Vaccine Name'),
                ),
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(labelText: 'Hospital'),
                ),
                TextField(
                  controller: doseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dose / Total Dose',
                  ),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date & Time'),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      dateController.text = picked.toString().split(" ").first;
                    }
                  },
                ),
                TextField(
                  controller: detailController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () {
                final data = {
                  "vaccineName": vaccineController.text,
                  "hospital": hospitalController.text,
                  "dose": doseController.text,
                  "date": dateController.text,
                  "description": detailController.text,
                };
                print("Submitted: $data");

                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

void showAddAppointmentDialog(BuildContext context, {required Function onAppointmentAdded}) {
  final vaccineController = TextEditingController();
  final hospitalController = TextEditingController();
  final doseController = TextEditingController();
  final detailController = TextEditingController();
  final totalDoseController = TextEditingController();

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccine Name',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: vaccineController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6CC2A8),
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hospital',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: hospitalController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6CC2A8),
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dose',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: doseController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBBBBBB),
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBBBBBB),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Dose',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: totalDoseController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBBBBBB),
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBBBBBB),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selectedDate == null
                                                ? Color(0xFFBBBBBB)
                                                : Color(0xFF6CC2A8),
                                        width: selectedDate == null ? 1.0 : 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      selectedDate == null
                                          ? ''
                                          : DateFormat.yMMMMd().format(
                                              selectedDate!,
                                            ),
                                      style: TextStyle(
                                        color:
                                            selectedDate == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Time",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          selectedTime ?? TimeOfDay.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selectedTime == null
                                                ? Color(0xFFBBBBBB)
                                                : Color(0xFF6CC2A8),
                                        width: selectedTime == null ? 1.0 : 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      selectedTime == null
                                          ? ''
                                          : selectedTime!.format(context),
                                      style: TextStyle(
                                        color:
                                            selectedTime == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details (Optional)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            minLines: 3,
                            maxLines: 3,
                            controller: detailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CC2A8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (vaccineController.text.isEmpty ||
                      hospitalController.text.isEmpty ||
                      doseController.text.isEmpty ||
                      totalDoseController.text.isEmpty ||
                      selectedDate == null ||
                      selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in all required fields."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final appointmentDateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  final data = {
                    'vaccineName': vaccineController.text,
                    'location': hospitalController.text,
                    'dose': int.tryParse(doseController.text),
                    'totalDose': int.tryParse(totalDoseController.text),
                    'date': appointmentDateTime.toIso8601String(),
                    'description': detailController.text,
                  };
                  final String? uid = await getUserId();
                  final response = await http.post(
                    Uri.parse('${dotenv.env['API_URL']}/appointment?uid=$uid'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(data),
                  );
                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Appointment added successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                    onAppointmentAdded(); // Call the callback here
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to add appointment: ${response.body}",
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}