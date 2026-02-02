import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/services/database.dart';
import 'package:provider/provider.dart';
import 'package:test_app/models/user.dart';
import 'package:intl/intl.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({super.key});

  @override
  ExpensePieChartState createState() => ExpensePieChartState();
}

class ExpensePieChartState extends State<ExpensePieChart> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
  }

  @override
  Widget build(BuildContext context) {
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

        final currentMonthTransactions =
            _filterCurrentMonthTransactions(safeTransactions);
        final categoryTotals =
            _aggregateTransactionAmounts(currentMonthTransactions);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPieChartWithCenterLabel(currentMonthTransactions),
            SizedBox(height: 100),
            _buildLegend(categoryTotals),
          ],
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _filterCurrentMonthTransactions(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    return transactions.map((category, transactionList) {
      //exclude Income
      if (category == "Income") {
        return MapEntry(category, <Map<String, dynamic>>[]);
      }

      final filteredTransactions = transactionList.where((transaction) {
        if (!transaction.containsKey('date')) return false;
        final transactionDate = DateTime.parse(transaction['date']);
        return DateFormat('yyyy-MM').format(transactionDate) == currentMonth;
      }).toList();

      return MapEntry(category, filteredTransactions);
    });
  }

  Widget _buildPieChartWithCenterLabel(
      Map<String, List<Map<String, dynamic>>> transactions) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildPieChart(transactions),
          _buildCenterLabel(transactions),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, List<Map<String, dynamic>>> transactions) {
    return PieChart(
      PieChartData(
        sections: _getChartSections(transactions),
        centerSpaceRadius: 70,
        sectionsSpace: 0,
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
      swapAnimationCurve: Curves.easeInOutQuint,
    );
  }

  List<PieChartSectionData> _getChartSections(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final categoryTotals = _aggregateTransactionAmounts(transactions);
    final totalAmount =
        categoryTotals.values.fold(0.0, (total, amount) => total + amount);

    return categoryTotals.entries.map((entry) {
      final categoryTotalAmount = entry.value;
      final badgeText = _selectedCategory == entry.key
          ? 'RM ${categoryTotalAmount.toStringAsFixed(2)}'
          : '';
      return _createSection(
        (categoryTotalAmount / totalAmount) * 100,
        _getCategoryColor(entry.key),
        entry.key,
        badgeText,
        categoryTotalAmount,
      );
    }).toList();
  }

  Map<String, double> _aggregateTransactionAmounts(
      Map<String, List<Map<String, dynamic>>> transactions) {
    Map<String, double> categoryTotals = {};

    transactions.forEach((category, transactionList) {
      double categoryTotal = 0.0;
      for (var transaction in transactionList) {
        if (transaction['amount'] is int) {
          categoryTotal += (transaction['amount'] as int).toDouble();
        } else if (transaction['amount'] is double) {
          categoryTotal += transaction['amount'] as double;
        }
      }
      categoryTotals[category] = categoryTotal;
    });

    return categoryTotals;
  }

  PieChartSectionData _createSection(double value, Color color, String title,
      String badgeText, double categoryTotalAmount) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '', // Empty string for non-selected categories
      titleStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      badgeWidget: _selectedCategory == title
          ? Text(
              badgeText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : SizedBox.shrink(), // Only show badge if selected
      badgePositionPercentageOffset: 1.5,
    );
  }

  Widget _buildCenterLabel(
      Map<String, List<Map<String, dynamic>>> transactions) {
    final totalAmount = transactions.values
        .expand((transactionList) => transactionList)
        .fold(0.0, (total, transaction) {
      return total + (transaction['amount'] ?? 0.0);
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Monthly',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        ),
        Text(
          'Spending',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        ),
        SizedBox(height: 5),
        Text(
          'RM ${totalAmount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegend(Map<String, double> categoryTotals) {
    final categoriesWithValues =
        categoryTotals.entries.where((entry) => entry.value > 0).toList();
    final totalAmount =
        categoryTotals.values.fold(0.0, (total, value) => total + value);

    return SizedBox(
      height: 120, // Slightly increased height for better spacing
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: categoriesWithValues.length,
        itemBuilder: (context, index) {
          final entry = categoriesWithValues[index];
          final percentage = (entry.value / totalAmount) * 100;
          return _buildLegendItem(
            _getCategoryColor(entry.key),
            entry.key,
            _getCategoryIcon(entry.key),
            '${percentage.toStringAsFixed(1)}%', // One decimal place is cleaner
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(
      Color color, String title, IconData icon, String percentage) {
    final isSelected = _selectedCategory == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () =>
            setState(() => _selectedCategory = isSelected ? null : title),
        child: Container(
          width: 120, // Increased width to accommodate longer titles
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.2 : 0.8,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Expanded(
                // Use Expanded to allow the title to take available space
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2, // Allow up to 2 lines
                  overflow:
                      TextOverflow.visible, // Show full text without clipping
                ),
              ),
              const SizedBox(height: 4),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.trim().toLowerCase()) {
      // Normalize string for comparison
      case 'food & drinks':
        return Colors.blue;
      case 'transport':
        return Color(0xFF1AAE48);
      case 'shopping':
        return Colors.redAccent;
      case 'entertainment':
        return Colors.orange;
      case 'bills & fees':
        return Colors.yellow;
      case 'healthcare':
        return Colors.purple;
      case 'groceries':
        return Color(0xFFFF7043); // Teal 800
      case 'financial goal':
        return Colors.cyan;
      default:
        return Colors.tealAccent; // Fallback color
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.trim().toLowerCase()) {
      // Normalize string for comparison
      case 'food & drinks':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills & fees':
        return Icons.payments;
      case 'healthcare':
        return Icons.health_and_safety;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'financial goal':
        return Icons.track_changes;
      default:
        return Icons.more_horiz; // Fallback icon
    }
  }
}
