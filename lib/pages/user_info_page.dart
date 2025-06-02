import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3001/api';
  late Future<Map<String, dynamic>?> futureUser;
  String? email;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<Map<String, dynamic>?> fetchUserInfo() async {
    final uid = await getUserId();
    if (uid == null) return null;

    final url = Uri.parse('$baseUrl/user/info?uid=$uid');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['user'] != null) {
          return jsonResponse['user'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    futureUser = fetchUserInfo();
    email = FirebaseAuth.instance.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Failed to load user info.'));
          } else {
            final user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('First Name: ${user['fistName'] ?? '-'}'),
                  Text('Last Name: ${user['lastName'] ?? '-'}'),
                  Text('Email: ${email ?? '-'}'),
                  Text('Date of Birth: ${user['dob'] ?? '-'}'),
                  Text('Age: ${user['age'] ?? '-'}'),
                  Text('Gender: ${user['gender'] ?? '-'}'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}