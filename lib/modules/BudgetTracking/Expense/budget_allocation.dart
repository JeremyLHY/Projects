import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/services/database.dart';
import 'package:provider/provider.dart';
import 'package:test_app/models/user.dart';

class BudgetAllocationPage extends StatefulWidget {
  const BudgetAllocationPage({super.key});

  @override
  State<BudgetAllocationPage> createState() => _BudgetAllocationPageState();
}

class _BudgetAllocationPageState extends State<BudgetAllocationPage> {
  double budgetAmount = 0.0;
  late List<Map<String, dynamic>> categories;

  Map<String, double> spendingPercentages = {};
  double totalPastSpending = 0.0;
  bool _hasAllocated = false; // Track allocation state

  Map<String, dynamic> _transactions = {}; // Store transactions in state

  final List<String> defaultCategories = [
    'Food & Drinks',
    'Transport',
    'Groceries',
    'Shopping',
    'Bills & Fees',
    'Entertainment',
  ];

  // Benchmark percentages based on financial guidelines
  final Map<String, double> categoryBenchmarks = {
    'Food & Drinks': 25.0,
    'Transport': 17.0,
    'Shopping': 8.0,
    'Entertainment': 8.0,
    'Bills & Fees': 17.0,
    'Groceries': 25.0,
  };

  @override
  void initState() {
    super.initState();
    // Initialize with default categories only
    categories = defaultCategories
        .map((category) => {
              'name': category,
              'progress': 0.0,
              'allocated': 0.0,
              'benchmark': categoryBenchmarks[category] ?? 0.0,
            })
        .toList();

    // Initialize spending percentages for default categories
    for (var category in defaultCategories) {
      spendingPercentages[category] = 0.0;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food & drinks':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills & fees':
        return Icons.lightbulb;
      case 'groceries':
        return Icons.local_grocery_store;
      default:
        return Icons.more_horiz;
    }
  }

