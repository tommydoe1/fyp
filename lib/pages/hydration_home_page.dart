import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reusables.dart';
import '../controllers/database_controller.dart';
import '../widgets/hydration_base_page.dart';
import '../pages/results_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../controllers/caffeine_page_controller.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class HydroHomePage extends StatefulWidget {
  final String uid;
  final PageController pageController;

  const HydroHomePage({required this.uid, required this.pageController, Key? key}) : super(key: key);

  @override
  _HydroHomePageState createState() => _HydroHomePageState();
}

class _HydroHomePageState extends State<HydroHomePage> {
  String? _selectedItem;
  String _selectedItemCategory = 'Water';
  final DatabaseController databaseController = DatabaseController();
  String _username = 'Loading...'; // placeholder
  final TextEditingController _sizeController = TextEditingController();
  double _progress = 0.0;
  int _waterConsumed = 0;
  int _dailyGoal = 1;
  String _progressMessage = 'Loading...'; // placeholder

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _resetWaterConsumedOnLoad();
    await _updateProgress();
    _fetchUsername();
    _checkRequiredFields();
  }


  Future<void> _resetWaterConsumedOnLoad() async {
    try {
      await databaseController.resetWaterConsumed(uid: widget.uid);
    } catch (e) {
      print("Error resetting water consumed: $e");
    }
  }

  Future<void> _updateProgress() async {
    try {
      int waterConsumed = await databaseController.getWaterConsumed(widget.uid) ?? 0;
      int dailyGoal = await databaseController.getDailyGoal(widget.uid) ?? 2000;
      DateTime now = DateTime.now();

      // Fetch user's bedtime
      String? bedtimeString = await databaseController.getBedtime(widget.uid);
      if (bedtimeString == null) {
        print("Error: Bedtime not found.");
        return;
      }

      // Parse bedtime (assuming stored format is "HH:mm" in 24-hour format)
      List<String> bedtimeParts = bedtimeString.split(":");
      int bedtimeHour = int.parse(bedtimeParts[0]);
      int bedtimeMinute = int.parse(bedtimeParts[1]);
      DateTime bedtime = DateTime(now.year, now.month, now.day, bedtimeHour, bedtimeMinute);

      // Ensure bedtime is in the future (if the user set bedtime past midnight)
      if (bedtime.isBefore(now)) {
        bedtime = bedtime.add(Duration(days: 1));
      }

      // Calculate wake-up time (bedtime - 7 hours)
      DateTime wakeUpTime = bedtime.subtract(Duration(hours: 7));

      // Ensure wake-up time is today
      if (wakeUpTime.isAfter(now)) {
        wakeUpTime = wakeUpTime.subtract(Duration(days: 1));
      }

      // Calculate total awake hours
      int awakeHours = bedtime.difference(wakeUpTime).inHours;
      if (awakeHours <= 0) awakeHours = 17; // Default to 17 if there's an error

      // Calculate how much they should drink per hour
      int hourlyTarget = (dailyGoal / awakeHours).ceil();

      // Calculate elapsed awake hours
      int elapsedHours = now.difference(wakeUpTime).inHours;
      elapsedHours = elapsedHours.clamp(0, awakeHours); // Ensure it's within range

      // Expected water intake by now
      int expectedConsumption = elapsedHours * hourlyTarget;

      // Determine message
      String progressMessage;
      int difference = waterConsumed.toInt() - expectedConsumption;

      if (difference < 0) {
        progressMessage = "You need to drink ${-difference} ml of water to get back on track!";
      } else {
        progressMessage = "You're ${difference} ml ahead of schedule, keep it up!";
      }

      setState(() {
        _waterConsumed = waterConsumed;
        _dailyGoal = dailyGoal;
        _progress = dailyGoal > 0 ? waterConsumed / dailyGoal : 0.0;
        _progressMessage = progressMessage;
      });
    } catch (e) {
      print("Error fetching progress data: $e");
    }
  }



  Future<void> _checkRequiredFields() async {
    bool fieldsExist = await databaseController.doAllFieldsExist(widget.uid);
    if (!fieldsExist) {
      showSetRequiredFieldsDialog(context, widget.uid, databaseController, hydroColorScheme);
    }
  }

  Future<void> _fetchUsername() async {
    String username = await databaseController.getUsername(widget.uid);
    setState(() {
      _username = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HydrationPage(
      title: 'Home',
      body: Container(
        decoration: BoxDecoration(
          color: dblue,
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Back text
                Text(
                  'Welcome Back $_username!',
                  style: TextStyle(
                    color: lblue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Lottie.asset(
                  'assets/waterbottle.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.fill,
                ),
                // Select item section
                Text(
                  'Enter how much you have drank:',
                  style: TextStyle(
                    color: lblue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                // Water content field
                TextField(
                  controller: _sizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Drink size (ml)',
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    color: dblue,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedItemCategory,
                  decoration: InputDecoration(
                    hintText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: lblue,
                  items: [
                    'Water',
                    'Coffee',
                    'Tea',
                    'Soft Drink',
                    'Energy Drink',
                    'Alcoholic Drink',
                    'Sports Drink',
                    'Other Drink',
                  ].map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(
                            color: dblue,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 20),

                // Calculate button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      minimumSize: Size(0, 50),
                    ),
                    onPressed: () async {
                      String sizeText = _sizeController.text.trim();
                      if (sizeText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter the drink size in ml.')),
                        );
                        return;
                      }
                      try {
                        double size = double.parse(sizeText);
                        bool? confirmed = await databaseController.calculateHydration(
                          context: context,
                          uid: widget.uid,
                          category: _selectedItemCategory,
                          size: size,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(confirmed!
                                ? 'Hydration Calculation Successful.'
                                : 'Hydration Calculation Failed.'),
                          ),
                        );
                        _updateProgress();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid input. Please enter a valid number.')),
                        );
                      }
                    },
                    child: Text(
                      'Calculate',
                      style: TextStyle(
                          color: dblue,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Progress bar
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 40.0,
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Color(0xFFEAE0D5),
                        valueColor: AlwaysStoppedAnimation<Color>(lblue),
                        minHeight: 40.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '$_waterConsumed ml / $_dailyGoal ml',
                  style: TextStyle(
                    color: lblue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _progressMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lblue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
