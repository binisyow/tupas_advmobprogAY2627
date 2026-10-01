import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final account = await UserService().createAccount(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        age: int.parse(_ageController.text),
        contactNo: _contactController.text,
        username: _usernameController.text,
        emailAddress: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: account,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
            children: [
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('First name'),
                validator: (value) => _required(value, 'First name'),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Last name'),
                validator: (value) => _required(value, 'Last name'),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Age'),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 13 || age > 120) {
                    return 'Enter an age from 13 to 120';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Contact number'),
                validator: (value) {
                  if (_required(value, 'Contact number') != null) {
                    return 'Contact number is required';
                  }
                  if (!RegExp(r'^[+0-9() .-]{7,20}$').hasMatch(value!.trim())) {
                    return 'Enter a valid contact number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _usernameController,
                decoration: _decoration('Username'),
                validator: (value) {
                  if (_required(value, 'Username') != null) {
                    return 'Username is required';
                  }
                  if (value!.trim().length < 3) {
                    return 'Use at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email address'),
                validator: (value) {
                  if (_required(value, 'Email address') != null) {
                    return 'Email address is required';
                  }
                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(value!.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: _decoration(
                  'Password',
                  suffixIcon: IconButton(
                    tooltip: _passwordVisible
                        ? 'Hide password'
                        : 'Show password',
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 8 ||
                      !RegExp(r'[A-Za-z]').hasMatch(value) ||
                      !RegExp(r'\d').hasMatch(value)) {
                    return 'Use 8+ characters with a letter and a number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 22.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _createAccount,
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
