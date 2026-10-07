import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

// models
import '../models/user.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 3: Profile tab built on the User model — reads the signed-in
// user from UserService (already persisted to SharedPreferences during
// splash/sign-in), so no arguments need to be passed in.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _UsernameEditDialog extends StatefulWidget {
  final String initialUsername;

  const _UsernameEditDialog({required this.initialUsername});

  @override
  State<_UsernameEditDialog> createState() => _UsernameEditDialogState();
}

class _UsernameEditDialogState extends State<_UsernameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? username]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(username);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update username'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Cancel')),
        FilledButton(
          onPressed: () => _close(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  void _close([({String currentPassword, String newPassword})? result]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Current password is required'
                  : null,
            ),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) => value == null || value.length < 8
                  ? 'Use at least 8 characters'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _close((
                currentPassword: _currentController.text,
                newPassword: _newController.text,
              ));
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  void _refreshUser() {
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    final userData = await UserService().getUserData();
    return User.fromJson(userData);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<T?> _showProfileDialog<T>({required WidgetBuilder builder}) {
    return Navigator.of(context).push<T>(
      DialogRoute<T>(
        context: context,
        builder: builder,
        barrierDismissible: true,
        themes: null,
      ),
    );
  }

  Future<void> _editUsername() async {
    final user = await _userFuture;
    if (!mounted) return;
    final username = await _showProfileDialog<String>(
      builder: (_) => _UsernameEditDialog(initialUsername: user.username),
    );
    if (username == null || username.isEmpty) return;
    try {
      await UserService().updateUsername(username);
      if (!mounted) return;
      setState(_refreshUser);
      _showMessage('Username updated');
    } catch (error) {
      if (mounted) _showMessage('Could not update username: $error');
    }
  }

  Future<void> _changePassword() async {
    final passwords =
        await _showProfileDialog<
          ({String currentPassword, String newPassword})
        >(builder: (_) => const _ChangePasswordDialog());
    if (passwords != null) {
      try {
        await UserService().resetPasswordFromCurrentPassword(
          currentPassword: passwords.currentPassword,
          newPassword: passwords.newPassword,
        );
        if (mounted) _showMessage('Password updated');
      } catch (error) {
        if (mounted) _showMessage('Could not update password: $error');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showProfileDialog<bool>(
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await UserService().deleteAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (mounted) _showMessage('Could not delete account: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null || user.username.isEmpty) {
          return Center(
            child: CustomText(text: 'Not signed in.', fontSize: 14.sp),
          );
        }
        final displayName = '${user.firstName} ${user.lastName}'.trim();

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50.r,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.image,
                                  width: 100.r,
                                  height: 100.r,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      Icon(Icons.person, size: 50.sp),
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            CustomText(
                              text: displayName.isEmpty
                                  ? 'Account name unavailable'
                                  : displayName,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 5.h),
                            CustomText(
                              text: '@${user.username}',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                            TextButton.icon(
                              onPressed: _editUsername,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit username'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email',
                          user.email,
                        ),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildInfoRow(Icons.wc, 'Gender', user.gender),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildInfoRow(
                          Icons.cake_outlined,
                          'Age',
                          '${user.age}',
                        ),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Contact',
                          user.phone.isEmpty ? 'Not provided' : user.phone,
                        ),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildInfoRow(
                          Icons.verified_user_outlined,
                          'Login type',
                          user.loginType == LoginType.firebase.name
                              ? 'Firebase'
                              : 'DummyJSON',
                        ),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          'User ID',
                          '#${user.id}',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change password'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete account'),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () async {
                      try {
                        await UserService().signOut();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/signin',
                          (route) => false,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          _showMessage('Could not sign out: $error');
                        }
                      }
                    },
                    icon: Icon(Icons.logout, size: 18.sp),
                    label: CustomText(
                      text: 'Log Out',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.amber.shade800),
          SizedBox(width: 10.w),
          CustomText(text: label, fontSize: 13.sp, fontWeight: FontWeight.w600),
          const Spacer(),
          CustomText(text: value, fontSize: 13.sp),
        ],
      ),
    );
  }
}
