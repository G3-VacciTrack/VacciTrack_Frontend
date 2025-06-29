import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void showHistoryDetailsDialog(
  BuildContext context, {
  required Function onHistoryAdded,
}) {
  final vaccineController = TextEditingController();
  final hospitalController = TextEditingController();
  final doseController = TextEditingController();
  final detailController = TextEditingController();
  final totalDoseController = TextEditingController();
  final diseaseController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<String> _diseases = [];
  bool _isLoadingDiseases = true;
  String? _diseaseError;

  List<Map<String, String>> _familyMembers = [];
  bool _isLoadingFamilyMembers = true;
  String? _familyMemberError;
  String? _selectedFamilyMemberId;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  showDialog(
    context: context,
    builder: (context) {
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

          Future<void> _fetchFamilyMemberNames() async {
            setState(() {
              _isLoadingFamilyMembers = true;
              _familyMemberError = null;
            });
            final uid = await getUserId();
            if (uid == null) {
              _familyMemberError = "User not logged in.";
              setState(() {
                _isLoadingFamilyMembers = false;
              });
              return;
            }

            try {
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

                if (_familyMembers.isNotEmpty) {
                  _selectedFamilyMemberId = _familyMembers.first['_id'];
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

          if (_isLoadingDiseases &&
              _diseases.isEmpty &&
              _diseaseError == null) {
            _fetchDiseases();
          }
          if (_isLoadingFamilyMembers &&
              _familyMembers.isEmpty &&
              _familyMemberError == null) {
            _fetchFamilyMemberNames();
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Add History',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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
                            'Disease',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _isLoadingDiseases
                              ? const Center(child: CircularProgressIndicator())
                              : _diseaseError != null
                              ? Text(
                                _diseaseError!,
                                style: const TextStyle(color: Colors.red),
                              )
                              : Autocomplete<String>(
                                optionsBuilder: (
                                  TextEditingValue textEditingValue,
                                ) {
                                  if (textEditingValue.text.isEmpty) {
                                    return _diseases;
                                  }
                                  return _diseases.where((String option) {
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
                                  diseaseController.text =
                                      textEditingController.text;
                                  return TextField(
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    onSubmitted: (String value) {
                                      onFieldSubmitted();
                                      diseaseController.text = value;
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                  diseaseController.text = selection;
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
                                            0.66,
                                        height: 300,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.all(8.0),
                                          itemCount: options.length,
                                          itemBuilder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            final String option = options
                                                .elementAt(index);
                                            return GestureDetector(
                                              onTap: () {
                                                onSelected(option);
                                              },
                                              child: ListTile(
                                                title: Text(option),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Family Member',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          _isLoadingFamilyMembers
                              ? const Center(child: CircularProgressIndicator())
                              : _familyMemberError != null
                              ? Text(
                                _familyMemberError!,
                                style: const TextStyle(color: Colors.red),
                              )
                              : DropdownButtonFormField<String>(
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF33354C),
                                ),
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
                                value: _selectedFamilyMemberId,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedFamilyMemberId = newValue;
                                  });
                                },
                                items:
                                    _familyMembers
                                        .map<DropdownMenuItem<String>>((
                                          Map<String, String> member,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: member['_id'],
                                            child: Text(member['name']!),
                                          );
                                        })
                                        .toList(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a family member';
                                  }
                                  return null;
                                },
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
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6CC2A8),
                                        width: 1.8,
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
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6CC2A8),
                                        width: 1.8,
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
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    height: 48,
                                    alignment: Alignment.centerLeft,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            selectedDate == null
                                                ? const Color(0xFFBBBBBB)
                                                : const Color(0xFF6CC2A8),
                                        width: selectedDate == null ? 1.2 : 1.8,
                                      ),
                                    ),
                                    child: Text(
                                      selectedDate == null
                                          ? 'Select Date'
                                          : DateFormat.yMMMMd().format(
                                            selectedDate!,
                                          ),
                                      style: TextStyle(
                                        color:
                                            selectedDate == null
                                                ? Colors.grey[600]
                                                : const Color(0xFF33354C),
                                        fontSize: 14,
                                      ),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                                    ),
                                    height: 48,
                                    alignment: Alignment.centerLeft,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            selectedTime == null
                                                ? const Color(0xFFBBBBBB)
                                                : const Color(0xFF6CC2A8),
                                        width: selectedTime == null ? 1.2 : 1.8,
                                      ),
                                    ),
                                    child: Text(
                                      selectedTime == null
                                          ? 'Select Time'
                                          : selectedTime!.format(context),
                                      style: TextStyle(
                                        color:
                                            selectedTime == null
                                                ? Colors.grey[600]
                                                : const Color(0xFF33354C),
                                        fontSize: 14,
                                      ),
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
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF6CC2A8)),
                        ),
                        child: const Text(
                          'Cancel',
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
                          if (_selectedFamilyMemberId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a family member."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          if (vaccineController.text.isEmpty ||
                              hospitalController.text.isEmpty ||
                              doseController.text.isEmpty ||
                              totalDoseController.text.isEmpty ||
                              selectedDate == null ||
                              selectedTime == null ||
                              diseaseController.text.isEmpty) {
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

                          final historyDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );

                          final name =
                              _familyMembers.firstWhere(
                                (member) =>
                                    member['_id'] == _selectedFamilyMemberId,
                                orElse: () => {'name': 'Unknown'},
                              )['name'];
                          if (name == 'Unknown') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Selected family member not found.",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final data = {
                            'memberName': name,
                            'vaccineName': vaccineController.text,
                            'location': hospitalController.text,
                            'dose': int.tryParse(doseController.text),
                            'totalDose': int.tryParse(totalDoseController.text),
                            'date': historyDateTime.toIso8601String(),
                            'description': detailController.text,
                            'diseaseName': diseaseController.text,
                          };

                          final String? uid = await getUserId();
                          final response = await http.post(
                            Uri.parse(
                              '${dotenv.env['API_URL']}/history?uid=$uid',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode(data),
                          );

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("History added successfully!"),
                                backgroundColor: Color(0xFF6CC2A8),
                              ),
                            );
                            Navigator.of(context).pop();
                            onHistoryAdded();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Failed to add history: ${response.body}",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
