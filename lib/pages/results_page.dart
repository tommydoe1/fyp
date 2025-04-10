import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/caffeine_base_page.dart';
import '../widgets/reusables.dart';
import '../controllers/database_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultsPage extends StatefulWidget {
  final String uid;

  ResultsPage({required this.uid});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final DatabaseController _databaseController = DatabaseController();
  DateTime? _endTime;
  String? _lastConsumedItem;
  DateTime? _lastConsumedTime;
  late Timer _timer;
  Duration? _timeRemaining;
  int _totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();

    // Set up a periodic timer to update the countdown every second
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_endTime != null && mounted) {
        setState(() {
          _timeRemaining = _endTime!.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch the caffeine end time, total minutes, and last consumed item
      DateTime? endTime = await _databaseController.getCaffeineEndTime(widget.uid);
      int? totalMinutes = await _databaseController.getTotalMinutes(widget.uid);
      Map<String, dynamic>? lastItem = await _databaseController.getLastItem(widget.uid);

      if (mounted) {
        setState(() {
          _endTime = endTime;
          _totalMinutes = totalMinutes ?? 0;
          _timeRemaining = endTime?.difference(DateTime.now());

          if (lastItem != null) {
            _lastConsumedItem = lastItem['name'];
            _lastConsumedTime = (lastItem['timeConsumed'] as Timestamp).toDate();
          } else {
            _lastConsumedItem = null;
            _lastConsumedTime = null;
          }
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CaffeinePage(
      title: 'Time Remaining',
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Text
            Text(
              'You have:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: caramel,
              ),
              textAlign: TextAlign.center,
            ),

            // Time Remaining
            Text(
              _endTime == null || _endTime!.isBefore(DateTime.now())
                  ? 'No time remaining!'
                  : _formatDuration(_timeRemaining!),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: caramel,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Until you have a caffeine crash!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: caramel,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Circular Progress Indicator
            if (_endTime != null && _endTime!.isAfter(DateTime.now()))
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _calculateProgress(_timeRemaining!), // Calculate progress dynamically
                        strokeWidth: 10,
                        backgroundColor: Color(0xFFEAE0D5),
                        valueColor: AlwaysStoppedAnimation<Color>(caramel),
                      ),
                    ),
                    // Percentage Text in the Middle
                    Text(
                      '${(_calculateProgress(_timeRemaining!) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: caramel,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 40),

            // Bottom Text
            Text(
              'You last consumed:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: caramel,
              ),
            ),
            SizedBox(height: 10),

            // Last Consumed Item and Time
            Text(
              _lastConsumedItem != null && _lastConsumedTime != null
                  ? '$_lastConsumedItem at ${_formatTime(_lastConsumedTime!)}'
                  : 'You\'ve not consumed any items on the app yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: caramel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Progress calculation function for CircularProgressIndicator
  double _calculateProgress(Duration remainingTime) {
    if (_totalMinutes == 0) return 0.0; // Avoid division by zero
    final remainingMinutes = remainingTime.inMinutes;
    return remainingMinutes / _totalMinutes;
  }

  /// Formats a duration into a readable string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours hours and $minutes minutes';
  }

  /// Formats a DateTime object into a readable time string
  String _formatTime(DateTime time) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(time);
  }
}
