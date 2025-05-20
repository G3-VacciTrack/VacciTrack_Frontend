import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class PersonalInfoPage extends StatefulWidget {
  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  int age = 0;
  String gender = 'Male';
  String responseMessage = '';
  static const String baseUrl = 'http://192.168.1.207:3001/api';

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();
    final uid = await getUserId();
    final url = Uri.parse(
      '$baseUrl/user/info?uid=${uid}&firstName=${firstName}&lastName=${lastName}&age=${age}&gender=${gender}',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
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
                validator:
                    (val) =>
                        val != null && val.isNotEmpty
                            ? null
                            : 'Enter first name',
                onSaved: (val) => firstName = val!.trim(),
              ),
              SizedBox(height: 12),

              // Last Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val != null && val.isNotEmpty
                            ? null
                            : 'Enter last name',
                onSaved: (val) => lastName = val!.trim(),
              ),
              SizedBox(height: 12),

              // Age and Gender in the same row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n <= 0) return 'Enter valid age';
                        return null;
                      },
                      onSaved: (val) => age = int.tryParse(val ?? '') ?? 0,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          ['Male', 'Female']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? 'Select gender'
                                  : null,
                      onChanged: (val) => gender = val ?? gender,
                      onSaved: (val) => gender = val ?? gender,
                    ),
                  ),
                ],
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
