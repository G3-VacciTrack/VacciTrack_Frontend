import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/appointment_record.dart'; 

void showAppointmentDetailsDialog(
  BuildContext context, {
  required AppointmentRecord appointment,
  required Function onAppointmentUpdated,
}) {
  showDialog(
    context: context,
    builder: (context) {
      bool _isEditing = false;

      final vaccineController = TextEditingController(
        text: appointment.vaccineName,
      );
      final hospitalController = TextEditingController(
        text: appointment.location,
      );
      final detailController = TextEditingController(
        text: appointment.description,
      );
      final doseController = TextEditingController(
        text: appointment.dose.toString(),
      );
      final totalDoseController = TextEditingController(
        text: appointment.totalDose?.toString() ?? '',
      );

      DateTime? selectedDate = DateTime.tryParse(appointment.date);
      TimeOfDay? selectedTime =
          selectedDate != null ? TimeOfDay.fromDateTime(selectedDate) : null;

      final String originalVaccineName = appointment.vaccineName;
      final String originalHospital = appointment.location;
      final String originalDescription = appointment.description ?? '';
      final int originalDose = appointment.dose;
      final int? originalTotalDose = appointment.totalDose;
      final DateTime? originalSelectedDate = DateTime.tryParse(
        appointment.date,
      );
      final TimeOfDay? originalSelectedTime =
          originalSelectedDate != null
              ? TimeOfDay.fromDateTime(originalSelectedDate)
              : null;

      Future<String?> getUserId() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('user_id');
      }

      String _formatDateForDisplay(DateTime? date) {
        return date == null ? '' : DateFormat.yMMMMd().format(date);
      }

      String _formatTimeForDisplay(TimeOfDay? time) {
        return time == null ? '' : time.format(context);
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(25.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.w500),),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6CC2A8)),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Vaccine Name',
                      vaccineController,
                      _isEditing,
                    ),
                    _buildDetailRow('Hospital', hospitalController, _isEditing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailRow(
                            'Dose',
                            doseController,
                            _isEditing,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetailRow(
                            'Total Dose',
                            totalDoseController,
                            _isEditing,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeRow(
                            context,
                            label: 'Date',
                            displayValue: _formatDateForDisplay(selectedDate),
                            isEditing: _isEditing,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            isDate: true,
                            selectedDate: selectedDate,
                            selectedTime: selectedTime,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateTimeRow(
                            context,
                            label: 'Time',
                            displayValue: _formatTimeForDisplay(selectedTime),
                            isEditing: _isEditing,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() => selectedTime = picked);
                              }
                            },
                            isDate: false,
                            selectedDate: selectedDate,
                            selectedTime: selectedTime,
                          ),
                        ),
                      ],
                    ),
                    _buildDetailRow(
                      'Details (Optional)',
                      detailController,
                      _isEditing,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      vaccineController.text = originalVaccineName;
                      hospitalController.text = originalHospital;
                      detailController.text = originalDescription;
                      doseController.text = originalDose.toString();
                      totalDoseController.text =
                          originalTotalDose?.toString() ?? '';
                      selectedDate = originalSelectedDate;
                      selectedTime = originalSelectedTime;
                    });
                  },
                  child: const Text('Cancel'),
                ),
              if (_isEditing)
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

                    final updatedAppointmentDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    final updatedData = {
                      'vaccineName': vaccineController.text,
                      'location': hospitalController.text,
                      'dose': int.tryParse(doseController.text),
                      'totalDose': int.tryParse(totalDoseController.text),
                      'date': updatedAppointmentDateTime.toIso8601String(),
                      'description': detailController.text,
                    };

                    final String? uid = await getUserId();
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("User not logged in."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    try {
                      final response = await http.put(
                        Uri.parse(
                          '${dotenv.env['API_URL']}/appointment/${appointment.id}?uid=$uid',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(updatedData),
                      );

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Appointment updated successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop();
                        onAppointmentUpdated();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to update appointment: ${response.body}",
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      print("Error updating appointment: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "An error occurred while updating appointment.",
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              if (!_isEditing)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildDetailRow(
  String label,
  TextEditingController controller,
  bool isEditing, {
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !isEditing, 
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isEditing
                        ? const Color(0xFF6CC2A8)
                        : const Color(0xFFBBBBBB),
                width: isEditing ? 1.8 : 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isEditing
                        ? const Color(0xFF6CC2A8)
                        : const Color(0xFFBBBBBB),
                width: isEditing ? 1.8 : 1.2,
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
  );
}

Widget _buildDateTimeRow(
  BuildContext context, {
  required String label,
  required String displayValue,
  required bool isEditing,
  required VoidCallback onTap,
  required bool isDate,
  DateTime? selectedDate,
  TimeOfDay? selectedTime,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isEditing ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48, 
            alignment: Alignment.centerLeft,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isEditing
                        ? const Color(0xFF6CC2A8)
                        : (isDate
                            ? (selectedDate == null
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFFBBBBBB))
                            : (selectedTime == null
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFFBBBBBB))),
                width: isEditing ? 1.8 : 1.2,
              ),
            ),
            child: Text(
              displayValue.isEmpty
                  ? (isEditing ? 'Tap to select' : 'N/A')
                  : displayValue,
              style: TextStyle(
                color: displayValue.isEmpty ? Colors.grey[600] : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
