import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/reusables.dart';
import '../controllers/database_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaffeineHistoryPage extends StatefulWidget {
  final String uid;

  const CaffeineHistoryPage({required this.uid});

  @override
  _CaffeineHistoryPageState createState() => _CaffeineHistoryPageState();
}

class _CaffeineHistoryPageState extends State<CaffeineHistoryPage> {
  final DatabaseController databaseController = DatabaseController();
  String _selectedConsumptionType = "Caffeine Consumption";
  String _selectedTimeRange = "Last Week";
  List<Map<String, dynamic>> _caffeineLogs = [];
  List<Map<String, dynamic>> _allCaffeineLogs = [];
  Map<String, double> _dailyConsumption = {};
  Map<String, int> _itemTypeCounts = {};
  double dailyCaffeineLimit = 400; // Recommended daily caffeine limit in mg

  final List<String> consumptionTypes = ["Caffeine Consumption", "Item Type Consumption"];
  final List<String> timeRanges = ["Last Week", "Last Month", "Last Two Months", "Last Three Months"];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
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

    List<Map<String, dynamic>> logs = await databaseController.getCaffeineHistoryForPeriod(widget.uid, startDate, now);

    if (!mounted) return;

    setState(() {
      _caffeineLogs = logs;
      _dailyConsumption = databaseController.calculateDailyCaffeineConsumption(logs);
      _itemTypeCounts = databaseController.calculateItemTypeCounts(logs);
    });
  }

  void _fetchAllData() async {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 90));

    List<Map<String, dynamic>> logs = await databaseController.getCaffeineHistoryForPeriod(widget.uid, startDate, now);


    logs.sort((a, b) {
      Timestamp timestampA = a['timeConsumed'];
      Timestamp timestampB = b['timeConsumed'];
      return timestampB.compareTo(timestampA);
    });

    if (!mounted) return;

    setState(() {
      _allCaffeineLogs = logs; // Store all data
    });

    // Apply default filter of last week
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

    List<Map<String, dynamic>> filteredLogs = _allCaffeineLogs.where((log) {
      Timestamp logTime = log['timeConsumed'];
      return logTime.toDate().isAfter(startDate);
    }).toList();

    setState(() {
      _caffeineLogs = filteredLogs;
      _dailyConsumption = databaseController.calculateDailyCaffeineConsumption(filteredLogs);
      _itemTypeCounts = databaseController.calculateItemTypeCounts(filteredLogs);
      _selectedTimeRange = selectedRange;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cafColorScheme.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _selectedConsumptionType,
                  dropdownColor: cafColorScheme.backgroundColor,
                  style: TextStyle(
                      color: cafColorScheme.foregroundColor,
                      fontWeight: FontWeight.bold
                  ),
                  items: consumptionTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: TextStyle(
                          color: cafColorScheme.foregroundColor,
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
                  dropdownColor: cafColorScheme.backgroundColor,
                  style: TextStyle(
                      color: cafColorScheme.foregroundColor,
                      fontWeight: FontWeight.bold
                  ),
                  items: timeRanges.map((String range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range, style: TextStyle(
                          color: cafColorScheme.foregroundColor,
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
              child: _selectedConsumptionType == "Caffeine Consumption"
                  ? LayoutBuilder(
                builder: (context, constraints) {
                  return _buildCaffeineConsumptionHistogram(context);
                },
              )
                  : BarChart(_buildItemTypeGraph()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recent Items",
              style: TextStyle(
                color: cafColorScheme.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _caffeineLogs.length > 5 ? 5 : _caffeineLogs.length,
              itemBuilder: (context, index) {
                final log = _caffeineLogs[index];
                Timestamp timestamp = log['timeConsumed'];
                DateTime timeConsumed = timestamp.toDate();
                String formattedTime = DateFormat('MMM dd, yyyy h:mm a').format(timeConsumed);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cafColorScheme.foregroundColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${log['name']}",
                          style: TextStyle(color: cafColorScheme.foregroundColor, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Caffeine Content: ${log['caffeineContent']} mg",
                          style: TextStyle(color: cafColorScheme.foregroundColor, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Time Consumed: $formattedTime",
                          style: TextStyle(color: cafColorScheme.foregroundColor, fontSize: 14),
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

  LayoutBuilder _buildCaffeineConsumptionHistogram(BuildContext context) {
    final bars = <BarChartGroupData>[];
    final allDates = <DateTime>[];

    _dailyConsumption.keys.forEach((dateStr) {
      allDates.add(DateTime.parse(dateStr));
    });

    DateTime now = DateTime.now();
    DateTime startDate = allDates.isEmpty
        ? now.subtract(Duration(days: 7)) // Default to last 7 days if no data
        : allDates.reduce((a, b) => a.isBefore(b) ? a : b); // Get oldest date

    // Adjust the date range according to the selected period (week, month, etc.)
    if (_selectedTimeRange == 'Last Week') {
      startDate = now.subtract(Duration(days: 7));
    } else if (_selectedTimeRange == 'Last Month') {
      startDate = DateTime(now.year, now.month - 1, now.day);
    } else if (_selectedTimeRange == 'Last Two Months') {
      startDate = DateTime(now.year, now.month - 2, now.day);
    } else if (_selectedTimeRange == 'Last Three Months') {
      startDate = DateTime(now.year, now.month - 3, now.day);
    }

    // Create bars for the chosen date range
    for (DateTime date = startDate;
    date.isBefore(now.add(Duration(days: 1)));
    date = date.add(Duration(days: 1))) {
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      double caffeineAmount = _dailyConsumption[dateKey] ?? 0;

      bars.add(BarChartGroupData(
        x: date.millisecondsSinceEpoch,
        barRods: [
          BarChartRodData(
            toY: caffeineAmount,
            color: cafColorScheme.foregroundColor,
            width: 10,
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(color: Colors.black, width: 0.8),
          ),
        ],
      ));
    }

    bars.sort((a, b) => a.x.compareTo(b.x)); // Sort bars by time

    if (bars.isEmpty) {
      bars.add(BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 0, color: Colors.transparent)],
      ));
    }

    final maxConsumption = _dailyConsumption.values.fold<num>(
        0, (prev, element) => element > prev ? element : prev);
    final maxY = max(maxConsumption, dailyCaffeineLimit + 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        double chartWidth = constraints.maxWidth; // Get chart width dynamically
        int barCount = bars.length;
        double maxBarWidth = 20;
        double minBarWidth = 5;
        double barWidth =
        max(minBarWidth, min(maxBarWidth, chartWidth / (barCount * 2)));

        return BarChart(
          BarChartData(
            barGroups: bars.map((bar) {
              return BarChartGroupData(
                x: bar.x,
                barRods: [
                  BarChartRodData(
                    toY: bar.barRods[0].toY,
                    color: cafColorScheme.foregroundColor,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: Colors.black, width: 0.8),
                  ),
                ],
              );
            }).toList(),
            alignment: BarChartAlignment.spaceBetween, // Ensures bars do not overflow
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    int step = (barCount / 10).ceil(); // Reduce label density dynamically
                    int index = bars.indexWhere((bar) => bar.x == value.toInt());
                    bool showLabel = (index % step == 0);

                    return showLabel
                        ? Transform.rotate(
                      angle: barCount > 15 ? -pi / 4 : 0, // Rotate if many labels
                      child: Text(
                        "${date.day}/${date.month}",
                        style: TextStyle(
                          color: cafColorScheme.foregroundColor,
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
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) => Text(
                    "${value.toInt()}mg",
                    style: TextStyle(
                      color: cafColorScheme.foregroundColor,
                      fontSize: _calculateFontSize(barCount),
                    ),
                  ),
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: dailyCaffeineLimit,
                  color: Colors.red,
                  strokeWidth: 2,
                  dashArray: [10, 5],
                  label: HorizontalLineLabel(
                    padding: EdgeInsets.all(6),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    alignment: Alignment.topCenter,
                    show: true,
                    labelResolver: (line) => 'Caffeine Limit: ${dailyCaffeineLimit} mg',
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
                    '$formattedDate\n${rod.toY.toInt()} mg',
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
              verticalInterval: 50,
              horizontalInterval: 50,
            ),
            minY: 0,
            maxY: maxY.toDouble(),
          ),
        );
      },
    );
  }

// Dynamically adjust font size for labels
  double _calculateFontSize(int numberOfBars) {
    if (numberOfBars < 10) {
      return 14;
    } else if (numberOfBars < 30) {
      return 12;
    } else {
      return 10;
    }
  }



  BarChartData _buildItemTypeGraph() {
    // Sort the item counts alphabetically by the keys (item names)
    final sortedEntries = _itemTypeCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final bars = sortedEntries.asMap().map((index, entry) {
      return MapEntry(
        index,
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: cafColorScheme.foregroundColor,
              width: 20,
              borderRadius: BorderRadius.circular(5),
              rodStackItems: [],
              backDrawRodData: BackgroundBarChartRodData(show: false),
            )
          ],
          showingTooltipIndicators: [],
        ),
      );
    }).values.toList();

    if (bars.isEmpty) {
      bars.add(BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 0, color: Colors.transparent)],
      ));
    }

    final maxItem = _itemTypeCounts.values.fold<num>(
        0, (prev, element) => element > prev ? element : prev);
    final maxYValue = max(maxItem, 8);

    // Calculate an appropriate step based on the maxYValue
    int step = 1;
    if (maxYValue > 10) {
      step = (maxYValue / 10).ceil();
    }

    final itemCount = sortedEntries.length;
    int maxLength = 10; // Default length for item names
    if (itemCount > 10) {
      maxLength = (20 / itemCount).ceil(); // Dynamically shorten the name as there are more items
    }

    return BarChartData(
      barGroups: bars,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final yValue = value.toInt();
              if (yValue % step == 0 && yValue >= 0 && yValue <= maxYValue) {
                return Text(
                  "$yValue",
                  style: TextStyle(color: cafColorScheme.foregroundColor, fontSize: 12),
                );
              }
              return Container();
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt() % itemCount;
              final fullName = sortedEntries[index].key;

              // Shorten name based on maxLength
              final shortenedName = fullName.length > maxLength
                  ? '${fullName.substring(0, maxLength)}...'
                  : fullName;

              return Text(
                shortenedName, // Display shortened name if necessary
                style: TextStyle(
                  color: cafColorScheme.foregroundColor,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis, // Ensure the text doesn't overflow
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        verticalInterval: 1,
        horizontalInterval: 1,
      ),
      minY: 0,
      maxY: maxYValue.toDouble(),
    );
  }
}
