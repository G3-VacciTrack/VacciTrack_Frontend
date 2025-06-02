import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/signin_page.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';
  late Future<Map<String, dynamic>?> futureUser;
  String? email;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('did');
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => SignInPage()));
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

  Widget buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6F6F6F),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget buildFamilyCard(String name, String age) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 12),
              ),
              Text(
                'Dummy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Age',
                style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 12),
              ),
              Text(
                '21',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: futureUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text('Failed to load user info.'));
            } else {
              final user = snapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 5.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF33354C),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            tooltip: 'Sign Out',
                            onPressed: () => _signOut(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 330,
                          child: Column(
                            children: [
                              buildProfileRow(
                                'Name',
                                '${user['fistName'] ?? ''} ${user['lastName'] ?? ''}',
                              ),
                              buildProfileRow(
                                'Age',
                                user['age']?.toString() ?? '-',
                              ),
                              buildProfileRow('Birthday', user['dob'] ?? '-'),
                              buildProfileRow('Gender', user['gender'] ?? '-'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Family',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF33354C),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Member',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF69C6AC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildFamilyCard('Chawisa', '21'),
                      buildFamilyCard('Chawisa', '21'),
                      buildFamilyCard('Chawisa', '21'),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
