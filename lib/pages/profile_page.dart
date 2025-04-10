import 'package:flutter/material.dart';
import '../widgets/caffeine_base_page.dart';
import '../widgets/hydration_base_page.dart';
import '../pages/welcome_page.dart';
import '../controllers/database_controller.dart';
import '../controllers/user_account_controller.dart';
import '../widgets/reusables.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final PageColorScheme colorScheme;

  ProfilePage({required this.uid, required this.colorScheme});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseController databaseController = DatabaseController();
  final UserAccountController userAccountController = UserAccountController();
  final TextEditingController _caffeineLimitController = TextEditingController();
  final TextEditingController _hydrationGoalController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String selectedHeightUnit = 'Centimetres';
  String selectedWeightUnit = 'Kilograms (kg)';
  String? _selectedTime;
  List<String> times = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _generateTimeDropdown();
    _fetchBedtime();
  }

  Future<void> _loadUserProfile() async {
    try {
      String username = await databaseController.getUsername(widget.uid);
      String weight = await databaseController.getWeight(widget.uid);
      String height = await databaseController.getHeight(widget.uid);
      int caffeineLimit = await databaseController.getCaffeineLimit(widget.uid);
      int hydrationGoal = await databaseController.getDailyGoal(widget.uid) ?? 0;

      // Convert height from meters to centimeters
      double heightInCm = (double.tryParse(height) ?? 0) * 100;

      setState(() {
        _usernameController.text = username;
        _weightController.text = weight;
        _heightController.text = heightInCm.toStringAsFixed(2);
        _caffeineLimitController.text = caffeineLimit.toString();
        _hydrationGoalController.text = hydrationGoal.toString();
      });
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }


  Future<void> _fetchBedtime() async {
    String bedtime = await databaseController.getBedtime(widget.uid);

    if (bedtime.isNotEmpty) {
      List<String> parts = bedtime.split(':');
      String normalizedBedtime =
          '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}'; // Format as HH:mm

      if (times.contains(normalizedBedtime)) {
        setState(() {
          _selectedTime = normalizedBedtime;
        });
      } else {
        setState(() {
          _selectedTime = times.first;
        });
      }
    }
  }

  void _generateTimeDropdown() {
    for (int hour = 0; hour < 24; hour++) {
      for (int min = 0; min < 60; min += 30) {
        times.add(
            '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}');
      }
    }
  }

  Future<void> _updateBedtime() async {
    if (_selectedTime != null) {
      List<String> timeParts = _selectedTime!.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      TimeOfDay bedtime = TimeOfDay(hour: hour, minute: minute);
      await databaseController.updateBedtime(uid: widget.uid, bedtime: bedtime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bedtime updated to $_selectedTime!')),
      );
    }
  }

  Future<void> _updateCaffeineLimit() async {
    try {
      String caffeineLimitText = _caffeineLimitController.text.trim();
      if (caffeineLimitText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid caffeine limit.')),
        );
        return;
      }

      int caffeineLimit = int.parse(caffeineLimitText);
      await databaseController.updateCaffeineLimit(
        uid: widget.uid,
        newCaffeineLimit: caffeineLimit,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Caffeine limit updated to $caffeineLimit mg!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update caffeine limit. Please try again.')),
      );
      print('Error updating caffeine limit: $e');
    }
  }

  Future<void> _updateHydrationGoal() async {
    try {
      String hydrationGoalText = _hydrationGoalController.text.trim();
      if (hydrationGoalText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid hydration goal.')),
        );
        return;
      }

      int hydrationGoal = int.parse(hydrationGoalText);
      await databaseController.updateHydrationGoal(
        uid: widget.uid,
        newHydrationGoal: hydrationGoal,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hydration goal updated to $hydrationGoal ml!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update hydration goal. Please try again.')),
      );
      print('Error updating hydration goal: $e');
    }
  }


  Future<void> _updateUserProfile() async {
    try {
      String username = _usernameController.text.trim();
      String heightText = _heightController.text.trim();
      String weightText = _weightController.text.trim();

      if (username.isEmpty || heightText.isEmpty || weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All fields are required!')),
        );
        return;
      }

      double height = 0.0;

      if (selectedHeightUnit == 'Centimetres') {
        height = double.parse(heightText) / 100;
      } else {
        List<String> parts = heightText.split("'");

        if (parts.length == 2) {
          // Extract feet and inches
          int feet = int.tryParse(parts[0].trim()) ?? 0;
          int inches = int.tryParse(parts[1].trim()) ?? 0;

          // Convert to meters (1 foot = 0.3048 meters, 1 inch = 0.0254 meters)
          height = (feet * 0.3048) + (inches * 0.0254);
        } else {
          throw FormatException(
              "Invalid height format. Use format: Feet'Inches (e.g., 5'10)");
        }
      }

      int weight = int.parse(weightText);
      if (selectedWeightUnit == 'Pounds (lbs)') {
        weight = (weight / 2.20462).round();
      }

      await databaseController.updateUserDetails(
        uid: widget.uid,
        username: username,
        height: height,
        weight: weight,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget basePage = (widget.colorScheme == cafColorScheme)
        ? CaffeinePage(
      title: 'Profile',
      body: _buildBody(context),
    )
        : HydrationPage(
      title: 'Profile',
      body: _buildBody(context),
    );

    return basePage;
  }

  Widget _buildBody(BuildContext context) {
    const List<String> heightUnits = ['Centimetres', 'Feet & Inches'];
    const List<String> weightUnits = ['Kilograms (kg)', 'Pounds (lbs)'];

    double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Personal Details',
                style: TextStyle(
                  color: widget.colorScheme.foregroundColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your username',
                  ),
                  style: TextStyle(
                      color: widget.colorScheme.backgroundColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Height',
                      ),
                      style: TextStyle(
                          color: widget.colorScheme.backgroundColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: screenWidth * 0.42,
                    child: DropdownButtonFormField<String>(
                      value: selectedHeightUnit,
                      dropdownColor: widget.colorScheme.foregroundColor,
                      items: heightUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(
                            unit,
                            style:
                            TextStyle(
                                color: widget.colorScheme.backgroundColor,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedHeightUnit = value!;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Unit',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Weight',
                      ),
                      style: TextStyle(
                          color: widget.colorScheme.backgroundColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: screenWidth * 0.42,
                    child: DropdownButtonFormField<String>(
                      value: selectedWeightUnit,
                      dropdownColor: widget.colorScheme.foregroundColor,
                      items: weightUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(
                            unit,
                            style:
                            TextStyle(
                                color: widget.colorScheme.backgroundColor,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWeightUnit = value!;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Unit',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateUserProfile();
                  },
                  child: Text('Update Personal Details',
                    style: TextStyle(
                        color: widget.colorScheme.backgroundColor,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your bedtime is set to:',
                style: TextStyle(
                  color: widget.colorScheme.foregroundColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedTime,
                dropdownColor: widget.colorScheme.foregroundColor,
                items: times.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(
                      time,
                      style: TextStyle(
                          color: widget.colorScheme.backgroundColor,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select time',
                  hintStyle:
                  TextStyle(
                      color: widget.colorScheme.foregroundColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _updateBedtime,
                  child: Text(
                    'Update Bedtime',
                    style: TextStyle(
                        color: widget.colorScheme.backgroundColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 40),

// Update Caffeine Limit
              Text(
                'Set Your Caffeine Limit:',
                style: TextStyle(
                  color: widget.colorScheme.foregroundColor,
                  fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caffeineLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter caffeine limit (mg)',
                      ),
                      style: TextStyle(
                        color: widget.colorScheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: widget.colorScheme.foregroundColor),
                    onPressed: () {
                      showCaffeineHelp(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _updateCaffeineLimit();
                },
                child: Text(
                  'Update Caffeine Limit',
                  style: TextStyle(
                    color: widget.colorScheme.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 40),

// Update Hydration Goal
              Text(
                'Set Your Daily Hydration Goal:',
                style: TextStyle(
                  color: widget.colorScheme.foregroundColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hydrationGoalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter hydration goal (ml)',
                      ),
                      style: TextStyle(
                        color: widget.colorScheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: widget.colorScheme.foregroundColor),
                    onPressed: () {
                      showHydrationHelp(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _updateHydrationGoal();
                },
                child: Text(
                  'Update Daily Hydration Goal',
                  style: TextStyle(
                    color: widget.colorScheme.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 40),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    bool? confirmed = await showYesNoDialog(
                      context,
                      "Delete Account",
                      "Are you sure you want to delete your account? This action cannot be reversed.",
                    );

                    if (confirmed!) {
                      try {
                        final result = await UserAccountController()
                            .deleteAccount(context);

                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Account deleted successfully.')),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WelcomePage()),
                                (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: ${result['error']}')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to delete account. Please try again.')),
                        );
                        print("Error deleting account: $e");
                      }
                    }
                  },
                  child: Text('Delete Account',
                    style: TextStyle(
                        color: widget.colorScheme.backgroundColor,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
