import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/history_record.dart';

void showHistoryDetailsDialog(
  BuildContext context, {
  required HistoryRecord history,
  required Function onHistoryUpdated,
}) {
  showDialog(
    context: context,
    builder: (context) {
      bool _isEditing = false;

      final vaccineController = TextEditingController(
        text: history.vaccineName,
      );
      final hospitalController = TextEditingController(text: history.location);
      final detailController = TextEditingController(text: history.description);
      final doseController = TextEditingController(
        text: history.dose.toString(),
      );
      final totalDoseController = TextEditingController(
        text: history.totalDose.toString(),
      );
      final diseaseController = TextEditingController(
        text: history.diseaseName,
      );
      final memberController = TextEditingController(text: history.memberName);

      DateTime? _selectedDate = DateTime.tryParse(history.date);
      TimeOfDay? _selectedTime =
          _selectedDate != null ? TimeOfDay.fromDateTime(_selectedDate) : null;

      final String originalVaccineName = history.vaccineName;
      final String originalHospital = history.location;
      final String originalDescription = history.description;
      final int originalDose = history.dose;
      final int? originalTotalDose = history.totalDose;
      final DateTime? originalSelectedDate = DateTime.tryParse(history.date);
      final TimeOfDay? originalSelectedTime =
          originalSelectedDate != null
              ? TimeOfDay.fromDateTime(originalSelectedDate)
              : null;
      final String originalDiseaseName = history.diseaseName;
      final String originalMemberName = history.memberName;
      final String? originalMemberId = history.memberId;

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

      String historyId = history.id;

      List<String> _diseases = [];
      bool _isLoadingDiseases = true;
      String? _diseaseError;

      List<Map<String, String>> _familyMembers = [];
      bool _isLoadingFamilyMembers = true;
      String? _familyMemberError;
      String? _selectedFamilyMemberId;

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

          Future<void> _fetchFamilyMembers() async {
            setState(() {
              _isLoadingFamilyMembers = true;
              _familyMemberError = null;
            });
            try {
              final String? uid = await getUserId();
              if (uid == null) {
                _familyMemberError = "User not logged in.";
                setState(() => _isLoadingFamilyMembers = false);
                return;
              }

              final response = await http.get(
                Uri.parse('${dotenv.env['API_URL']}/family/names?uid=$uid'),
                headers: {'Content-Type': 'application/json'},
              );

              if (response.statusCode == 200) {
                final Map<String, dynamic> responseData = jsonDecode(
                  response.body,
                );
                final List<dynamic> membersList =
                    responseData['members'] as List<dynamic>;

                _familyMembers =
                    membersList
                        .map(
                          (item) => {
                            '_id': item['id'].toString(),
                            'name': item['fullName'].toString(),
                          },
                        )
                        .toList();

                if (originalMemberId != null &&
                    _familyMembers.any((m) => m['_id'] == originalMemberId)) {
                  _selectedFamilyMemberId = originalMemberId;
                } else if (_familyMembers.isNotEmpty) {
                  final matchedMember = _familyMembers.firstWhere(
                    (m) => m['name'] == originalMemberName,
                    orElse: () => _familyMembers.first,
                  );
                  _selectedFamilyMemberId = matchedMember['_id'];
                }
              } else {
                _familyMemberError =
                    'Failed to load family members: ${response.statusCode}';
                print(
                  "Error fetching family members: ${response.statusCode} - ${response.body}",
                );
              }
            } catch (e) {
              _familyMemberError =
                  'Failed to connect to server to load family members.';
              print("Exception fetching family members: $e");
            } finally {
              setState(() {
                _isLoadingFamilyMembers = false;
              });
            }
          }

          if (_isEditing) {
            if (_isLoadingDiseases &&
                _diseases.isEmpty &&
                _diseaseError == null) {
              _fetchDiseases();
            }
            if (_isLoadingFamilyMembers &&
                _familyMembers.isEmpty &&
                _familyMemberError == null) {
              _fetchFamilyMembers();
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(25.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit History' : 'History Details',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6CC2A8)),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                        _fetchDiseases();
                        _fetchFamilyMembers();

                        _selectedDate = originalSelectedDate;
                        _selectedTime = originalSelectedTime;
                        _selectedFamilyMemberId = originalMemberId;
                        memberController.text = originalMemberName;
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

                    _buildFamilyMemberDropdown(
                      context,
                      'Family Member',
                      _isEditing,
                      _familyMembers,
                      _isLoadingFamilyMembers,
                      _familyMemberError,
                      _selectedFamilyMemberId,
                      (String? newValue) {
                        setState(() {
                          _selectedFamilyMemberId = newValue;

                          if (newValue != null) {
                            memberController.text =
                                _familyMembers.firstWhere(
                                  (m) => m['_id'] == newValue,
                                )['name'] ??
                                '';
                          } else {
                            memberController.text = '';
                          }
                        });
                      },
                      memberController.text,
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
                            displayValue: _formatDateForDisplay(_selectedDate),
                            isEditing: _isEditing,
                            onTap: () async {
                              print("Date field tapped!");
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            isDate: true,
                            selectedDate: _selectedDate,
                            selectedTime: _selectedTime,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateTimeRow(
                            context,
                            label: 'Time',
                            displayValue: _formatTimeForDisplay(_selectedTime),
                            isEditing: _isEditing,
                            onTap: () async {
                              print("Time field tapped!");
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                            isDate: false,
                            selectedDate: _selectedDate,
                            selectedTime: _selectedTime,
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
                            _selectedDate = originalSelectedDate;
                            _selectedTime = originalSelectedTime;
                            diseaseController.text = originalDiseaseName;
                            memberController.text = originalMemberName;
                            _selectedFamilyMemberId = originalMemberId;
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
                              _selectedDate == null ||
                              _selectedTime == null ||
                              diseaseController.text.isEmpty ||
                              _selectedFamilyMemberId == null) {
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

                          final updatedHistoryDateTime = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );

                          final updatedData = {
                            'vaccineName': vaccineController.text,
                            'location': hospitalController.text,
                            'dose': int.tryParse(doseController.text),
                            'totalDose': int.tryParse(totalDoseController.text),
                            'date': updatedHistoryDateTime.toIso8601String(),
                            'description': detailController.text,
                            'diseaseName': diseaseController.text,
                            'memberId': _selectedFamilyMemberId,
                            'memberName': memberController.text,
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
                                '${dotenv.env['API_URL']}/history/${history.id}?uid=$uid',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(updatedData),
                            );

                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "History updated successfully!",
                                  ),
                                  backgroundColor: Color(0xFF6CC2A8),
                                ),
                              );
                              Navigator.of(context).pop();
                              onHistoryUpdated();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed to update history: ${response.body}",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            print("Error updating history: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "An error occurred while updating history.",
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
                                  'Are you sure you want to delete your History?',
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
                                                  '${dotenv.env['API_URL']}/history/$historyId?uid=$uid',
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
                                                      "History deleted successfully!",
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF6CC2A8,
                                                    ),
                                                  ),
                                                );
                                                Navigator.of(context).pop();
                                                onHistoryUpdated();
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Failed to delete history: ${response.body}",
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                "Error deleting history: $e",
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "An error occurred while deleting history.",
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  behavior:
                                                      SnackBarBehavior.floating,
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
                    return diseases;
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
                      controller.text = value;
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
                  controller.text = selection;
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
                        width: MediaQuery.of(context).size.width * 0.7,
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

Widget _buildFamilyMemberDropdown(
  BuildContext context,
  String label,
  bool isEditing,
  List<Map<String, String>> familyMembers,
  bool isLoadingFamilyMembers,
  String? familyMemberError,
  String? selectedValue,
  ValueChanged<String?> onChanged,
  String displayValue,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (isEditing)
          isLoadingFamilyMembers
              ? const Center(child: CircularProgressIndicator())
              : familyMemberError != null
              ? Text(
                familyMemberError,
                style: const TextStyle(color: Colors.red),
              )
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6CC2A8),
                    width: 1.8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedValue,
                    hint: const Text('Select a family member'),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF6CC2A8),
                    ),
                    items:
                        familyMembers.map<DropdownMenuItem<String>>((
                          Map<String, String> member,
                        ) {
                          return DropdownMenuItem<String>(
                            value: member['_id'],
                            child: Text(
                              member['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              )
        else
          TextField(
            controller: TextEditingController(text: displayValue),
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
          child: AbsorbPointer(
            absorbing: !isEditing,
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: displayValue),
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
                suffixIcon:
                    isEditing
                        ? Icon(
                          isDate ? Icons.calendar_today : Icons.access_time,
                        )
                        : null,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
