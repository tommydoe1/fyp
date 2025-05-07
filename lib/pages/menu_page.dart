import 'package:flutter/material.dart';
import '../controllers/caffeine_page_controller.dart';
import '../controllers/hydration_page_controller.dart';
import '../widgets/reusables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/welcome_page.dart';

class MenuPage extends StatelessWidget {
  final String uid;
  const MenuPage({required this.uid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            bool? shouldLogout = await showYesNoDialog(
                context,
                'Log Out?',
                'Are you sure you want to log out?'
            );

            if (shouldLogout == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => WelcomePage()),
              );
            }
          },
          color: Colors.black,
        ),
      ),
      body: Row(
        children: [
          // Left Half
          Expanded(
            child: Container(
              color: Color(0xFF2B4257),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hydration Tracking',
                      style: TextStyle(
                        color: Color(0xFF88A9C3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF88A9C3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.water_drop,
                          color: Color(0xFF2B4257),
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

          Expanded(
            child: Container(
              color: Color(0xFFA0522D),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Caffeine Tracking',
                      style: TextStyle(
                        color: Color(0xFFFFD59A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD59A),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.coffee,
                          color: Color(0xFFA0522D),
                        ),
                        iconSize: 50,
                        onPressed: () {
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
