import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/modules/BudgetTracking/Expense/edit_transaction.dart';
import 'package:test_app/services/database.dart';

class RecentTransactionList extends StatefulWidget {
  final DatabaseService databaseService;

  const RecentTransactionList({super.key, required this.databaseService});

  @override
  State<RecentTransactionList> createState() => _RecentTransactionListState();
}

class _RecentTransactionListState extends State<RecentTransactionList> {
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
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.databaseService.userInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null || !userData.containsKey('transactions')) {
          return const Center(child: Text('No transactions found.'));
        }

        final transactions = userData['transactions'] as Map<String, dynamic>;

        List<Map<String, dynamic>> flattenedTransactions = [];
        transactions.forEach((category, transactionList) {
          if (transactionList is List) {
            flattenedTransactions.addAll(
                transactionList.map((e) => e as Map<String, dynamic>).toList());
          }
        });

        if (flattenedTransactions.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        }

        flattenedTransactions.sort((a, b) {
          DateTime fullDateTimeA, fullDateTimeB;

          var dateA = a['date'];
          var dateB = b['date'];
          var timeA = a['time'];
          var timeB = b['time'];

          if (dateA is String) {
            dateA = DateTime.parse(dateA);
          } else if (dateA is Timestamp) {
            dateA = dateA.toDate();
          }

          if (dateB is String) {
            dateB = DateTime.parse(dateB);
          } else if (dateB is Timestamp) {
            dateB = dateB.toDate();
          }

          if (timeA is String && timeA.isNotEmpty) {
            final cleanedTimeA =
                timeA.replaceAll(" AM", "").replaceAll(" PM", "").trim();
            final timePartsA = cleanedTimeA.split(":");
            int hour = int.parse(timePartsA[0]);
            int minute = int.parse(timePartsA[1]);
            if (timeA.contains("PM") && hour != 12) hour += 12;
            fullDateTimeA =
                DateTime(dateA.year, dateA.month, dateA.day, hour, minute);
          } else {
            fullDateTimeA = dateA;
          }

          if (timeB is String && timeB.isNotEmpty) {
            final cleanedTimeB =
                timeB.replaceAll(" AM", "").replaceAll(" PM", "").trim();
            final timePartsB = cleanedTimeB.split(":");
            int hour = int.parse(timePartsB[0]);
            int minute = int.parse(timePartsB[1]);
            if (timeB.contains("PM") && hour != 12) hour += 12;
            fullDateTimeB =
                DateTime(dateB.year, dateB.month, dateB.day, hour, minute);
          } else {
            fullDateTimeB = dateB;
          }

          return fullDateTimeB.compareTo(fullDateTimeA);
        });

        final recentTransactions = flattenedTransactions.take(3).toList();

        return SingleChildScrollView(
          child: Column(
            children: recentTransactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isLast = index == recentTransactions.length - 1;

              final amount = transaction['amount'];
              final category = transaction['category'];

              var date = transaction['date'];
              if (date is String) {
                date = DateTime.parse(date);
              } else if (date is Timestamp) {
                date = date.toDate();
              }

              final time = transaction['time'];

              final categoryLower = category.toString().toLowerCase().trim();
              final isIncome = categoryLower == 'income';
              final transactionWidget = Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 10.0, top: 3.0),
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
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    isIncome
                                        ? '+RM${amount.toStringAsFixed(2)}'
                                        : '-RM${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                      color: isIncome
                                          ? Colors.blueAccent
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}   $time',
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
                    if (!isLast)
                      const Divider(color: Colors.grey, thickness: 0.3),
                  ],
                ),
              );

              return isIncome
                  ? transactionWidget
                  : GestureDetector(
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
                      child: transactionWidget,
                    );
            }).toList(),
          ),
        );
      },
    );
  }
}
