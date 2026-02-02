import 'package:flutter/material.dart';
import 'package:test_app/modules/SpendingPrediction/ExpenseTracker/expense_tracker.dart';
import 'package:test_app/modules/SpendingPrediction/Prediction/prediction_page.dart';
import 'package:test_app/modules/SpendingPrediction/Analytics/analytics.dart';

class BottomNavWrapper extends StatefulWidget {
  final int initialIndex;
  const BottomNavWrapper({super.key, this.initialIndex = 0});

  @override
  State<BottomNavWrapper> createState() => _BottomNavWrapperState();
}

class _BottomNavWrapperState extends State<BottomNavWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Function to handle BottomNavigationBar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of pages for each BottomNavBar item
  final List<Widget> _pages = [
    Expenses(), // Page for Expenses
    PredictionPage(), // Page for Prediction
    AnalyticsPage(), // Page for Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Prediction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Trend',
            ),
          ],
        ),
      ),
    );
  }
}
