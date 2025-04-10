import 'package:flutter/material.dart';
import '../controllers/caffeine_page_controller.dart';
import '../controllers/hydration_page_controller.dart';
import '../widgets/reusables.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import for Firebase Authentication
import '../pages/welcome_page.dart';  // Import for WelcomePage

class MenuPage extends StatelessWidget {
  final String uid;
  const MenuPage({required this.uid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,  // Make app bar background transparent
        elevation: 0,  // Remove the default elevation
        leading: IconButton(
          icon: Icon(Icons.logout),  // Log out icon
          onPressed: () async {
            // Show the confirmation dialog
            bool? shouldLogout = await showYesNoDialog(
                context,
                'Log Out?',
                'Are you sure you want to log out?'
            );

            // If user presses "Yes" (i.e., shouldLogout is true), log them out
            if (shouldLogout == true) {
              await FirebaseAuth.instance.signOut();
              // Navigate back to the WelcomePage
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => WelcomePage()),
              );
            }
          },
          color: Colors.black,  // Color for the logout icon
        ),
      ),
      body: Row(
        children: [
          // Left Half
          Expanded(
            child: Container(
              color: Color(0xFF2B4257), // Left half background color
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Center content vertically
                  children: [
                    // Text above the water droplet button
                    Text(
                      'Hydration Tracking',
                      style: TextStyle(
                        color: Color(0xFF88A9C3), // Text color matches button background
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16), // Spacing between text and button
                    // Water droplet icon button
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF88A9C3), // Button background color
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.water_drop, // Water droplet icon
                          color: Color(0xFF2B4257), // Icon color matches background
                        ),
                        iconSize: 50,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  HydrationPageController(uid: uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Half
          Expanded(
            child: Container(
              color: Color(0xFFA0522D), // Right half background color (brown)
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Center content vertically
                  children: [
                    // Text above the coffee cup button
                    Text(
                      'Caffeine Tracking',
                      style: TextStyle(
                        color: Color(0xFFFFD59A), // Text color matches button background
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16), // Spacing between text and button
                    // Coffee cup icon button
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD59A), // Button background color (caramel)
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.coffee, // Coffee cup icon
                          color: Color(0xFFA0522D), // Icon color (brown)
                        ),
                        iconSize: 50,
                        onPressed: () {
                          // Navigate to the caffeine tracking page
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CaffeinePageController(uid: uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
