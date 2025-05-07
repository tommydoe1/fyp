import 'package:flutter/material.dart';
import '../pages/menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/hydration_page_controller.dart';

class CaffeinePage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showAppBar;
  final List<Widget>? actions;

  const CaffeinePage({
    Key? key,
    required this.title,
    required this.body,
    this.showAppBar = true,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'default_uid';
    final Color caramel = Color(0xFFF7CA79);
    final Color brown = Color(0xFF935F4C);

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: caramel,
      foregroundColor: brown,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      textStyle: const TextStyle(fontSize: 16),
    );

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: caramel,
      focusColor: caramel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: brown),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: brown, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: brown, width: 1),
      ),
      labelStyle: TextStyle(color: brown),
      hintStyle: TextStyle(color: brown.withOpacity(0.6)),
    );

    return Scaffold(
        appBar: showAppBar
            ? AppBar(
          backgroundColor: caramel,
          title: Text(
            title,
            style: TextStyle(color: brown),
          ),
          iconTheme: IconThemeData(color: brown),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  Icons.water_drop,
                  color: brown,
                  size: 28,
                ),
                onPressed: () {
                  // When the icon is pressed, navigate to HydrationPageController
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HydrationPageController(uid: uid),
                    ),
                  );
                },
              ),
            ),
            if (actions != null) ...actions!,
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: brown),
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
        color: brown,
        child: Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
            inputDecorationTheme: inputDecorationTheme,
            dropdownMenuTheme: DropdownMenuThemeData(
              textStyle: TextStyle(color: caramel),
              menuStyle: MenuStyle(
                backgroundColor: MaterialStateProperty.all(brown),
              ),
            ),
          ),
          child: body,
        ),
      ),
    );
  }
}
