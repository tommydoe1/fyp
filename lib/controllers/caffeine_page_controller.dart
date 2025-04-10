import 'package:flutter/material.dart';
import '../pages/profile_page.dart';
import '../pages/caffeine_home_page.dart';
import '../pages/caffeine_history_page.dart';
import '../pages/results_page.dart';
import '../widgets/caffeine_base_page.dart';
import '../widgets/reusables.dart';

class CaffeinePageController extends StatefulWidget {
  final String uid;

  CaffeinePageController({required this.uid});

  @override
  _CaffeinePageControllerState createState() => _CaffeinePageControllerState();
}

class _CaffeinePageControllerState extends State<CaffeinePageController> {
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
          CaffeinePage(
            title: 'Home',
            body: HomePage(uid: widget.uid, pageController: _pageController),
            showAppBar: false,
          ),
          CaffeinePage(
            title: 'Time Remaining',
            body: ResultsPage(uid: widget.uid),
            showAppBar: false,
          ),
          CaffeinePage(
            title: 'History',
            body: CaffeineHistoryPage(uid: widget.uid),
            showAppBar: true,
          ),
          CaffeinePage(
            title: 'Profile',
            body: ProfilePage(uid: widget.uid, colorScheme: cafColorScheme),
            showAppBar: false,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Time Remaining'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: brown,
        selectedItemColor: caramel,
        unselectedItemColor: Color(0xff9e9e9e),
      ),
    );
  }
}
