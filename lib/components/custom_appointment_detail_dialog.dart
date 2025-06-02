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
        text: appointment.totalDose.toString(),
      );
      final diseaseController = TextEditingController(
        text: appointment.diseaseName,
      );

      DateTime? selectedDate = DateTime.tryParse(appointment.date);
      TimeOfDay? selectedTime =
          selectedDate != null ? TimeOfDay.fromDateTime(selectedDate) : null;

      final String originalVaccineName = appointment.vaccineName;
      final String originalHospital = appointment.location;
      final String originalDescription = appointment.description;
      final int originalDose = appointment.dose;
      final int? originalTotalDose = appointment.totalDose;
      final DateTime? originalSelectedDate = DateTime.tryParse(
        appointment.date,
      );
      final TimeOfDay? originalSelectedTime =
          originalSelectedDate != null
              ? TimeOfDay.fromDateTime(originalSelectedDate)
              : null;
      final String originalDiseaseName =
          appointment.diseaseName;

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

      String appointmentId = appointment.id;

      List<String> _diseases = [];
      bool _isLoadingDiseases = true;
      String? _diseaseError;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> _fetchDiseases() async {
            setState(() {
              _isLoadingDiseases = true;
              _diseaseError = null;
            });
            try {
              final response = await http.get(
                Uri.parse('${dotenv.env['API_URL']}/disease/all'),
                headers: {'Content-Type': 'application/json'},
              );

              if (response.statusCode == 200) {
                final Map<String, dynamic> responseData = jsonDecode(
                  response.body,
                );
                final List<dynamic> diseaseList =
                    responseData['disease'] as List<dynamic>;
                _diseases = diseaseList.map((item) => item.toString()).toList();
              } else {
                _diseaseError =
                    'Failed to load diseases: ${response.statusCode}';
                print(
                  "Error fetching diseases: ${response.statusCode} - ${response.body}",
                );
              }
            } catch (e) {
              _diseaseError = 'Failed to connect to server to load diseases.';
              print("Exception fetching diseases: $e");
            } finally {
              setState(() {
                _isLoadingDiseases = false;
              });
            }
          }

          if (_isEditing &&
              _isLoadingDiseases &&
              _diseases.isEmpty &&
              _diseaseError == null) {
            _fetchDiseases();
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(25.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6CC2A8)),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                        _fetchDiseases();
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
                    _buildDiseaseDetailRow(
                      context,
                      'Disease',
                      diseaseController,
                      _isEditing,
                      _diseases,
                      _isLoadingDiseases,
                      _diseaseError,
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF6CC2A8)),
                        ),
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
                            diseaseController.text =
                                originalDiseaseName;
                          });
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF6CC2A8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
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
                              selectedTime == null ||
                              diseaseController
                                  .text
                                  .isEmpty
                                  ) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please fill in all required fields.",
                                ),
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
                            'date':
                                updatedAppointmentDateTime.toIso8601String(),
                            'description': detailController.text,
                            'diseaseName':
                                diseaseController.text,
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
                                  content: Text(
                                    "Appointment updated successfully!",
                                  ),
                                  backgroundColor: Color(0xFF6CC2A8),
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
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              if (!_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF6CC2A8)),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6CC2A8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6CC2A8),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  'Are you sure you want to delete your Appointment?',
                                  style: TextStyle(fontSize: 18),
                                ),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFF7797B),
                                            ),
                                          ),
                                          child: const Text(
                                            'No',
                                            style: TextStyle(
                                              color: Color(0xFFF7797B),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();

                                            final String? uid =
                                                await getUserId();
                                            if (uid == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "User not logged in.",
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                              return;
                                            }

                                            try {
                                              final response = await http.delete(
                                                Uri.parse(
                                                  '${dotenv.env['API_URL']}/appointment/$appointmentId?uid=$uid',
                                                ),
                                                headers: {
                                                  'Content-Type':
                                                      'application/json',
                                                },
                                              );

                                              if (response.statusCode == 200) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Appointment deleted successfully!",
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF6CC2A8,
                                                    ),
                                                  ),
                                                );
                                                Navigator.of(context).pop();
                                                onAppointmentUpdated();
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Failed to delete appointment: ${response.body}",
                                                    ),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                "Error deleting appointment: $e",
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "An error occurred while deleting appointment.",
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFF7797B,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Yes'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
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

Widget _buildDiseaseDetailRow(
  BuildContext context,
  String label,
  TextEditingController controller,
  bool isEditing,
  List<String> diseases,
  bool isLoadingDiseases,
  String? diseaseError,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (isEditing)
          isLoadingDiseases
              ? const Center(child: CircularProgressIndicator())
              : diseaseError != null
              ? Text(diseaseError, style: const TextStyle(color: Colors.red))
              : Autocomplete<String>(
                initialValue: TextEditingValue(text: controller.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return diseases.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  controller.text = textEditingController.text;
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                      controller.text =
                          value;
                    },
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF6CC2A8),
                          width: 1.8,
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (String selection) {
                  controller.text =
                      selection;
                  FocusScope.of(context).unfocus();
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width:
                            MediaQuery.of(context).size.width *
                            0.7,
                        height: 300,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return GestureDetector(
                              onTap: () {
                                onSelected(option);
                              },
                              child: ListTile(title: Text(option)),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )
        else
          TextField(
            controller: controller,
            readOnly: true,
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
              focusedBorder: OutlineInputBorder(
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
