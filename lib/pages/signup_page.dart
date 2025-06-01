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
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final _passwordController = TextEditingController();

  Future<void> submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    setState(() {
      loading = true;
      error = '';
    });

    final result = await _authService.registerWithEmail(email, password);

    if (result == null) {
      Navigator.of(context).pop(); // Success
    } else {
      setState(() => error = result);
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 94),
          child: Stack(
            children: [
              // Back Button
              Positioned(
                left: 0,
                top: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFF33354C)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Header Text
              const Positioned(
                left: 50,
                top: 0,
                child: Text(
                  'Create New Account',
                  style: TextStyle(
                    color: Color(0xFF33354C),
                    fontSize: 32,
                    fontFamily: 'Noto Sans Bengali',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Positioned(
                top: 138,
                left: 20,
                right: 20,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      buildLabeledField(
                        label: 'Email',
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: textFieldDecoration(),
                          onSaved: (val) => email = val!.trim(),
                          validator:
                              (val) =>
                                  val != null && val.contains('@')
                                      ? null
                                      : 'Enter valid email',
                        ),
                      ),
                      const SizedBox(height: 24),
                      buildLabeledField(
                        label: 'Password',
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: textFieldDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          onSaved: (val) => password = val!.trim(),
                          validator:
                              (val) =>
                                  val != null && val.length >= 6
                                      ? null
                                      : 'Password too short',
                        ),
                      ),
                      const SizedBox(height: 24),
                      buildLabeledField(
                        label: 'Confirm Password',
                        child: TextFormField(
                          obscureText: !_confirmPasswordVisible,
                          decoration: textFieldDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          onSaved: (val) => confirmPassword = val!.trim(),
                          validator:
                              (val) =>
                                  val != _passwordController.text
                                      ? 'Passwords do not match'
                                      : null,
                        ),
                      ),
                      const SizedBox(height: 40),
                      loading
                          ? const CircularProgressIndicator()
                          : GestureDetector(
                            onTap: submit,
                            child: Container(
                              width: 338,
                              height: 44,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF6CC2A8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Noto Sans Bengali',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Have an account?',
                            style: TextStyle(
                              color: Color(0xFF6F6F6F),
                              fontSize: 13,
                              fontFamily: 'Noto Sans Bengali',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF6CC2A8),
                                fontSize: 13,
                                fontFamily: 'Noto Sans Bengali',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33354C),
            fontSize: 15.93,
            fontFamily: 'Noto Sans Bengali',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
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
}
