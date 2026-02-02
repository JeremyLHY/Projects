import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/modules/wrapper.dart';
import 'dart:developer';
import '../WidgetServices/pie_chart_widget.dart';
import 'package:provider/provider.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:intl/intl.dart';
import 'package:test_app/modules/SpendingPrediction/ExpenseTracker/history.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expenses> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, double> monthlyExpenses = {};
  bool isLoading = true;
  String selectedMonthYear = '';
  DateTime _selectedDate = DateTime.now();

  bool isDetailsVisible = false;
  List<Map<String, dynamic>> transactions = [];

  // Fetch user ID from Firebase Authentication
  Future<String> getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      log("Error parsing date: $e");
      return '';
    }
  }

  Future<void> _loadExpenses() async {
    final user = Provider.of<CustomUser?>(context, listen: false);

    if (user == null) {
      log("User not logged in. Cannot load expenses.");
      return;
    }

    final databaseService = DatabaseService(uid: user.uid);

    setState(() {
      isLoading = true;
    });

    try {
      monthlyExpenses = await databaseService.fetchExpenses(selectedMonthYear);
    } catch (e) {
      log("Error fetching expenses: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedMonthYear =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";
    _loadExpenses();
  }

  // Function to show the date picker for filtering by month and year
  void _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate:
          DateTime(now.year, now.month), // Limit to current month and year
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        selectedMonthYear =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";
        isLoading = true;
      });
      _loadExpenses();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & drinks':
        return const Color(0xFF4CAF50); // Soft Green
      case 'groceries':
        return const Color(0xFF8D6E63); // Muted Brown
      case 'entertainment':
        return const Color(0xFFFFA726); // Warm Orange
      case 'bills & fees':
        return const Color(0xFF43A047); // Muted Green
      case 'shopping':
        return const Color(0xFF7E57C2); // Soft Purple
      case 'transport':
        return const Color(0xFF0288D1); // Soft Blue
      case 'healthcare':
        return const Color(0xFF00897B); // Muted Teal
      default:
        return const Color(0xFF5E35B1); // Soft Purple for default
    }
  }

  CategoryStyle getCategoryStyle(String category) {
    switch (category) {
      case "Food & Drinks":
        return CategoryStyle(icon: Icons.fastfood);
      case "Groceries":
        return CategoryStyle(icon: Icons.local_grocery_store);
      case "Entertainment":
        return CategoryStyle(icon: Icons.movie);
      case "Healthcare":
        return CategoryStyle(icon: Icons.local_hospital);
      case "Transport":
        return CategoryStyle(icon: Icons.directions_car);
      case "Shopping":
        return CategoryStyle(icon: Icons.shopping_bag);
      case "Bills & Fees":
        return CategoryStyle(icon: Icons.account_balance_wallet);
      default:
        return CategoryStyle(icon: Icons.category);
    }
  }

  Widget _buildTransactionItem(
      Map<String, dynamic> transaction, BuildContext context) {
    final dateTime = DateTime.parse(transaction['date']);
    final formattedDateTime =
        DateFormat('dd MMM yyyy - HH:mm').format(dateTime);
    final categoryColor = _getCategoryColor(transaction['category']);

    final lightColor = Color.alphaBlend(
        categoryColor.withAlpha(30), Theme.of(context).colorScheme.surface);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            spreadRadius: 0.2,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(transaction['category']),
              color: categoryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['category'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDateTime,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "RM${transaction['amount']?.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Exit'),
          content:
              const Text('Do you want to go back to the expense tracker app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Expenses"),
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 60,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onPrimary, // Set text color to white
          fontSize:
              24, // Adjust the text size as needed (24 is just an example)
          fontWeight: FontWeight.bold, // Optional: Make the text bold
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(2.0), // Set the height of the line
          child: Container(
            color: Colors.white, // Set the color of the line to white
            height: 2.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              bool? shouldExit = await _confirmExit(context);
              if (shouldExit ?? false) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Wrapper(),
                  ),
                );
              }
            },
            child: const Text(
              "Back",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Allow the page to be scrollable
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Month: ${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_drop_down), // Down arrow icon
                        Text(
                            "${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : monthlyExpenses.isNotEmpty
                      ? PieChartWidget(monthlyExpenses: monthlyExpenses)
                      : Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.pie_chart_outline,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No data available for $selectedMonthYear',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              children: [
                                TextButton(
                                  onPressed: _pickDate,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: const Text('Try another month'),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
            // View Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isDetailsVisible = !isDetailsVisible;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isDetailsVisible ? 'Hide Details' : 'View Details',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isDetailsVisible
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (isDetailsVisible && monthlyExpenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Breakdown',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...monthlyExpenses.entries.map((entry) {
                      final totalAmount = monthlyExpenses.values
                          .fold(0.0, (total, item) => total + item);
                      final percentage = (entry.value / totalAmount) * 100;
                      final categoryStyle = getCategoryStyle(entry.key);

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                categoryStyle.icon,
                                color: Colors.grey[800],
                                size: 20,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text('RM${entry.value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (percentage / 100).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCategoryColor(entry.key)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 24, thickness: 0.5),
                        ],
                      );
                    }),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: getUserId().asStream().asyncExpand((userId) {
                      if (userId.isNotEmpty) {
                        return db
                            .collection('Spendlys')
                            .doc(userId)
                            .snapshots();
                      }
                      return const Stream.empty();
                    }),
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      // Error/no data state
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                            child: Text('No transactions found'));
                      }

                      // Get data with null safety
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};

                      // Process transactions
                      final transactions =
                          data['transactions'] as Map<String, dynamic>? ?? {};
                      final effectiveData =
                          transactions.isNotEmpty ? transactions : data;

                      List<Map<String, dynamic>> allTransactions = [];
                      List<Widget> transactionWidgets = [];

                      // Inside the StreamBuilder's transaction processing loop
                      effectiveData.forEach((category, rawExpenses) {
                        if (category == "Income") return;
                        final expenses =
                            (rawExpenses is List) ? rawExpenses : [];

                        for (var expense in expenses) {
                          try {
                            dynamic dateValue = expense['date'];
                            dynamic timeValue = expense['time'];

                            DateTime expenseDateTime;

                            // Handle Firestore Timestamp
                            if (dateValue is Timestamp) {
                              expenseDateTime = dateValue.toDate();
                            }
                            // Handle String date
                            else if (dateValue is String) {
                              // Normalize spaces to dots in the time component (e.g., "2025-04-04T05:19:45 625479" → "2025-04-04T05:19:45.625479")
                              String normalizedDate =
                                  dateValue.replaceAll(' ', '.');

                              // Check if date already contains time
                              if (normalizedDate.contains('T')) {
                                expenseDateTime =
                                    DateTime.parse(normalizedDate);
                              } else {
                                // Combine date and time fields
                                String dateTimeStr =
                                    '${normalizedDate}T$timeValue';
                                expenseDateTime = DateTime.parse(dateTimeStr);
                              }
                            } else {
                              throw FormatException('Unsupported date format');
                            }

                            final monthYear =
                                "${expenseDateTime.year}-${expenseDateTime.month.toString().padLeft(2, '0')}";

                            final transactionWithId = {
                              ...expense,
                              'uid':
                                  '${expense['date']}${expense['time']}${expense['amount']}'
                            };

                            if (monthYear == selectedMonthYear) {
                              allTransactions.add({
                                ...transactionWithId,
                                'date': expenseDateTime.toIso8601String(),
                                'category': expense['category'] ?? category,
                              });
                            }
                          } catch (e) {
                            debugPrint('Error processing transaction: $e');
                          }
                        }
                      });

                      // Sort transactions by date descending
                      allTransactions.sort((a, b) => DateTime.parse(b['date'])
                          .compareTo(DateTime.parse(a['date'])));

                      // Take first 3 transactions
                      final recentTransactions =
                          allTransactions.take(3).toList();

                      // Build transaction items
                      for (var transaction in recentTransactions) {
                        transactionWidgets
                            .add(_buildTransactionItem(transaction, context));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row with View All
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Transactions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (allTransactions.length > 3 &&
                                    allTransactions.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HistoryPage(
                                            transactions: allTransactions,
                                            monthYear: selectedMonthYear,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          'View All',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.blue[700],
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Transaction List
                          Column(children: transactionWidgets),
                        ],
                      );
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Drinks':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills & Fees':
        return Icons.account_balance_wallet;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Entertainment':
        return Icons.movie;
      case 'Groceries':
        return Icons.local_grocery_store;
      default:
        return Icons.description;
    }
  }
}

class CategoryStyle {
  final IconData icon;
  CategoryStyle({required this.icon});
}
