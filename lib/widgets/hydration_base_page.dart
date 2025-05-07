import 'package:flutter/material.dart';
import '../pages/menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/caffeine_page_controller.dart';

class HydrationPage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showAppBar;
  final List<Widget>? actions;

  const HydrationPage({
    Key? key,
    required this.title,
    required this.body,
    this.showAppBar = true,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'default_uid';
    final Color lblue = Color(0xFF88A9C3);
    final Color dblue = Color(0xFF2B4257);

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: lblue,
      foregroundColor: dblue,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      textStyle: const TextStyle(fontSize: 16),
    );

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: lblue,
      focusColor: lblue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: dblue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: dblue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: dblue, width: 1),
      ),
      labelStyle: TextStyle(color: dblue),
      hintStyle: TextStyle(color: dblue.withOpacity(0.6)),
    );

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        backgroundColor: lblue,
        title: Text(
          title,
          style: TextStyle(color: dblue),
        ),
        iconTheme: IconThemeData(color: dblue),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.coffee,
                color: dblue,
                size: 28,
              ),
              onPressed: () {
                // When the icon is pressed, navigate to HydrationPageController
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => CaffeinePageController(uid: uid),
                  ),
                );
              },
            ),
          ),
          if (actions != null) ...actions!,
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dblue),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MenuPage(uid: uid),
              ),
            );
          },
        ),
      )
          : null,
      body: Container(
        color: dblue,
        child: Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
            inputDecorationTheme: inputDecorationTheme,
            dropdownMenuTheme: DropdownMenuThemeData(
              textStyle: TextStyle(color: lblue),
              menuStyle: MenuStyle(
                backgroundColor: MaterialStateProperty.all(dblue),
              ),
            ),
          ),
          child: body,
        ),
      ),
    );
  }
}
