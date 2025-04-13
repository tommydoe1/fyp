import '../controllers/database_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color caramel = Color(0xFFF7CA79);
const Color brown = Color(0xFF935F4C);
const Color lblue = Color(0xFF88A9C3);
const Color dblue = Color(0xFF2B4257);

final Map<String, double> hydrationMultipliers = {
  'Water': 1.0,
  'Coffee': 0.8,
  'Tea': 0.9,
  'Soft Drink': 0.7,
  'Energy Drink': 0.7,
  'Alcoholic Drink': 0.3,
  'Sports Drink': 0.9,
  'Other Drink': 0.8,
};

class PageColorScheme {
  final Color backgroundColor;
  final Color foregroundColor;

  PageColorScheme({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

final PageColorScheme cafColorScheme = PageColorScheme(
  backgroundColor: brown,
  foregroundColor: caramel
);

final PageColorScheme hydroColorScheme = PageColorScheme(
    backgroundColor: dblue,
    foregroundColor: lblue
);

void showHydrationHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Hydration Goal Guidance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended daily hydration goals:'),
            SizedBox(height: 8),
            Text('- Average person: 2000-2500ml'),
            Text('- Hot weather: 2500-3500ml'),
            Text('- Heavy exercise: 3500ml or more'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

void showCaffeineHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Caffeine Limit Guidance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended caffeine limits:'),
            SizedBox(height: 8),
            Text('- Average person: up to 400mg/day'),
            Text('- Regular caffeine drinker: 400-600mg/day'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<bool?> showYesNoDialog(BuildContext context, String title, String message) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}

void showSetRequiredFieldsDialog(
    BuildContext context,
    String uid,
    DatabaseController databaseController,
    PageColorScheme colorScheme) {

  final TextEditingController bedtimeController = TextEditingController();
  final TextEditingController caffeineLimitController = TextEditingController();
  final TextEditingController dailyGoalController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing without input
    builder: (context) {
      return Dialog(
        child: Container(
          color: colorScheme.backgroundColor,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Set Required Fields',
                style: TextStyle(
                  color: colorScheme.foregroundColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Bedtime Input
              TextField(
                controller: bedtimeController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  hintText: 'Enter bedtime (e.g. 10:30 PM or 22:30)',
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(color: colorScheme.backgroundColor),
                ),
                style: TextStyle(color: colorScheme.backgroundColor),
              ),
              SizedBox(height: 10),

              // Caffeine Limit Input with Help Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caffeineLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter caffeine limit (mg)',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: colorScheme.backgroundColor),
                      ),
                      style: TextStyle(color: colorScheme.backgroundColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: colorScheme.foregroundColor),
                    onPressed: () {
                      showCaffeineHelp(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Daily Hydration Goal Input with Help Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dailyGoalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter Daily Hydration Goal (ml)',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: colorScheme.backgroundColor),
                      ),
                      style: TextStyle(color: colorScheme.backgroundColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: colorScheme.foregroundColor),
                    onPressed: () {
                      showHydrationHelp(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Save Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      String bedtime = bedtimeController.text.trim();
                      String caffeineLimitStr = caffeineLimitController.text.trim();
                      String dailyGoalStr = dailyGoalController.text.trim();

                      // Check if any input field is empty
                      if (bedtime.isEmpty || caffeineLimitStr.isEmpty || dailyGoalStr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill out all fields!')),
                        );
                        return;
                      }

                      try {
                        int caffeineLimit = int.tryParse(caffeineLimitStr) ?? 400; // Default 400 mg
                        int dailyGoal = int.tryParse(dailyGoalStr) ?? 2000; // Default 2000 ml

                        // Attempt to parse bedtime
                        TimeOfDay? timeOfDay;
                        final twelveHourFormat = DateFormat("hh:mm a");
                        final twentyFourHourFormat = DateFormat("HH:mm");

                        try {
                          if (RegExp(r'^\d{1,2}:\d{2} (AM|PM)$', caseSensitive: false).hasMatch(bedtime)) {
                            // Already in 12-hour format
                            DateTime parsedBedtime = twelveHourFormat.parse(bedtime);
                            timeOfDay = TimeOfDay(hour: parsedBedtime.hour, minute: parsedBedtime.minute);
                          } else if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(bedtime)) {
                            // If entered in 24-hour format (e.g., 23:30)
                            DateTime parsedBedtime = twentyFourHourFormat.parse(bedtime);
                            timeOfDay = TimeOfDay(hour: parsedBedtime.hour, minute: parsedBedtime.minute);
                            // Convert to 12-hour format for display
                            bedtimeController.text = twelveHourFormat.format(parsedBedtime);
                          } else {
                            throw FormatException("Invalid time format");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid bedtime format! Use "10:30 PM" or "22:30".')),
                          );
                          return;
                        }

                        // Save to Firestore
                        await databaseController.updateBedtime(uid: uid, bedtime: timeOfDay!);
                        await databaseController.updateCaffeineLimit(uid: uid, newCaffeineLimit: caffeineLimit);
                        await databaseController.updateDailyGoal(uid: uid, newDailyGoal: dailyGoal);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fields updated successfully!')),
                        );

                        Navigator.of(context).pop(); // Close the dialog
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating fields: $e')),
                        );
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

