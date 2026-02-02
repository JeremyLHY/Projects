import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<String> availableMonths = [];
  String? selectedMonth;
  Map<String, double> actualExpenses = {};
  Map<String, double> predictedExpenses = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableMonths();
  }

  Future<void> _fetchAvailableMonths() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('Spendlys')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final transactions = data['transactions'] as Map<String, dynamic>?;
    if (transactions == null) return;

    Set<String> monthsSet = {};

    transactions.forEach((category, expenses) {
      if (category == 'Income') return;
      if (expenses is List) {
        for (var expense in expenses) {
          if (expense is Map<String, dynamic> && expense.containsKey('date')) {
            String dateStr = expense['date'];
            try {
              DateTime date = DateTime.parse(dateStr);
              String monthYear =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}";
              monthsSet.add(monthYear);
            } catch (e) {
              // Invalid date
            }
          }
        }
      }
    });

    List<String> monthsList = monthsSet.toList();
    monthsList.sort((a, b) => b.compareTo(a));
    setState(() {
      availableMonths = monthsList;
      if (monthsList.isNotEmpty) {
        selectedMonth = monthsList.first;
        _fetchData(selectedMonth!);
      }
    });
  }

  Future<void> _fetchData(String selectedMonth) async {
    setState(() => isLoading = true);

    // Fetch actual expenses
    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) return;
    final databaseService = DatabaseService(uid: user.uid);
    try {
      actualExpenses = await databaseService.fetchExpenses(selectedMonth);
    } catch (e) {
      // Handle error
    }

    // Fetch predicted expenses
    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.2:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        predictedExpenses = data.map((k, v) => MapEntry(k, v.toDouble()));
      }
    } catch (e) {
      // Handle error
    }

    setState(() => isLoading = false);
  }

  Widget _buildPredictionBadge() {
    final totalActual = actualExpenses.values.fold(0.0, (a, b) => a + b);
    final totalPredicted = predictedExpenses.values.fold(0.0, (a, b) => a + b);
    final difference = totalPredicted - totalActual;
    final percentage = totalActual != 0
        ? (difference.abs() / totalActual * 100).abs()
        : totalPredicted != 0
            ? 100.0
            : 0.0;

    final isPositive = difference >= 0;
    final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final emoji = isPositive ? '🔼' : '🔽';
    final changeText = isPositive ? 'Predicted Increase' : 'Predicted Decrease';
    final formattedAmount = NumberFormat.currency(
      symbol: 'RM',
      decimalDigits: difference.abs() >= 1 ? 0 : 2,
    ).format(difference.abs());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16, color: color)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isPositive ? '+' : '-'}$formattedAmount (${percentage.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                changeText,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(double actual, double predicted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Actual Total:   ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: NumberFormat.currency(symbol: 'RM', decimalDigits: 2)
                      .format(actual),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Predicted Total: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: NumberFormat.currency(symbol: 'RM', decimalDigits: 2)
                      .format(predicted),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ChartData> chartData = [];
    Set<String> allCategories = {
      ...actualExpenses.keys,
      ...predictedExpenses.keys
    };
    for (var category in allCategories) {
      chartData.add(ChartData(
        category,
        actualExpenses[category] ?? 0.0,
        predictedExpenses[category] ?? 0.0,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analytics Chart'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.white,
            height: 2.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedMonth,
              hint: const Text('Select Month'),
              onChanged: (newValue) {
                setState(() => selectedMonth = newValue!);
                _fetchData(newValue!);
              },
              items: availableMonths.map((monthYear) {
                DateTime date = DateTime.parse('$monthYear-01');
                String display = DateFormat('MMM yyyy').format(date);
                return DropdownMenuItem(
                  value: monthYear,
                  child: Text(display),
                );
              }).toList(),
            ),
            if (selectedMonth != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Predicted for ${_getPredictedMonthLabel()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actualExpenses.isNotEmpty && predictedExpenses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPredictionBadge(),
                            const SizedBox(width: 16),
                            _buildTotals(
                              actualExpenses.values.fold(0.0, (a, b) => a + b),
                              predictedExpenses.values
                                  .fold(0.0, (a, b) => a + b),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SfCartesianChart(
                            primaryXAxis: CategoryAxis(
                              labelStyle: const TextStyle(fontSize: 12),
                              arrangeByIndex: true,
                              autoScrollingMode: AutoScrollingMode.start,
                              autoScrollingDelta: 1,
                              edgeLabelPlacement: EdgeLabelPlacement.shift,
                            ),
                            primaryYAxis: NumericAxis(
                              edgeLabelPlacement: EdgeLabelPlacement.shift,
                            ),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePanning: true,
                              enablePinching: true,
                              zoomMode: ZoomMode.x,
                            ),
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                            margin: const EdgeInsets.only(
                                bottom: 60, left: 10, right: 10),
                            series: <ColumnSeries<ChartData, String>>[
                              ColumnSeries<ChartData, String>(
                                width: 0.4,
                                spacing: 0.1,
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) =>
                                    data.category,
                                yValueMapper: (ChartData data, _) =>
                                    data.actual,
                                name: 'Actual',
                                color: Colors.blue,
                                dataLabelMapper: (ChartData data, _) =>
                                    NumberFormat.currency(
                                            symbol: 'RM', decimalDigits: 0)
                                        .format(data.actual),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600),
                                  labelAlignment: ChartDataLabelAlignment.top,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                              ),
                              ColumnSeries<ChartData, String>(
                                width: 0.4,
                                spacing: 0.1,
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) =>
                                    data.category,
                                yValueMapper: (ChartData data, _) =>
                                    data.predicted,
                                name: 'Predicted',
                                color: Colors.orange,
                                dataLabelMapper: (ChartData data, _) =>
                                    NumberFormat.currency(
                                            symbol: 'RM', decimalDigits: 0)
                                        .format(data.predicted),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600),
                                  labelAlignment: ChartDataLabelAlignment.top,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _getPredictedMonthLabel() {
  try {
    DateTime currentDate = DateTime.now();
    DateTime predictedDate =
        DateTime(currentDate.year, currentDate.month + 1, 1);
    return DateFormat('MMM yyyy').format(predictedDate);
  } catch (e) {
    return 'next month';
  }
}

class ChartData {
  final String category;
  final double actual;
  final double predicted;

  ChartData(this.category, this.actual, this.predicted);
}
