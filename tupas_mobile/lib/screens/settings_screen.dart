import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// providers
import '../providers/theme_provider.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 3: settings page that hosts the dark/light mode switch
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await UserService().signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        children: [
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
            ),
            title: CustomText(
              text: 'Dark Mode',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            subtitle: CustomText(
              text: themeProvider.isDark ? 'Currently on' : 'Currently off',
              fontSize: 12.sp,
            ),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: CustomText(
              text: 'Log out',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
