import 'package:flutter/material.dart';
import '../pages/profile_page.dart';
import '../pages/hydration_home_page.dart';
import '../pages/hydration_history_page.dart';
import '../widgets/hydration_base_page.dart';
import '../widgets/reusables.dart';

class HydrationPageController extends StatefulWidget {
  final String uid;

  HydrationPageController({required this.uid});

  @override
  _HydrationPageControllerState createState() => _HydrationPageControllerState();
}

class _HydrationPageControllerState extends State<HydrationPageController> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void navigateToPage(int pageIndex) {
    setState(() {
      _currentIndex = pageIndex;
    });
    _pageController.jumpToPage(pageIndex); // Navigate instantly without animation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HydrationPage(
            title: 'Home',
            body: HydroHomePage(uid: widget.uid, pageController: _pageController),
            showAppBar: false,
          ),
          HydrationPage(
            title: 'History',
            body: HydrationHistoryPage(uid: widget.uid),
            showAppBar: true,
          ),
          HydrationPage(
            title: 'Profile',
            body: ProfilePage(uid: widget.uid, colorScheme: hydroColorScheme),
            showAppBar: false,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFF2B4257),
        selectedItemColor: Color(0xFF88A9C3),
        unselectedItemColor: Color(0xff9e9e9e),
      ),
    );
  }
}
