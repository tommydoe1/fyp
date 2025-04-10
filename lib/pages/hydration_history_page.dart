import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/reusables.dart';
import '../controllers/database_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationHistoryPage extends StatefulWidget {
  final String uid;

  const HydrationHistoryPage({required this.uid});

  @override
  _HydrationHistoryPageState createState() => _HydrationHistoryPageState();
}

class _HydrationHistoryPageState extends State<HydrationHistoryPage> {
  final DatabaseController databaseController = DatabaseController();
  String _selectedConsumptionType = "Water Consumption";
  String _selectedTimeRange = "Last Week";
  List<Map<String, dynamic>> _hydrationLogs = [];
  List<Map<String, dynamic>> _allHydrationLogs = [];
  Map<String, double> _dailyConsumption = {};
  Map<String, int> _drinkTypeCounts = {};
  int _dailyGoal = 0;

  final List<String> consumptionTypes = ["Water Consumption", "Drink Type Consumption"];
  final List<String> timeRanges = ["Last Week", "Last Month", "Last Two Months", "Last Three Months"];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchData() async {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
      case "Last Month":
        startDate = now.subtract(Duration(days: 30));
        break;
      case "Last Two Months":
        startDate = now.subtract(Duration(days: 60));
        break;
      case "Last Three Months":
        startDate = now.subtract(Duration(days: 90));
        break;
      default:
        startDate = now.subtract(Duration(days: 7));
    }
    int? dailyGoal = await databaseController.getDailyGoal(widget.uid);

    List<Map<String, dynamic>> logs = await databaseController.getHydrationHistoryForPeriod(widget.uid, startDate, now);

    // Sort logs by timestamp in descending order (most recent first)
    logs.sort((a, b) {
      Timestamp timestampA = a['timeConsumed'];
      Timestamp timestampB = b['timeConsumed'];
      return timestampB.compareTo(timestampA); // Compare in descending order
    });

