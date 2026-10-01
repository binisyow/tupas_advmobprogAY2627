import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';

enum LoginType { dummyJson, firebase }

class UserService {
  Map<String, dynamic> data = {};
  final firebase.FirebaseAuth? _firebaseAuthOverride;

  UserService({firebase.FirebaseAuth? firebaseAuth})
    : _firebaseAuthOverride = firebaseAuth;

  firebase.FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? firebase.FirebaseAuth.instance;

  Future<Map<String, dynamic>> signInWithIdentifier({
    required String identifier,
    required String password,
  }) {
    final loginType = identifier.trim().contains('@')
        ? LoginType.firebase
        : LoginType.dummyJson;
    return signIn(
      loginType: loginType,
      username: identifier.trim(),
      password: password,
    );
  }

  Future<Map<String, dynamic>> signIn({
    required LoginType loginType,
    required String username,
    required String password,
  }) async {
    if (loginType == LoginType.dummyJson) {
      return loginUser(username, password);
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: username.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Firebase sign-in returned no user.');

    final token = await user.getIdToken();
    data = {
      'id': 0,
      'firebaseUid': user.uid,
      'username': user.displayName ?? user.email?.split('@').first ?? '',
      'email': user.email ?? '',
      'firstName': '',
      'lastName': '',
      'age': 0,
      'phone': '',
      'gender': '',
      'image': '',
      'accessToken': token ?? '',
      'refreshToken': '',
      'loginType': LoginType.firebase.name,
    };
    await saveUserData(data);
    return data;
  }

  Future<Map<String, dynamic>> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: emailAddress.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Firebase signup returned no user.');

    await user.updateDisplayName(username.trim());
    final token = await user.getIdToken();
    data = {
      'id': 0,
      'firebaseUid': user.uid,
      'username': username.trim(),
      'email': emailAddress.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'age': age,
      'phone': contactNo.trim(),
      'gender': '',
      'image': '',
      'accessToken': token ?? '',
      'refreshToken': '',
      'loginType': LoginType.firebase.name,
    };
    await saveUserData(data);
    return data;
  }

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);
    await prefs.setString('firebaseUid', userData['firebaseUid'] ?? '');
    await prefs.setString(
      'loginType',
      userData['loginType'] ?? LoginType.dummyJson.name,
    );

    if (userData['loginType'] == LoginType.firebase.name) {
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('token');
    } else if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('loginType') ?? '';
    var accessToken = prefs.getString('accessToken') ?? '';
    if (loginType == LoginType.firebase.name) {
      final activeFirebaseUser = _firebaseAuth.currentUser;
      if (activeFirebaseUser != null) {
        accessToken = await activeFirebaseUser.getIdToken() ?? '';
      }
    }

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': accessToken,
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': accessToken.isNotEmpty
          ? accessToken
          : prefs.getString('token') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'firebaseUid': prefs.getString('firebaseUid') ?? '',
      'loginType': loginType,
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// Check if a user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      if (_firebaseAuth.currentUser != null) return true;
    } on firebase.FirebaseException {
      // Allow local-only tests to check a persisted DummyJSON session.
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> updateUsername(String username) async {
    final userData = await getUserData();
    if (userData['loginType'] == LoginType.firebase.name) {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No Firebase user is signed in.');
      await user.updateDisplayName(username.trim());
    } else {
      final response = await http.patch(
        Uri.parse('$host/users/${userData['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username.trim()}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(response.body);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username.trim());
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Password changes require a signed-in Firebase account.');
    }
    final credential = firebase.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final userData = await getUserData();
    if (userData['loginType'] == LoginType.firebase.name) {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No Firebase user is signed in.');
      await user.delete();
    } else {
      final response = await http.delete(
        Uri.parse('$host/users/${userData['id']}'),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(response.body);
      }
    }
    await signOut();
  }

  Future<void> signOut() async {
    try {
      if (_firebaseAuth.currentUser != null) await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'id',
        'username',
        'email',
        'firstName',
        'lastName',
        'gender',
        'image',
        'accessToken',
        'refreshToken',
        'token',
        'age',
        'phone',
        'firebaseUid',
        'loginType',
      ]) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> logout() => signOut();
}
