import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FamilyDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> familyMember;
  final VoidCallback? onFamilyMemberUpdated;

  const FamilyDetailsDialog({
    super.key,
    required this.familyMember,
    this.onFamilyMemberUpdated,
  });

  @override
  State<FamilyDetailsDialog> createState() => _FamilyDetailsDialogState();
}

class _FamilyDetailsDialogState extends State<FamilyDetailsDialog> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  DateTime? _selectedDob;
  String? _selectedGender;
  late int _initialAge;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.familyMember['firstName'],
    );
    _lastNameController = TextEditingController(
      text: widget.familyMember['lastName'],
    );

    if (widget.familyMember['dob'] != null) {
      try {
        if (widget.familyMember['dob'] is String) {
          _selectedDob = DateFormat(
            'd MMMM yyyy',
          ).parse(widget.familyMember['dob']);
        } else if (widget.familyMember['dob'] is Map &&
            widget.familyMember['dob']['_seconds'] != null) {
          _selectedDob = DateTime.fromMillisecondsSinceEpoch(
            widget.familyMember['dob']['_seconds'] * 1000,
          );
        }
      } catch (e) {
        print('Error parsing DOB: ${widget.familyMember['dob']} - $e');
        _selectedDob = null;
      }
    }

    _selectedGender = widget.familyMember['gender'];
    _initialAge = widget.familyMember['age'] ?? 'N/A';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _updateFamilyMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String? uid = await getUserId();
    final String? memberId = widget.familyMember['id'];

    if (uid == null || memberId == null) {
      _showSnackBar("Error: User or member ID is missing.", Colors.redAccent);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseUrl/family/update/$memberId?uid=$uid');
    final updatedData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'dob': _selectedDob?.toIso8601String(),
      'gender': _selectedGender,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Family member updated successfully!", Color(0xFF6CC2A8));
        setState(() {
          _isEditing = false;

          widget.onFamilyMemberUpdated?.call();
        });
      } else {
        _showSnackBar(
          "Failed to update: ${json.decode(response.body)['message'] ?? response.statusCode}",
          Colors.redAccent,
        );
      }
    } catch (e) {
      print('Error updating family member: $e');
      _showSnackBar("An error occurred during update.", Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFamilyMember() async {
    setState(() {
      _isLoading = true;
    });

    final String? uid = await getUserId();
    final String? memberId = widget.familyMember['id'];

    if (uid == null || memberId == null) {
      _showSnackBar("Error: User or member ID is missing.", Colors.redAccent);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseUrl/family/delete/$memberId?uid=$uid');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showSnackBar("Family member deleted successfully!", Color(0xFF6CC2A8));
        Navigator.of(context).pop();
        widget.onFamilyMemberUpdated?.call();
      } else {
        _showSnackBar(
          "Failed to delete: ${json.decode(response.body)['message'] ?? response.statusCode}",
          Colors.redAccent,
        );
      }
    } catch (e) {
      print('Error deleting family member: $e');
      _showSnackBar("An error occurred during deletion.", Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    int? currentAge;
    if (_selectedDob != null) {
      final now = DateTime.now();
      currentAge = now.year - _selectedDob!.year;
      if (now.month < _selectedDob!.month ||
          (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
        currentAge--;
      }
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isEditing ? 'Edit Member' : 'Member Details',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputField(
                        label: 'First Name',
                        controller: _firstNameController,
                        readOnly: !_isEditing,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'First Name cannot be empty'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        readOnly: !_isEditing,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Last Name cannot be empty'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePickerField(
                        context: context,
                        label: 'Date of Birth',
                        selectedDate: _selectedDob,
                        readOnly: !_isEditing,
                        onTap:
                            _isEditing
                                ? () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDob ?? DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (pickedDate != null &&
                                      pickedDate != _selectedDob) {
                                    setState(() {
                                      _selectedDob = pickedDate;
                                    });
                                  }
                                }
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Age:',
                        currentAge?.toString() ?? _initialAge.toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildGenderDropdown(
                        selectedGender: _selectedGender,
                        readOnly: !_isEditing,
                        onChanged:
                            _isEditing
                                ? (String? newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                }
                                : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6CC2A8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (_isEditing) {
                    setState(() {
                      _isEditing = false;

                      _firstNameController.text =
                          widget.familyMember['firstName'] ?? '';
                      _lastNameController.text =
                          widget.familyMember['lastName'] ?? '';
                      if (widget.familyMember['dob'] != null &&
                          widget.familyMember['dob'] is String) {
                        try {
                          _selectedDob = DateFormat(
                            'd MMMM yyyy',
                          ).parse(widget.familyMember['dob']);
                        } catch (e) {
                          _selectedDob = null;
                        }
                      } else {
                        _selectedDob = null;
                      }
                      _selectedGender = widget.familyMember['gender'];
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  _isEditing ? 'Cancel' : 'Close',
                  style: const TextStyle(color: Color(0xFF6CC2A8)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CC2A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          if (_isEditing) {
                            _updateFamilyMember();
                          } else {
                            _deleteFamilyMember();
                          }
                        },
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(_isEditing ? 'Save' : 'Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6CC2A8), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    DateTime? selectedDate,
    required bool readOnly,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF6CC2A8),
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? ''
                      : DateFormat.yMMMMd().format(selectedDate),
                  style: TextStyle(color: Colors.black),
                ),
                if (!readOnly) const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown({
    required String? selectedGender,
    required bool readOnly,
    ValueChanged<String?>? onChanged,
  }) {
    final List<String> genders = ['Male', 'Female'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: Color(0xFF33354C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedGender,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6CC2A8), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items:
              genders.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
          onChanged: readOnly ? null : onChanged,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF33354C),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF6F6F6F)),
            ),
          ),
        ],
      ),
    );
  }
}
