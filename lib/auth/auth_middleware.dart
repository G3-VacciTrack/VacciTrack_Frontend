import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/home_page.dart';
import '../pages/signin_page.dart';
import '../pages/personal_info_page.dart';

class AuthMiddleware extends StatefulWidget {
  @override
  _AuthMiddlewareState createState() => _AuthMiddlewareState();
}

class _AuthMiddlewareState extends State<AuthMiddleware> {
  static const String baseUrl = 'http://192.168.1.207:3001/api';
  late Future<Widget> _pageToShow;

  @override
  void initState() {
    super.initState();
    _pageToShow = validateNewUser();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<Widget> validateNewUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return SignInPage();

    final uid = user.uid;

    final url = Uri.parse('$baseUrl/user/validate?uid=$uid');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final bool isNewUser = jsonResponse['status'] == true;

        return isNewUser ? PersonalInfoPage() : Home();
      } else {
        return Home();
      }
    } catch (e) {
      print('Error sending request: $e');
      return SignInPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _pageToShow,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Something went wrong')));
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}
