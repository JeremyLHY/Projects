import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_app/modules/BudgetTracking/Expense/category_transaction.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';

class BreakdownPieChart extends StatefulWidget {
  const BreakdownPieChart({super.key});

  @override
  BreakdownPieChartPageState createState() => BreakdownPieChartPageState();
}

class BreakdownPieChartPageState extends State<BreakdownPieChart> {
  DateTime _selectedDate = DateTime.now();

  CategoryStyle getCategoryStyle(String category) {
    switch (category) {
      case "Food & Drinks":
        return CategoryStyle(icon: Icons.fastfood);
      case "Transport":
        return CategoryStyle(icon: Icons.directions_bus);
      case "Shopping":
        return CategoryStyle(icon: Icons.shopping_cart);
      case "Healthcare":
        return CategoryStyle(icon: Icons.health_and_safety);
      case "Groceries":
        return CategoryStyle(icon: Icons.local_grocery_store);
      case "Entertainment":
        return CategoryStyle(icon: Icons.movie);
      case "Bills & Fees":
        return CategoryStyle(icon: Icons.payments);
      case "Financial Goal":
        return CategoryStyle(icon: Icons.track_changes);
      default:
        return CategoryStyle(icon: Icons.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final databaseService = DatabaseService(uid: user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: databaseService.userInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null || !userData.containsKey('transactions')) {
          return const Center(child: Text('No transactions found.'));
        }

        final transactions = userData['transactions'] as Map<String, dynamic>;
        final filteredTransactions = _filterTransactionsByMonth(transactions);

        return Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDateFilterHeader(),
                const SizedBox(height: 16),
                _buildPieChartWithBreakdown(filteredTransactions),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
            onPressed: _showYearPicker,
          ),
        ],
      ),
    );
  }

  void _showYearPicker() async {
    int? selectedYear = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  "Select Year",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.vertical,
                  itemCount: 101,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Divider(),
                  ),
                  itemBuilder: (context, index) {
                    int year = 2025 + index;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, year),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Text(
                          year.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    // Check if the widget is still mounted before calling _showMonthPicker
    if (mounted && selectedYear != null) {
      _showMonthPicker(selectedYear);
    }
  }

  void _showMonthPicker(int year) {
    FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: _selectedDate.month - 1);
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Select Month"),
          content: SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 50,
                  left: 40,
                  right: 40,
                  child: Divider(thickness: 2, height: 2),
                ),
                Positioned(
                  bottom: 50,
                  left: 40,
                  right: 40,
                  child: Divider(thickness: 2, height: 2),
                ),
                ListWheelScrollView.useDelegate(
                  controller: monthController,
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  perspective: 0.005,
                  overAndUnderCenterOpacity: 0.5,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    childCount: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Set the text color to blue
              ),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate =
                      DateTime(year, monthController.selectedItem + 1, 1);
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Set the text color to blue
              ),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _filterTransactionsByMonth(
      Map<String, dynamic> transactions) {
    Map<String, List<Map<String, dynamic>>> filteredTransactions = {};

    transactions.forEach((category, transactionList) {
      if (category == "Income") return; // exclude the Income

      final filteredList = (transactionList as List)
          .map((e) => e as Map<String, dynamic>)
          .where((transaction) {
        final dynamic dateData = transaction['date'];
        DateTime transactionDate;

        if (dateData is Timestamp) {
          transactionDate = dateData.toDate();
        } else if (dateData is String) {
          transactionDate = DateTime.parse(dateData);
        } else {
          throw Exception('Unexpected date type');
        }

        return transactionDate.year == _selectedDate.year &&
            transactionDate.month == _selectedDate.month;
      }).toList();

      if (filteredList.isNotEmpty) {
        filteredTransactions[category] = filteredList;
      }
    });

    return filteredTransactions;
  }

  Map<String, double> _aggregateTransactionAmounts(
      Map<String, List<Map<String, dynamic>>> transactions) {
    Map<String, double> categoryTotals = {};

    transactions.forEach((categoryName, transactionList) {
      double categoryTotal = transactionList.fold(0.0, (total, transaction) {
        final amount = transaction['amount'];
        if (amount is int) {
          return total + amount.toDouble();
        } else if (amount is double) {
          return total + amount;
        } else {
          throw Exception('Invalid amount type: ${amount.runtimeType}');
        }
      });
      categoryTotals[categoryName] = categoryTotal;
    });

    return categoryTotals;
  }

  List<PieChartSectionData> _getChartSections(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final categoryTotals = _aggregateTransactionAmounts(transactions);
    final totalAmount =
        categoryTotals.values.fold(0.0, (total, amount) => total + amount);

    return categoryTotals.entries.map((entry) {
      final categoryTotalAmount = entry.value;
      final percentage = (categoryTotalAmount / totalAmount) * 100;
      return _createSection(percentage, _getCategoryColor(entry.key));
    }).toList();
  }

  PieChartSectionData _createSection(double value, Color color) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '',
      radius: 40,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCenterLabel(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final totalAmount = transactions.values
        .expand((transactionList) => transactionList)
        .fold(0.0, (total, transaction) {
      // Safely handle both int and double values
      final amount = transaction['amount'];
      if (amount is int) {
        return total + amount.toDouble(); // Convert int to double
      } else if (amount is double) {
        return total + amount; // Keep as double
      } else {
        throw Exception('Invalid amount type: ${amount.runtimeType}');
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Monthly Spending',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 8),
        Text(
          'RM ${totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPieChartWithBreakdown(
      Map<String, List<Map<String, dynamic>>> transactions) {
    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: _getChartSections(transactions),
                  centerSpaceRadius: 70,
                  sectionsSpace: 0,
                ),
              ),
              _buildCenterLabel(transactions),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCategoryBreakdownList(transactions),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & drinks':
        return Colors.blueAccent;
      case 'transport':
        return Color(0xFF1AAE48);
      case 'shopping':
        return Colors.redAccent;
      case 'entertainment':
        return Colors.orangeAccent;
      case 'utilities':
        return Colors.yellow;
      case 'health':
        return Colors.purple;
      case 'groceries':
        return Color(0xFFFF7043);
      case 'vehicle':
        return Colors.indigo;
      case 'rent/mortgage':
        return Colors.brown;
      case 'investment':
        return Colors.lime;
      case 'savings':
        return Colors.lightGreen;
      case 'debt':
        return Colors.pink;
      case 'education':
        return Colors.amber;
      case 'financial goal':
        return Colors.cyan;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  Widget _buildCategoryBreakdownList(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final categoryTotals = _aggregateTransactionAmounts(transactions);
    final totalAmount =
        categoryTotals.values.fold(0.0, (total, amount) => total + amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryTotals.length,
          itemBuilder: (context, index) {
            String category = categoryTotals.keys.elementAt(index);
            double totalSpent = categoryTotals[category]!;
            int transactionCount = transactions[category]!.length;
            double percentage =
                totalAmount > 0 ? (totalSpent / totalAmount) * 100 : 0;
            Color categoryColor = _getCategoryColor(category);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              child: Column(
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
                        getCategoryStyle(category).icon,
                        color: Colors.grey[800],
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'RM ${totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$transactionCount ${transactionCount == 1 ? 'transaction' : 'transactions'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (percentage / 100).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(categoryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTransactionsScreen(
                            category: category,
                            transactions: transactions[category]!,
                            selectedDate: _selectedDate,
                          ),
                        ),
                      );
                    },
                  ),
                  if (index < categoryTotals.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Divider(color: Colors.grey, thickness: 0.3),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CategoryStyle {
  final IconData icon;

  CategoryStyle({required this.icon});
}
