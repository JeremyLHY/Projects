import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CategoryTransactionsScreen extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> transactions;
  final DateTime selectedDate;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.transactions,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title:
            Text('$category - ${DateFormat('MMM yyyy').format(selectedDate)}'),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions found.'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 15),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                dynamic dateData = transaction['date'];
                DateTime date;

                if (dateData is Timestamp) {
                  date = dateData.toDate();
                } else if (dateData is String) {
                  date = DateTime.parse(dateData);
                } else {
                  throw Exception('Invalid date format');
                }

                final time = transaction['time'] ?? '';
                final amount = transaction['amount'] ?? 0.0;
                final notes = transaction['notes'] ?? '';
                final category = transaction['category'] ?? '';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
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
                                  ? const Color(0xFF1AAE48)
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (notes.isNotEmpty)
                            Expanded(
                              child: Text(
                                notes,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  $time',
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                          color: Colors.grey, thickness: 0.3, height: 0),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
