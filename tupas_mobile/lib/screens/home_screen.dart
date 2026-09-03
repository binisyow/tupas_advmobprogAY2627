import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _profileName = 'Profile';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  // Enhancement 3: the Profile tab's header uses the saved user's first
  // name, read the same way ProfileScreen reads it (via UserService).
  Future<void> _loadProfileName() async {
    final user = await UserService().getUser();
    if (!mounted || user.firstName.isEmpty) return;
    setState(() {
      _profileName = user.firstName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onProfileTab = _selectedIndex == 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          backgroundColor: onProfileTab ? brandNavy : null,
          foregroundColor: onProfileTab ? Colors.white : null,
          title: (_selectedIndex == 0)
              ? Image.asset('assets/images/nubdexchange_logo.png', scale: 11.sp)
              : CustomText(
                  text: (_selectedIndex == 1) ? 'Cart' : _profileName,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: onProfileTab ? Colors.white : null,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          // Enhancement 1: Cart is now a tab (index 1) instead of a pushed
          // screen, sharing this Scaffold's AppBar/bottom nav.
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false, //selected item
          showUnselectedLabels: false, //unselected item
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
        // Enhancement 2: the old "Chat" bottom nav tab is now a
        // FloatingActionButton, hidden while the Cart tab is active.
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                backgroundColor: Colors.deepPurple.shade50,
                foregroundColor: Colors.deepPurple.shade700,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat coming soon')),
                  );
                },
                child: const Icon(Icons.chat),
              ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
