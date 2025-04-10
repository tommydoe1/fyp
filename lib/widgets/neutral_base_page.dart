import 'package:flutter/material.dart';

class NeutralPage extends StatelessWidget {
  final String title;
  final Widget body;

  const NeutralPage({Key? key, required this.title, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF22333B),
      foregroundColor: Color(0xFFEAE0D5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      textStyle: const TextStyle(fontSize: 16),
    );

    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF22333B),
      focusColor: Color(0xFF22333B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFEAE0D5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFEAE0D5), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFEAE0D5), width: 1),
      ),
      labelStyle: TextStyle(color: Color(0xFFEAE0D5)),
      hintStyle: TextStyle(color: Color(0xFFEAE0D5).withOpacity(0.6)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF22333B),
        title: Text(
          title,
          style: TextStyle(color: Color(0xFFEAE0D5)),
        ),
        iconTheme: IconThemeData(color: Color(0xFFEAE0D5)),
      ),
      body: Container(
        color: const Color(0xFFEAE0D5),
        child: Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
          ),
          child: body,
        ),
      ),
    );
  }
}
