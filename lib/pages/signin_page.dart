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
            builder: (_) => isNew ? NewUserInfoPage() : MainPage()),
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
            builder: (_) => isNew ? NewUserInfoPage() : MainPage()),
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
                validator: (val) =>
                    val != null && val.contains('@') ? null : 'Enter a valid email',
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (val) => password = val!.trim(),
                validator: (val) =>
                    val != null && val.length >= 6 ? null : 'Password must be 6+ chars',
              ),
              SizedBox(height: 20),
              loading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
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
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SignUpPage()));
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
                  onPressed: handleGoogleSignIn,
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
