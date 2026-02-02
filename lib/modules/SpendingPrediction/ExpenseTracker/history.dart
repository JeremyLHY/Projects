import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String monthYear;

  const HistoryPage({
    super.key,
    required this.transactions,
    required this.monthYear,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions - $monthYear"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) =>
            _buildTransactionItem(transactions[index], context),
      ),
    );
  }

  Widget _buildTransactionItem(
      Map<String, dynamic> transaction, BuildContext context) {
    final date = DateTime.parse(transaction['date']);
    final categoryColor = _getCategoryColor(transaction['category']);
    final lightColor = Color.alphaBlend(
      categoryColor.withAlpha(0x1A),
      Theme.of(context).colorScheme.surface,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withAlpha(0x1A),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  DateFormat('dd MMM yyyy - HH:mm').format(date),
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
}
