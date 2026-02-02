import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/modules/BudgetTracking/Budget/edit_budget.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetDetailPage extends StatefulWidget {
  final Map<String, dynamic> budgetData;

  const BudgetDetailPage({super.key, required this.budgetData});

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  late Map<String, dynamic> _currentBudgetData;

  @override
  void initState() {
    super.initState();
    _currentBudgetData = widget.budgetData;
  }

  @override
  Widget build(BuildContext context) {
    String budgetName = widget.budgetData['name'] ?? 'Unnamed Budget';
    double budgetAmount = widget.budgetData['amount']?.toDouble() ?? 0.0;
    double spentAmount =
        widget.budgetData['progressSpending']?.toDouble() ?? 0.0;

    double remainingAmount = budgetAmount - spentAmount;
    double progress = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(budgetName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit), // Trash can icon
            onPressed: () {
              _showOptionsBottomSheet(context, widget.budgetData);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Period

            const SizedBox(height: 10),

            // Budget Overview Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Budget Header with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Budget Overview",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.account_balance_wallet, color: Colors.black),
                      ],
                    ),
                    Divider(),
                    const SizedBox(height: 10),

                    // 🔹 Total Budget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Budget:",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "RM${budgetAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    // 🔹 Spent Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Spent:",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "-RM${spentAmount.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),

                    // 🔹 Remaining Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Remaining:",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "RM${remainingAmount.toStringAsFixed(2)}",
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF1AAE48)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Gradient Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          progress >= 1
                              ? Colors.redAccent
                              : (progress > 0.8
                                  ? Colors.orangeAccent
                                  : Color(0xFF1AAE48)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Add Funds Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showNumpadDialog(context, widget.budgetData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  minimumSize: const Size(350, 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: const Icon(
                  Icons.add,
                  color: Colors.blueAccent,
                ),
                label: const Text('Add Funds',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // Transactions Header
            const Text("Transactions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            Expanded(
              child: _buildTransactionList(context, widget.budgetData),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumpadDialog(
      BuildContext context, Map<String, dynamic> budgetData) {
    TextEditingController amountController =
        TextEditingController(text: '0.00');

    String budgetName = budgetData['name'] ?? 'Unnamed Budget';
    double budgetAmount = budgetData['amount']?.toDouble() ?? 0.0;
    double spentAmount = budgetData['progressSpending']?.toDouble() ?? 0.0;
    double remainingAmount = budgetAmount - spentAmount;

    bool isCompleted = spentAmount >= budgetAmount;
    if (isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Unable to add more funds, Budget has reached its limit')),
      );
      return;
    }

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

    void submitAmount() async {
      double addedAmount = double.tryParse(amountController.text) ?? 0.0;

      if (addedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      if (addedAmount > remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add in funds that exceed the remaining amount of RM${remainingAmount.toStringAsFixed(2)} left.',
            ),
          ),
        );
        return;
      }

      final user = Provider.of<CustomUser?>(context, listen: false);
      if (user != null) {
        final databaseService = DatabaseService(uid: user.uid);

        try {
          String budgetCategory = budgetData['category'];
          await databaseService.addMoneyToBudget(
              budgetCategory, budgetName, addedAmount, budgetData);

          if (mounted) {
            setState(() {
              _currentBudgetData['progressSpending'] =
                  (_currentBudgetData['progressSpending'] ?? 0.0) + addedAmount;
            });
          }

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Added RM ${addedAmount.toStringAsFixed(2)} to your budget!'),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient balance in wallet.')),
          );
        }
      }
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.backspace,
                        size: 30, color: Colors.blueAccent),
                    onPressed: backspace,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [1, 4, 7]
                        .map((i) => _buildNumRow([i, i + 1, i + 2], addDigit))
                        .toList() +
                    [
                      _buildNumRow([0], addDigit)
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
                    onPressed: submitAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((number) => _buildNumpadButton(number, onPressed))
          .toList(),
    );
  }

  Widget _buildNumpadButton(int number, Function(int) onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: SizedBox(
        width: 65,
        height: 65,
        child: ElevatedButton(
          onPressed: () => onPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff444444),
            shadowColor: Colors.black54,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("$number",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(
      BuildContext context, Map<String, dynamic> budgetData) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose an action',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Options List
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Budget'),
                onTap: () {
                  Navigator.pop(context); // Close BottomSheet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          EditBudgetPage(budgetData: budgetData),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Budget'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context,
                      budgetData); // Pass budgetData instead of just budgetName
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> budgetData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this goal?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the confirmation dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.blueAccent, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () async {
                final user = Provider.of<CustomUser?>(context, listen: false);
                if (user == null) return;

                final databaseService = DatabaseService(uid: user.uid);

                // Extract category and name from budgetData
                String budgetCategory = budgetData['category'];
                String budgetName = budgetData['name'];

                await databaseService.deleteBudget(budgetCategory, budgetName);

                Navigator.pop(context); // Close the dialog after deletion

                // Then pop back to the main budget page
                Navigator.pop(context);
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.blueAccent, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime _parseDate(dynamic date) {
    if (date is String) return DateTime.parse(date);
    if (date is Timestamp) return date.toDate();
    return DateTime.now();
  }

  bool _isDateInRange(DateTime date) {
    DateTime startDate = DateTime(2024); // Default: Show all transactions
    DateTime endDate = DateTime.now().add(Duration(days: -1));
    // Check if "All" filter is active
    if (startDate == DateTime(2015) &&
        endDate == DateTime.now().add(Duration(days: 365))) {
      return true;
    }
    return date.isAfter(startDate.subtract(Duration(days: 1))) &&
        date.isBefore(endDate.add(Duration(days: 1)));
  }

  Widget _buildTransactionList(
      BuildContext context, Map<String, dynamic> budgetData) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final databaseService = DatabaseService(uid: user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: databaseService.userInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null || !userData.containsKey('transactions')) {
          return Center(child: Text('No transactions found.'));
        }

        final transactions = userData['transactions'] as Map<String, dynamic>;

        final safeTransactions = transactions.map((category, transactionList) {
          return MapEntry(
            category,
            (transactionList as List)
                .map((e) => e as Map<String, dynamic>)
                .toList(),
          );
        });

        List<Map<String, dynamic>> flattenedTransactions = [];
        safeTransactions.forEach((category, categoryTransactions) {
          flattenedTransactions.addAll(categoryTransactions);
        });

        if (flattenedTransactions.isEmpty) {
          return Center(child: Text('No transactions found.'));
        }

        // 🔍 Filter transactions to only include those with the tapped 'budgetName'
        final transactionsWithBudget = flattenedTransactions
            .where((transaction) =>
                transaction.containsKey('budgetName') &&
                transaction['budgetName'] == budgetData['name'])
            .toList();

        if (transactionsWithBudget.isEmpty) {
          return Center(child: Text('No budget-related transactions found.'));
        }

        // 🔄 Sort transactions by date
        transactionsWithBudget.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        // 📆 Apply date filtering
        final filteredTransactions = transactionsWithBudget.where((t) {
          final date = _parseDate(t['date']);
          return _isDateInRange(date);
        }).toList();

        if (filteredTransactions.isEmpty) {
          return Center(child: Text('No transactions in selected date range.'));
        }

        return SingleChildScrollView(
          child: Column(
            children: filteredTransactions.map((transaction) {
              final amount = transaction['amount'];
              final category = transaction['budgetName'];

              // Handle date field
              var date = transaction['date'];
              if (date is String) {
                date = DateTime.parse(date);
              } else if (date is Timestamp) {
                date = date.toDate();
              }

              final time = transaction['time'] ?? '';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    category == "Top-Up Wallet"
                                        ? '+RM${amount.toStringAsFixed(2)}'
                                        : '-RM${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                      color: category == "Top-Up Wallet"
                                          ? Color(0xFF1AAE48)
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 7),
                              Row(
                                children: [
                                  Text(
                                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}   $time',
                                    style: TextStyle(
                                        fontSize: 14.0, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey, thickness: 0.2),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
