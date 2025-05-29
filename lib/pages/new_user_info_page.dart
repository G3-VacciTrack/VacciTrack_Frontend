import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'home_page.dart';

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
          MaterialPageRoute(builder: (context) => HomePage()),
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
      appBar: AppBar(title: Text('Personal Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Please complete your personal info',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),

              // First Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Enter first name',
                onSaved: (val) => firstName = val!.trim(),
              ),
              SizedBox(height: 12),

              // Last Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Enter last name',
                onSaved: (val) => lastName = val!.trim(),
              ),
              SizedBox(height: 12),

              // Date of Birth Picker
              InkWell(
                onTap: () => _selectDOB(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    dob != null
                        ? "${dob!.day}/${dob!.month}/${dob!.year}"
                        : 'Select Date of Birth',
                    style: TextStyle(
                      color: dob != null ? Colors.black : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select gender' : null,
                onChanged: (val) => gender = val ?? gender,
                onSaved: (val) => gender = val ?? gender,
              ),
              SizedBox(height: 20),

              ElevatedButton(onPressed: _submit, child: Text('Submit')),

              if (responseMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    responseMessage,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