    // Check if widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      _hydrationLogs = logs;
      _dailyConsumption = databaseController.calculateDailyWaterConsumption(logs);
      _drinkTypeCounts = databaseController.calculateDrinkTypeCounts(logs);
      _dailyGoal = dailyGoal ?? 2000;
    });
  }

  void _fetchAllData() async {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 90)); // Last 3 months

    int? dailyGoal = await databaseController.getDailyGoal(widget.uid);

    List<Map<String, dynamic>> logs = await databaseController.getHydrationHistoryForPeriod(widget.uid, startDate, now);

    // Sort logs by timestamp in descending order (most recent first)
    logs.sort((a, b) {
      Timestamp timestampA = a['timeConsumed'];
      Timestamp timestampB = b['timeConsumed'];
      return timestampB.compareTo(timestampA);
    });

    if (!mounted) return;

    setState(() {
      _allHydrationLogs = logs; // Store all data
      _dailyGoal = dailyGoal ?? 2000;
    });

    // Apply initial filter (e.g., default to last 7 days)
    _filterData("Last Week");
  }

  void _filterData(String selectedRange) {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedRange) {
      case "Last Month":
        startDate = now.subtract(Duration(days: 30));
        break;
      case "Last Two Months":
        startDate = now.subtract(Duration(days: 60));
        break;
      case "Last Three Months":
        startDate = now.subtract(Duration(days: 90));
        break;
      default:
        startDate = now.subtract(Duration(days: 7));
    }

    List<Map<String, dynamic>> filteredLogs = _allHydrationLogs.where((log) {
      Timestamp logTime = log['timeConsumed'];
      return logTime.toDate().isAfter(startDate);
    }).toList();

    setState(() {
      _hydrationLogs = filteredLogs;
      _dailyConsumption = databaseController.calculateDailyWaterConsumption(filteredLogs);
      _drinkTypeCounts = databaseController.calculateDrinkTypeCounts(filteredLogs);
      _selectedTimeRange = selectedRange;
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hydroColorScheme.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _selectedConsumptionType,
                  dropdownColor: hydroColorScheme.backgroundColor,
                  style: TextStyle(
                      color: hydroColorScheme.foregroundColor,
                      fontWeight: FontWeight.bold
                  ),
                  items: consumptionTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: TextStyle(
                          color: hydroColorScheme.foregroundColor,
                          fontWeight: FontWeight.bold
                      )),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedConsumptionType = newValue!;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedTimeRange,
                  dropdownColor: hydroColorScheme.backgroundColor,
                  style: TextStyle(
                      color: hydroColorScheme.foregroundColor,
                      fontWeight: FontWeight.bold
                  ),
                  items: timeRanges.map((String range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range, style: TextStyle(
                          color: hydroColorScheme.foregroundColor,
                          fontWeight: FontWeight.bold
                      )),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTimeRange = newValue!;
                      _filterData(_selectedTimeRange);
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _selectedConsumptionType == "Water Consumption"
                  ? LayoutBuilder(
                builder: (context, constraints) {
                  return _buildWaterConsumptionGraph(context);
                },
              )
                  : BarChart(_buildDrinkTypeGraph()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recent Drinks",
              style: TextStyle(
                color: hydroColorScheme.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _hydrationLogs.length > 5 ? 5 : _hydrationLogs.length,
              itemBuilder: (context, index) {
                final log = _hydrationLogs[index];
                Timestamp timestamp = log['timeConsumed'];
                DateTime timeConsumed = timestamp.toDate();
                String formattedTime = DateFormat('MMM dd, yyyy h:mm a').format(timeConsumed);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hydroColorScheme.foregroundColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category: ${log['category']}",
                          style: TextStyle(color: hydroColorScheme.foregroundColor, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Water Content: ${log['waterContent']} ml",
                          style: TextStyle(color: hydroColorScheme.foregroundColor, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Time Consumed: $formattedTime", // Use the formatted time here
                          style: TextStyle(color: hydroColorScheme.foregroundColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  LayoutBuilder _buildWaterConsumptionGraph(BuildContext context) {
    final bars = <BarChartGroupData>[];
    final allDates = <DateTime>[];

    // Collect all dates in _dailyConsumption
    _dailyConsumption.keys.forEach((dateStr) {
      allDates.add(DateTime.parse(dateStr));
    });

    // Determine the date range
    DateTime now = DateTime.now();
    DateTime startDate = allDates.isEmpty
        ? now.subtract(Duration(days: 7)) // Default to last 7 days if no data
        : allDates.reduce((a, b) => a.isBefore(b) ? a : b); // Get oldest date

    if (_selectedTimeRange == 'Last Month') {
      startDate = now.subtract(Duration(days: 30));
    } else if (_selectedTimeRange == 'Last Two Months') {
      startDate = now.subtract(Duration(days: 60));
    } else if (_selectedTimeRange == 'Last Three Months') {
      startDate = now.subtract(Duration(days: 90));
    } else {
      startDate = now.subtract(Duration(days: 7));
    }

    // Create bars for the chosen date range
    for (DateTime date = startDate;
    date.isBefore(now.add(Duration(days: 1)));
    date = date.add(Duration(days: 1))) {
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      double waterAmount = _dailyConsumption[dateKey] ?? 0.0;

      bars.add(BarChartGroupData(
        x: date.millisecondsSinceEpoch,
        barRods: [
          BarChartRodData(
            toY: waterAmount,
            color: hydroColorScheme.foregroundColor,
            width: 10, // Adjusted dynamically below
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(color: Colors.black, width: 0.8),
          ),
        ],
      ));
    }

    bars.sort((a, b) => a.x.compareTo(b.x)); // Ensure bars are in time order

    if (bars.isEmpty) {
      bars.add(BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 0, color: Colors.transparent)],
      ));
    }

    final maxConsumption = _dailyConsumption.values.fold<num>(
        0, (prev, element) => element > prev ? element : prev);
    final maxY = max(maxConsumption, _dailyGoal + 500);

    return LayoutBuilder(
      builder: (context, constraints) {
        double chartWidth = constraints.maxWidth;
        int barCount = bars.length;
        double maxBarWidth = 20;
        double minBarWidth = 5;
        double barWidth = max(minBarWidth, min(maxBarWidth, chartWidth / (barCount * 2)));

        return BarChart(
          BarChartData(
            barGroups: bars.map((bar) {
              return BarChartGroupData(
                x: bar.x,
                barRods: [
                  BarChartRodData(
                    toY: bar.barRods[0].toY,
                    color: hydroColorScheme.foregroundColor,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: Colors.black, width: 0.8),
                  ),
                ],
              );
            }).toList(),
            alignment: BarChartAlignment.spaceBetween,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    int step = (barCount / 10).ceil();
                    int index = bars.indexWhere((bar) => bar.x == value.toInt());
                    bool showLabel = (index % step == 0);

                    return showLabel
                        ? Transform.rotate(
                      angle: barCount > 15 ? -pi / 4 : 0,
                      child: Text(
                        "${date.day}/${date.month}",
                        style: TextStyle(
                          color: hydroColorScheme.foregroundColor,
                          fontSize: _calculateFontSize(barCount),
                        ),
                      ),
                    )
                        : Container();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    "${value.toInt()} ml",
                    style: TextStyle(
                      color: hydroColorScheme.foregroundColor,
                      fontSize: _calculateFontSize(barCount),
                    ),
                  ),
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: _dailyGoal.toDouble(),
                  color: Colors.red,
                  strokeWidth: 2,
                  dashArray: [10, 5],
                  label: HorizontalLineLabel(
                    padding: EdgeInsets.all(6),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    alignment: Alignment.topCenter,
                    show: true,
                    labelResolver: (line) => 'Daily Goal: ${_dailyGoal.toInt()} ml',
                  ),
                ),
              ],
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: EdgeInsets.all(8),
                tooltipMargin: 8,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  DateTime date = DateTime.fromMillisecondsSinceEpoch(group.x.toInt());
                  String formattedDate = DateFormat('yyyy-MM-dd').format(date);

                  return BarTooltipItem(
                    '$formattedDate\n${rod.toY.toInt()} ml',
                    TextStyle(color: Colors.white),
                  );
                },
                tooltipBorder: BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              handleBuiltInTouches: true,
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              verticalInterval: 500,
              horizontalInterval: 500,
            ),
            minY: 0,
            maxY: maxY.toDouble(),
          ),
        );
      },
    );
  }

  double _calculateFontSize(int numberOfBars) {
    if (numberOfBars < 10) {
      return 14;
    } else if (numberOfBars < 30) {
      return 12;
    } else {
      return 10;
    }
  }

  BarChartData _buildDrinkTypeGraph() {
    // Sort the entries alphabetically by the drink type (key)
    final sortedEntries = _drinkTypeCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));  // Sort by key (alphabetically)

    // Create the bars based on sorted entries
    final barSpots = sortedEntries.asMap().map((index, entry) {
      return MapEntry(
          index,
          BarChartGroupData(
          x: index,  // Use the sorted index for x value
          barRods: [
          BarChartRodData(
          toY: entry.value.toDouble(),
      color: hydroColorScheme.foregroundColor,
      width: 20,
      borderRadius: BorderRadius.circular(5),
      ),
      ],
      )
      );
    }).values.toList();  // Convert to list

    return BarChartData(
      barGroups: barSpots,
      borderData: FlBorderData(show: true, border: Border.all(color: hydroColorScheme.foregroundColor)),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              int groupIndex = value.toInt();  // Use groupIndex for label
              return Text(
                sortedEntries[groupIndex].key,  // Display drink type (key) in alphabetical order
                style: TextStyle(color: hydroColorScheme.foregroundColor, fontSize: 12),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}', style: TextStyle(color: hydroColorScheme.foregroundColor, fontSize: 12));
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipPadding: EdgeInsets.all(8),
          tooltipMargin: 8,
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (group != null && rod != null) {
              return BarTooltipItem(
                '${sortedEntries[groupIndex].key}: ${rod.toY.toInt()}',
                TextStyle(color: Colors.white),
              );
            }
            return null;
          },
          tooltipBorder: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }



}
