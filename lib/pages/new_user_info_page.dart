import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'main_page.dart';

class NewUserInfoPage extends StatefulWidget {
  @override
  State<NewUserInfoPage> createState() => _NewUserInfoPageState();
}

class _NewUserInfoPageState extends State<NewUserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String gender = 'Male';
  String responseMessage = '';
  DateTime? dob;

  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();

    if (form == null || !form.validate()) return;

    if (dob == null) {
      setState(() {
        responseMessage = 'Please select your date of birth.';
      });
      return;
    }

    form.save();
    final uid = await getUserId();
    final url = Uri.parse('$baseUrl/user/info?uid=$uid');
    final Map<String, dynamic> requestBody = {
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob!.toIso8601String(),
      'gender': gender,
      'token': token,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        setState(() {
          responseMessage = 'Failed (${response.statusCode}): ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Error sending request: $e';
      });
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(31, 94, 31, 24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Info',
                style: TextStyle(
                  color: Color(0xFF33354C),
                  fontSize: 32,
                  fontFamily: 'Noto Sans Bengali',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 60),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabeledTextField('First Name', onSaved: (val) => firstName = val!, validator: (val) => val != null && val.isNotEmpty ? null : 'Enter first name'),
                    const SizedBox(height: 24),
                    _buildLabeledTextField('Last Name', onSaved: (val) => lastName = val!, validator: (val) => val != null && val.isNotEmpty ? null : 'Enter last name'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildDOBField(context)),
                        SizedBox(width: 16),
                        Expanded(child: _buildGenderDropdown())
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Color(0xFFBBBBBB)),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Policy, PDPA ',
                                style: TextStyle(
                                  color: Color(0xFF33354C),
                                  fontSize: 15,
                                  fontFamily: 'Noto Sans Bengali',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Ipsum is simply dummy text of the printing and typesetting industry.',
                                style: TextStyle(
                                  color: Color(0xFF6F6F6F),
                                  fontSize: 11,
                                  fontFamily: 'Noto Sans Bengali',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    loadingButton(),
                    if (responseMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          responseMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(String label, {required FormFieldSetter<String> onSaved, required FormFieldValidator<String> validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 15.93,
            fontFamily: 'Noto Sans Bengali',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onSaved: onSaved,
          validator: validator,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFFBBBBBB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFFBBBBBB), width: 1.5),
            ),
            
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDOBField(BuildContext context) {
    return SizedBox(
      width: 137,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Age',
            style: TextStyle(
              color: Color(0xFF33354C),
              fontSize: 15.93,
              fontFamily: 'Noto Sans Bengali',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDOB(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBBBBBB), width: 1.2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                dob != null ? "${dob!.day}/${dob!.month}/${dob!.year}" : 'Select Date',
                style: TextStyle(
                  color: dob != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return SizedBox(
      width: 137,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(
              color: Color(0xFF33354C),
              fontSize: 15.93,
              fontFamily: 'Noto Sans Bengali',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: gender,
            items: ['Male', 'Female']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => gender = val ?? gender),
            onSaved: (val) => gender = val ?? gender,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFFBBBBBB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFFBBBBBB), width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFFBBBBBB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF6CC2A8),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Submit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Noto Sans Bengali',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
