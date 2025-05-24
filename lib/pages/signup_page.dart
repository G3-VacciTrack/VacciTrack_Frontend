import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';
  bool loading = false;

  Future<void> submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    if (password != confirmPassword) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    final result = await _authService.registerWithEmail(email, password);

    if (result == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => error = result);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create your new account')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (error.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.red[200],
                        child: Text(error, style: TextStyle(color: Colors.red[900])),
                      ),
                    SizedBox(height: 20),

                    // Email
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => email = val!.trim(),
                      validator: (val) =>
                          val != null && val.contains('@') ? null : 'Enter a valid email',
                    ),
                    SizedBox(height: 20),

                    // Password
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                      onSaved: (val) => password = val!.trim(),
                      validator: (val) =>
                          val != null && val.length >= 6 ? null : 'Password must be 6+ chars',
                    ),
                    SizedBox(height: 20),

                    // Confirm Password
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                      obscureText: true,
                      onSaved: (val) => confirmPassword = val!.trim(),
                      validator: (val) => val != null && val.length >= 6
                          ? null
                          : 'Confirm password must be 6+ chars',
                    ),
                    SizedBox(height: 20),

                    loading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(onPressed: submit, child: Text('Register')),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Have an account? '),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
