import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/signin_page.dart';
import '../components/custom_family_card.dart';
import '../components/custom_family_detail_dialog.dart';
import '../components/custom_create_family_dialog.dart'; 

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  late Future<Map<String, dynamic>?> futureUser;
  late Future<List<Map<String, dynamic>>> futureFamily;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    futureUser = fetchUserInfo();
    futureFamily = fetchFamilyInfo();
  }

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
    if (uid == null) {
      print('User ID is null, cannot fetch user info.');
      return null;
    }

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
      } else {
        print('Failed to load user info: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFamilyInfo() async {
    final uid = await getUserId();
    if (uid == null) {
      print('User ID is null, cannot fetch family info.');
      return [];
    }

    final url = Uri.parse('$baseUrl/family/all?uid=$uid');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['members'] != null &&
            jsonResponse['members'] is List) {
          return List<Map<String, dynamic>>.from(jsonResponse['members']);
        }
      } else {
        print('Failed to load family info: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error fetching family info: $e');
      return [];
    }
  }

  Widget buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6F6F6F),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  
  void _showFamilyMemberDetailsDialog(
    BuildContext context,
    Map<String, dynamic> familyMember,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return FamilyDetailsDialog(
          familyMember: familyMember,
          onFamilyMemberUpdated: () {
            setState(() {
              futureFamily = fetchFamilyInfo();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: futureUser,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.data == null) {
                return const Center(
                  child: Text('Failed to load user info or user not found.'),
                );
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
                              icon: const Icon(Icons.logout, size: 28),
                              tooltip: 'Sign Out',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actionsPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 8.0,
                                          ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        24.0,
                                        10,
                                        24.0,
                                        0.0,
                                      ),
                                      actions: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    side: const BorderSide(
                                                      color: Color(0xFF6CC2A8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Color(0xFF6CC2A8),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pop(); 
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: const Color(
                                                      0xFF6CC2A8,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Logout',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pop(); 
                                                    _signOut(
                                                      context,
                                                    ); 
                                                  },
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 330,
                            child: Column(
                              children: [
                                buildProfileRow(
                                  'Name',
                                  '${user['fistName'] ?? ''} ${user['lastName'] ?? ''}',
                                ),
                                const SizedBox(height: 8),
                                buildProfileRow(
                                  'Age',
                                  user['age']?.toString() ?? '-',
                                ),
                                const SizedBox(height: 8),
                                buildProfileRow('Birthday', user['dob'] ?? '-'),
                                const SizedBox(height: 8),
                                buildProfileRow(
                                  'Gender',
                                  user['gender'] ?? '-',
                                ),
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
                              onPressed: () async {
                                final bool?
                                memberAdded = await showDialog<bool?>(
                                  context: context,
                                  builder:
                                      (context) =>
                                          const AddFamilyMemberDialog(), 
                                );
                                if (memberAdded == true) {
                                  setState(() {
                                    futureFamily = fetchFamilyInfo();
                                  });
                                }
                              },
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
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureFamily,
                          builder: (context, familySnapshot) {
                            if (familySnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (familySnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading family: ${familySnapshot.error}',
                                ),
                              );
                            } else if (familySnapshot.data == null ||
                                familySnapshot.data!.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons
                                            .people_alt, 
                                        size: 48.0, 
                                        color: const Color.fromARGB(
                                          255,
                                          186,
                                          235,
                                          221,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 8.0,
                                      ), 
                                      Text(
                                        'No member found', 
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color:
                                              Colors
                                                  .grey[600], 
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: familySnapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final familyMember =
                                      familySnapshot.data![index];
                                  return FamilyCard(
                                    familyMember: familyMember,
                                    onTap: () {
                                      _showFamilyMemberDetailsDialog(
                                        context,
                                        familyMember,
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Vaccitrack Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF33354C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Need assistance? Don’t hesitate to reach out to our support team—we’re here to help you with any questions, issues, or guidance you may need.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6F6F6F),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            buildProfileRow('Email', 'support@vaccitrack.com'),
                            const SizedBox(height: 8),
                            buildProfileRow('Phone', '+1 (123) 456-7890'),
                            const SizedBox(height: 8),
                            buildProfileRow('Website', 'www.vaccitrack.com'),
                            const SizedBox(height: 8),
                            buildProfileRow(
                              'Location',
                              '123 Vaccine St, Health City, Global',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
