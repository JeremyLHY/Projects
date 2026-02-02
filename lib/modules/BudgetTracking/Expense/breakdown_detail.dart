import 'package:flutter/material.dart';
import 'package:test_app/modules/BudgetTracking/Expense/piechart_breakdown.dart';
// import 'package:test_app/modules/home/pie_chart.dart';

class BreakdownDetailPage extends StatelessWidget {
  const BreakdownDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Expense Breakdown'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          BreakdownPieChart(),
        ],
      ),
    );
  }
}
