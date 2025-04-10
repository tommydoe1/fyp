import 'package:flutter/material.dart';
import '../widgets/neutral_base_page.dart';
import '../controllers/user_account_controller.dart';
import '../controllers/caffeine_page_controller.dart';
import '../widgets/reusables.dart';
import '../pages/menu_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final UserAccountController _accountController = UserAccountController();

  String _selectedHeightUnit = 'Centimetres';
  String _selectedWeightUnit = 'Kilograms (kg)';

  // Add a state variable to track password visibility
  bool _isPasswordVisible = false;

  void _onSignupSuccess(BuildContext context, String uid) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MenuPage(uid: uid),
      ),
    );
  }

  Future<void> _signup(BuildContext context) async {
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String height = _heightController.text.trim();
    double weight = double.tryParse(_weightController.text.trim()) ?? 0;

    // Validation
    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        height.isEmpty ||
        weight <= 0) {
      showErrorDialog(context, 'Please fill in all fields correctly.');
      return;
    }

    // Height conversion to meters
    double heightInMeters;
    if (_selectedHeightUnit == 'Feet & Inches') {
      List<String> heightParts = height.split("'"); // Example: "5'11"
      if (heightParts.length == 2) {
        int feet = int.tryParse(heightParts[0]) ?? 0;
        int inches = int.tryParse(heightParts[1]) ?? 0;
        heightInMeters = ((feet * 12) + inches) * 0.0254;
      } else {
        showErrorDialog(context, "Please enter height in Feet & Inches format (e.g., 5'11).");
        return;
      }
    } else {
      heightInMeters = double.tryParse(height) ?? 0;
      heightInMeters /= 100; // Convert cm to meters
    }

    // Weight conversion to kilograms
    double weightInKg = _selectedWeightUnit == 'Pounds (lbs)' ? weight * 0.453592 : weight;

    var result = await _accountController.signUp(
      email: email,
      password: password,
      username: username,
      height: double.parse(heightInMeters.toStringAsFixed(2)),
      weight: weightInKg,
      context: context,
    );

    if (result['success']) {
      _onSignupSuccess(context, result['uid']);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color dropdownBackgroundColor = Color(0xFFEAE0D5);
    const Color dropdownTextColor = Color(0xFF22333B);

    return NeutralPage(
      title: 'Sign up',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Toggle obscureText
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _heightController,
                decoration: InputDecoration(labelText: 'Height'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedHeightUnit,
                dropdownColor: dropdownBackgroundColor,
                decoration: const InputDecoration(labelText: 'Height Unit'),
                items: [
                  DropdownMenuItem(
                    value: 'Feet & Inches',
                    child: Text(
                      'Feet & Inches',
                      style: TextStyle(color: dropdownTextColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Centimetres',
                    child: Text(
                      'Centimetres',
                      style: TextStyle(color: dropdownTextColor),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedHeightUnit = value!;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedWeightUnit,
                dropdownColor: dropdownBackgroundColor,
                decoration: const InputDecoration(labelText: 'Weight Unit'),
                items: [
                  DropdownMenuItem(
                    value: 'Kilograms (kg)',
                    child: Text(
                      'Kilograms (kg)',
                      style: TextStyle(color: dropdownTextColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Pounds (lbs)',
                    child: Text(
                      'Pounds (lbs)',
                      style: TextStyle(color: dropdownTextColor),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWeightUnit = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => _signup(context),
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
