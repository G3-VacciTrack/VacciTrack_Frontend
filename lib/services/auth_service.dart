import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  Future<void> saveUserId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);
  }

  Future<bool> isNewUser(String uid, String email) async {
    final url = Uri.parse('$baseUrl/user/validate?uid=$uid&email=$email');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == true;
    }
    return true;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Sign-in aborted by user'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;
        final email = user.email ?? '';
        await saveUserId(uid);
        final isNew = await isNewUser(uid, email);
        return {'success': true, 'isNewUser': isNew};
      } else {
        return {'success': false, 'message': 'User is null'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;
        await saveUserId(uid);
        final isNew = await isNewUser(uid, email);
        return {'success': true, 'isNewUser': isNew};
      } else {
        return {'success': false, 'message': 'User is null'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Auth error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<String?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    return 'Unknown error occurred';
  }
}
