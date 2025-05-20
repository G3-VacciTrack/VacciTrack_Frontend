import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:colorful_iconify_flutter/icons/logos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'signup_page.dart';
import 'personal_info_page.dart';
import 'home_page.dart';

class SignInPage extends StatefulWidget {
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  static const String baseUrl = 'http://192.168.1.207:3001/api';

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  Future<void> saveUserId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;
        await saveUserId(uid);

        // Call backend to check if user is new
        final url = Uri.parse('$baseUrl/user/validate?uid=$uid');
        final response = await http.get(
          url,
          headers: {'Content-Type': 'application/json'},
        );

        bool isNewUser = false;
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          isNewUser = jsonResponse['status'] == true;
        } else {
          isNewUser = true;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isNewUser ? PersonalInfoPage() : Home(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Google sign-in failed';
      });
    } catch (e, stackTrace) {
      setState(() {
        error = 'Unexpected error: $e';
      });
      print("Google sign-in error: $e");
      print("Stack trace: $stackTrace");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    setState(() {
      loading = true;
      error = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await saveUserId(userCredential.user!.uid);
        final url = Uri.parse(
          '$baseUrl/user/validate?uid=${userCredential.user!.uid}',
        );
        final response = await http.get(
          url,
          headers: {'Content-Type': 'application/json'},
        );
        bool isNewUser = false;
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          setState(() {
            isNewUser = jsonResponse['status'];
          });
        } else {
          isNewUser = true;
        }
        if (isNewUser) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => PersonalInfoPage()),
          );
        } else {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => Home()));
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Authentication error';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (error.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.red[200],
                  child: Text(error, style: TextStyle(color: Colors.red[900])),
                ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => email = val!.trim(),
                validator:
                    (val) =>
                        val != null && val.contains('@')
                            ? null
                            : 'Enter a valid email',
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (val) => password = val!.trim(),
                validator:
                    (val) =>
                        val != null && val.length >= 6
                            ? null
                            : 'Password must be 6+ chars',
              ),
              SizedBox(height: 20),
              loading
                  ? CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    height:
                        50, // for a square button, set height = width (or choose a fixed height)
                    child: ElevatedButton(
                      onPressed: submit,
                      child: Text('Sign In'),
                    ),
                  ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => SignUpPage()));
                    },
                    child: Text('Register now'),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => signInWithGoogle(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign In with',
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(width: 8),
                      Iconify(Logos.google, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
