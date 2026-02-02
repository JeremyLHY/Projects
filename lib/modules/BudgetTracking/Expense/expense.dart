import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_app/models/user.dart';
import 'package:test_app/modules/BudgetTracking/Expense/breakdown_detail.dart';
import 'package:test_app/modules/BudgetTracking/Expense/budget_allocation.dart';
import 'package:test_app/modules/BudgetTracking/Expense/full_transaction.dart';
import 'package:test_app/modules/BudgetTracking/Expense/prediction_navigation.dart';
import 'package:test_app/modules/BudgetTracking/Expense/recent_transaction_list.dart';
import 'package:test_app/services/auth.dart';
import 'package:test_app/shared/numpad.dart';
import 'package:test_app/shared/numpad_for_transaction.dart';
import 'pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:test_app/services/database.dart';
import 'package:intl/intl.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final databaseService = DatabaseService(uid: user.uid);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    // final themeProvider = Provider.of<ThemeProvider>(context);
    // bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final theme = Theme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: Container(
          color: Colors.white, // Ensure background is pure white
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                child: Text(
                  'Menu',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
              ListTile(
                leading: Icon(Icons.insights, color: theme.iconTheme.color),
                title: Text('Spending Prediction',
                    style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpendingPredictionIntroPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: theme.iconTheme.color),
                title: Text('Logout', style: theme.textTheme.bodyLarge),
                onTap: () async => await _auth.signOut(),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: databaseService.userInfoStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (snapshot.hasData) {
                                  final accountBalance =
                                      (snapshot.data?['accountBalance'] as Map<
                                              String, dynamic>?)?['amount'] ??
                                          0.0;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'RM ${accountBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right:
                                                    12.0), // 👈 Add space from right edge
                                            child: IconButton(
                                              icon: Icon(Icons.menu,
                                                  color: Colors.white,
                                                  size: 30),
                                              onPressed: () => scaffoldKey
                                                  .currentState
                                                  ?.openDrawer(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => NumpadPage()),
                                            ),
                                            child: Text('+ Add Money'),
                                          ),
                                          SizedBox(width: 50),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return Text('No data available',
                                    style: TextStyle(color: Colors.white));
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 190,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMenuButton(Icons.attach_money, 'Add Expense',
                              NumpadfortransactionPage()),
                          SizedBox(width: 70.0),
                          _buildMenuButton(Icons.lightbulb, 'Budget Allocation',
                              BudgetAllocationPage()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60),
            Padding(
              padding:
                  EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 25),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM y').format(DateTime.now()),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BreakdownDetailPage()),
                                );
                              },
                              icon: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.blueAccent,
                              ), // Add an arrow icon
                              label: Text(
                                'Show more',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black, // Text color
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors
                                    .transparent, // Transparent background
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 50.0),
                        ExpensePieChart(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          spreadRadius: 4,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 20, color: Colors.black),
                              SizedBox(width: 8),
                              Text('Recent Transactions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2)),
                              Spacer(),
                              InkWell(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullTransactionList(
                                          databaseService: databaseService),
                                    )),
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        decoration: TextDecoration
                                            .underline, // This will underline the text
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: Colors.black,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.grey[200], height: 1),
                        SizedBox(height: 16),
                        RecentTransactionList(databaseService: databaseService),
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

  Widget _buildMenuButton(IconData icon, String text, Widget page) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      child: Column(
        children: [
          Icon(icon, size: 25.0, color: theme.iconTheme.color),
          SizedBox(height: 5.0),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
