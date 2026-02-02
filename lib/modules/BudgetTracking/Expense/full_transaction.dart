import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/modules/BudgetTracking/Expense/edit_transaction.dart';
import 'package:test_app/services/database.dart';
import 'package:intl/intl.dart';

class FullTransactionList extends StatefulWidget {
  final DatabaseService databaseService;

  const FullTransactionList({required this.databaseService, super.key});

  @override
  FullTransactionListState createState() => FullTransactionListState();
}

class FullTransactionListState extends State<FullTransactionList> {
  int _findOriginalIndex(Map<String, dynamic> transactions, String category,
      Map<String, dynamic> transaction) {
    final categoryTransactions = (transactions[category] as List?) ?? [];
    for (int i = 0; i < categoryTransactions.length; i++) {
      final tx = categoryTransactions[i] as Map<String, dynamic>;
      if (tx['amount'] == transaction['amount'] &&
          tx['date'] == transaction['date'] &&
          tx['time'] == transaction['time']) {
        return i;
      }
    }
    return 0; // fallback
  }

  DateTime _startDate = DateTime(2025); // Default: Show all transactions
  DateTime _endDate = DateTime.now(); // Set to current date and time

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  CategoryStyle getCategoryStyle(String category) {
    switch (category) {
      case "Food & Drinks":
        return CategoryStyle(icon: Icons.fastfood);
      case "Transport":
        return CategoryStyle(icon: Icons.directions_bus);
      case "Shopping":
        return CategoryStyle(icon: Icons.shopping_cart);
      case "Healthcare":
        return CategoryStyle(icon: Icons.local_hospital);
      case "Groceries":
        return CategoryStyle(icon: Icons.local_grocery_store);
      case "Entertainment":
        return CategoryStyle(icon: Icons.movie);
      case "Bills & Fees":
        return CategoryStyle(icon: Icons.electrical_services);
      case "Financial Goal":
        return CategoryStyle(icon: Icons.track_changes);
      default:
        return CategoryStyle(icon: Icons.category);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true, // allow full height with scrolling
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter by Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildFilterOption(
                      Icons.today, 'Today', () => _applyDateFilter(0)),
                  _buildFilterOption(Icons.calendar_today, 'Yesterday',
                      () => _applyDateFilter(1)),
                  _buildFilterOption(Icons.calendar_view_week, 'Last 7 Days',
                      () => _applyDateFilter(7)),
                  _buildFilterOption(Icons.calendar_view_month, 'Last 30 Days',
                      () => _applyDateFilter(30)),
                  _buildFilterOption(Icons.query_stats, 'Last 90 Days',
                      () => _applyDateFilter(90)),
                  _buildFilterOption(Icons.date_range, 'Custom Range',
                      _showCustomDateRangePicker),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _applyDateFilter(int days) {
    final now = DateTime.now();
    setState(() {
      if (days == 0) {
        // Today: from midnight today to midnight tomorrow
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (days == 1) {
        // Yesterday: from midnight yesterday to midnight today
        _startDate = DateTime(now.year, now.month, now.day - 1);
        _endDate = DateTime(now.year, now.month, now.day);
      } else {
        // Last X days: from midnight of (today - X + 1) to midnight tomorrow
        _startDate = DateTime(now.year, now.month, now.day - days + 1);
        _endDate = DateTime(now.year, now.month, now.day + 1);
      }
    });
  }

  Future<void> _showCustomDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            // ===== KEY FIX =====
            colorScheme: const ColorScheme.light(
              primary: Colors.black, // Selected date text color

              onSurface: Colors.black, // Unselected text
              // Range highlight customization:
              primaryContainer: Color(0xFFE0E0E0), // Light grey for range
              onPrimaryContainer: Colors.black, // Text in range
            ),
            // ===================
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Buttons color
              ),
            ),
            // Force material defaults to use your scheme
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  bool _isDateInRange(DateTime date) {
    // All time check (if start is 2015 and end is far future)
    if (_startDate.year == 2015 && _endDate.year > 2100) {
      return true;
    }
    // Check if date is within [startDate, endDate)
    return date.compareTo(_startDate) >= 0 && date.compareTo(_endDate) < 0;
  }

  Widget _buildDateFilterHeader() {
    final isShowingAll = _startDate == DateTime(2015) &&
        _endDate == DateTime.now().add(Duration(days: 365));

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _showFilterBottomSheet, // Make the whole row tappable
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isShowingAll
                    ? 'All Transactions'
                    : _startDate.isAtSameMomentAs(_endDate)
                        ? _dateFormat.format(_startDate)
                        : '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
              Icon(Icons.arrow_drop_down,
                  color: Colors.blue[800]), // Removed IconButton
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildDateFilterHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: widget.databaseService.userInfoStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null ||
                      !userData.containsKey('transactions')) {
                    return const Center(child: Text('No transactions found.'));
                  }

                  final transactions =
                      userData['transactions'] as Map<String, dynamic>;

                  final safeTransactions =
                      transactions.map((category, transactionList) {
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
                    return const Center(child: Text('No transactions found.'));
                  }

                  flattenedTransactions.sort((a, b) {
                    DateTime dateA = _parseDate(a['date']);
                    DateTime dateB = _parseDate(b['date']);
                    return dateB.compareTo(dateA);
                  });

                  final filteredTransactions = flattenedTransactions.where((t) {
                    final date = _parseDate(t['date']);
                    return _isDateInRange(date);
                  }).toList();

                  if (filteredTransactions.isEmpty) {
                    return const Center(
                      child: Text('No transactions in selected date range.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final amount = transaction['amount'];
                      final category = transaction['category'];
                      final date = _parseDate(transaction['date']);
                      final time = transaction['time'];
                      final categoryStyle = getCategoryStyle(category);

                      return GestureDetector(
                        onTap: () {
                          final originalIndex = _findOriginalIndex(
                              transactions, category, transaction);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTransactionPage(
                                transactionData: {
                                  'transactionIndex': originalIndex,
                                  'category': category,
                                  'amount': amount,
                                  'date': date.toString(),
                                  'time': time,
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      categoryStyle.icon,
                                      size: 20.0,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              category,
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              category == "Income"
                                                  ? '+RM${amount.toStringAsFixed(2)}'
                                                  : '-RM${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w500,
                                                color: category == "Income"
                                                    ? Colors.blueAccent
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  $time',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: Colors.grey, thickness: 0.5),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic date) {
    if (date is String) return DateTime.parse(date);
    if (date is Timestamp) return date.toDate();
    return DateTime.now();
  }
}

class CategoryStyle {
  final IconData icon;

  CategoryStyle({required this.icon});
}
