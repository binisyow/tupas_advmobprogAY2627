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

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService().getUser();
  }

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
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
                              text: '${user.firstName} ${user.lastName}'.trim(),
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
                          Icons.badge_outlined,
                          'User ID',
                          '#${user.id}',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
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
                    onPressed: () => _logout(context),
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
