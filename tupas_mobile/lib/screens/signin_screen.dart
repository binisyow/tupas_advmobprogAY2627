import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// constants
import '../constants.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 2: sign-in UI built around UserService's login/save flow —
// the form only handles input/validation/loading state, all the
// authentication logic (loginUser + saveUserData) lives in UserService.
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    UserService userService = UserService();
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      try {
        final response = await userService.loginUser(
          _usernameController.text,
          _passwordController.text,
        );

        // Save user data to SharedPreferences
        await userService.saveUserData(response);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(context, '/home', arguments: response);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      width: 32.w,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Welcome',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
                TextFormField(
                  controller: _usernameController,
                  decoration: _fieldDecoration('Username'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Username is required'
                      : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _fieldDecoration('Password'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Password is required'
                      : null,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : CustomText(
                              text: 'Log In',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
