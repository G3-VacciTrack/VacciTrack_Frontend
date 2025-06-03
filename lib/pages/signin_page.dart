import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:colorful_iconify_flutter/icons/logos.dart';

import 'main_page.dart';
import 'new_user_info_page.dart';
import 'signup_page.dart';
import '../services/auth_service.dart';

class SignInPage extends StatefulWidget {
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;
  bool _obscurePassword = true;

  Future<void> submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    setState(() {
      loading = true;
      error = '';
    });

    final result = await _authService.signInWithEmail(email, password);
    if (result['success']) {
      final isNew = result['isNewUser'] == true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isNew ? NewUserInfoPage() : MainPage(),
        ),
      );
    } else {
      setState(() {
        error = result['message'];
      });
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> handleGoogleSignIn() async {
    setState(() {
      loading = true;
      error = '';
    });

    final result = await _authService.signInWithGoogle();
    if (result['success']) {
      final isNew = result['isNewUser'] == true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isNew ? NewUserInfoPage() : MainPage(),
        ),
      );
    } else {
      setState(() {
        error = result['message'];
      });
    }

    setState(() {
      loading = false;
    });
  }

  InputDecoration textFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBBBBBB), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBBBBBB), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 440,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 94),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 31),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: const Color(0xFF33354C),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 93),
              Center(
                child: Container(
                  width: 338,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            color: const Color(0xFF33354C),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          decoration: textFieldDecoration().copyWith(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF6CC2A8),
                                width: 1.8,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (val) => email = val!.trim(),
                          validator:
                              (val) =>
                                  val != null && val.contains('@')
                                      ? null
                                      : 'Enter a valid email',
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Password',
                          style: TextStyle(
                            color: const Color(0xFF33354C),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          decoration: textFieldDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF6CC2A8),
                                width: 1.8,
                              ),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          onSaved: (val) => password = val!.trim(),
                          validator:
                              (val) =>
                                  val != null && val.length >= 6
                                      ? null
                                      : 'Password must be 6+ chars',
                        ),
                        SizedBox(height: 32),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              error,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        loading
                            ? Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6CC2A8),
                                minimumSize: Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              onPressed: submit,
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 20,
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  indent: 16,
                                  endIndent: 8,
                                ),
                              ),
                              const Text(
                                'Or',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  indent: 8,
                                  endIndent: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF6CC2A8)),
                            backgroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sign In with',
                                style: TextStyle(
                                  color: const Color(0xFF6CC2A8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Iconify(Logos.google, size: 20),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don’t have an account?',
                              style: TextStyle(
                                color: const Color(0xFF6F6F6F),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SignUpPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Register Now',
                                style: TextStyle(
                                  color: const Color(0xFF6CC2A8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ),
    );
  }
}