  void _showNumpadDialog(BuildContext context) {
    TextEditingController amountController =
        TextEditingController(text: budgetAmount.toStringAsFixed(2));

    void addDigit(int digit) {
      String currentText =
          amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;
      currentValue = currentValue * 10 + digit;
      amountController.text = (currentValue / 100).toStringAsFixed(2);
    }

    void backspace() {
      String currentText =
          amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;
      currentValue = currentValue ~/ 10;
      amountController.text = (currentValue / 100).toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff222222),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amountController,
                      readOnly: true,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.backspace, color: Colors.redAccent),
                    onPressed: backspace,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildNumRow([1, 2, 3], addDigit),
                  _buildNumRow([4, 5, 6], addDigit),
                  _buildNumRow([7, 8, 9], addDigit),
                  _buildNumRow([0], addDigit),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => amountController.text = "0.00",
                    child: const Text("Clear",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        budgetAmount =
                            double.tryParse(amountController.text) ?? 0.0;
                        // Reset progress and allocated values
                        for (var category in categories) {
                          category['progress'] = 0.0;
                          category['allocated'] = 0.0;
                        }
                        // Trigger auto-allocation
                        _autoAllocateBudget();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Confirm",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumRow(List<int> numbers, Function(int) onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9, // Ensure it fits
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: numbers
            .map((number) => _buildNumpadButton(number, onPressed))
            .toList(),
      ),
    );
  }

  Widget _buildNumpadButton(int number, Function(int) onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 0.0), // Reduced padding
      child: SizedBox(
        width: 65, // Slightly reduced width
        height: 60,
        child: ElevatedButton(
          onPressed: () => onPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff444444),
            shadowColor: Colors.black54,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            "$number",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _analyzeSpending() {
    Map<String, double> categorySpending = {};
    double totalSpending = 0.0;

    // Initialize spending for default categories to 0
    for (var category in defaultCategories) {
      categorySpending[category] = 0.0;
    }

    // Analyze transactions only for default categories
    _transactions.forEach((category, transactionList) {
      // Check if category is in default categories
      if (defaultCategories.contains(category)) {
        if (transactionList is List) {
          double categoryTotal = 0.0;

          // Iterate through the transaction list and sum amounts
          for (var transaction in transactionList) {
            if (transaction is Map<String, dynamic>) {
              final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
              final transactionCategory = transaction['category'] as String?;

              // Skip 'Top-Up Wallet' and ensure valid category
              if (transactionCategory != null &&
                  transactionCategory != 'Top-Up Wallet') {
                categoryTotal += amount;
              }
            }
          }

          // Update categorySpending and totalSpending only if categoryTotal is greater than 0
          if (categoryTotal > 0) {
            categorySpending[category] = categoryTotal;
            totalSpending += categoryTotal;
          }
        }
      }
    });

    // Update spendingPercentages
    setState(() {
      spendingPercentages.clear();

      if (totalSpending > 0) {
        // Calculate percentages for categories with transactions
        categorySpending.forEach((category, amount) {
          spendingPercentages[category] = (amount / totalSpending) * 100;
        });
      } else {
        // Reset all categories to 0 if no transactions
        for (var category in defaultCategories) {
          spendingPercentages[category] = 0.0;
        }
      }
    });
  }

  void _autoAllocateBudget() {
    if (budgetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a budget amount first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Analyze spending only when allocating
    _analyzeSpending();

    setState(() {
      _hasAllocated = true;
      for (var category in categories) {
        final benchmark = categoryBenchmarks[category['name']] ?? 0.0;
        final allocation = (budgetAmount * benchmark) / 100;
        category['allocated'] = allocation;
        category['progress'] = allocation / budgetAmount;
      }
    });
  }

  Widget _buildProgressComparison(double pastValue, double benchmarkValue) {
    return Column(
      children: [
        _buildProgressBar(
          'Past Spending: ${_hasAllocated ? pastValue.toStringAsFixed(1) : '0.0'}%',
          _hasAllocated ? pastValue / 100 : 0.0,
          Colors.blueAccent,
        ),
        const SizedBox(height: 8),
        _buildProgressBar(
          'Recommended: ${_hasAllocated ? benchmarkValue.toStringAsFixed(1) : '0.0'}%',
          _hasAllocated ? benchmarkValue / 100 : 0.0,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Map<String, double> _calculateAverageAmounts() {
    Map<String, double> averages = {};
    if (budgetAmount <= 0) return averages;

    for (var category in categories) {
      final categoryName = category['name'];
      final benchmark = categoryBenchmarks[categoryName] ?? 0.0;
      averages[categoryName] = (budgetAmount * benchmark) / 100;
    }
    return averages;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);
    if (user == null) return const Center(child: CircularProgressIndicator());
    final databaseService = DatabaseService(uid: user.uid);

    // Calculate average amounts
    final averageAmounts = _calculateAverageAmounts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Budget Allocation'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: databaseService.userInfoStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          _transactions =
              userData?['transactions'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Text(
                  'RM${budgetAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text('Find out the best spending allocations'),
                const SizedBox(height: 20),
                // Allocate Fund Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showNumpadDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    label: const Text('Allocate Fund'),
                  ),
                ),
                const SizedBox(height: 20),
                // Reset Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.restart_alt, color: Colors.red),
                        label: const Text('Reset Allocations',
                            style: TextStyle(color: Colors.red)),
                        onPressed: _resetAllocation,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: categories
                        .map((category) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(_getCategoryIcon(category['name'])),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            if (_hasAllocated)
                                              Text(
                                                'RM${averageAmounts[category['name']]?.toStringAsFixed(2) ?? '0.00'}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildProgressComparison(
                                    spendingPercentages[category['name']] ??
                                        0.0,
                                    categoryBenchmarks[category['name']] ?? 0.0,
                                  ),
                                  const SizedBox(height: 10),
                                  const SizedBox(height: 20),
                                  Divider(color: Colors.grey, thickness: 0.3),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _resetAllocation() {
    setState(() {
      budgetAmount = 0.0;
      _hasAllocated = false;
      categories = defaultCategories
          .map((category) => {
                'name': category,
                'progress': 0.0,
                'allocated': 0.0,
                'benchmark': categoryBenchmarks[category] ?? 0.0,
              })
          .toList();
    });
  }
}
