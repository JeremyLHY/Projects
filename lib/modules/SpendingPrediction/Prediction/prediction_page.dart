import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  Map<String, double> predictions = {};
  String errorMessage = '';
  bool isLoading = false;
  String predictedMonth = '';
  double totalPredicted = 0.0;

  Future<String> getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  String getNextMonth() {
    DateTime now = DateTime.now();
    DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
    return DateFormat('MMM yyyy').format(nextMonth);
  }

  Future<void> fetchPredictions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
        predictions = {};
        totalPredicted = 0.0;
      });

      String userId = await getUserId();
      if (userId.isEmpty) throw "No user logged in";

      String nextMonth = getNextMonth();
      setState(() => predictedMonth = nextMonth);

      final response = await http.post(
        Uri.parse('http://172.20.10.2:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        predictions = data.map((k, v) => MapEntry(k, v.toDouble()));
        totalPredicted = predictions.values.fold(0.0, (a, b) => a + b);
      } else if (response.statusCode == 404) {
        errorMessage = json.decode(response.body)['error'];
      } else {
        throw "Failed to load predictions";
      }
    } catch (e) {
      errorMessage = "Failed to fetch predictions. Please try again.";
      log("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & drinks':
        return Colors.blueAccent;
      case 'groceries':
        return const Color(0xFFFF7043);
      case 'entertainment':
        return Colors.orangeAccent;
      case 'bills & fees':
        return Colors.greenAccent;
      case 'transport':
        return Colors.indigoAccent;
      case 'shopping':
        return Colors.pinkAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  Widget _buildPredictionItem(String category, double amount) {
    final percentage = totalPredicted > 0 ? (amount / totalPredicted) * 100 : 0;
    final categoryColor = _getCategoryColor(category);
    final lightColor = Color.alphaBlend(
      categoryColor.withAlpha(0x1A),
      Theme.of(context).colorScheme.surface,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).dividerColor.withAlpha(0x1A),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
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
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}% of total',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'RM${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Predictions'),
        elevation: 0,
        centerTitle: true,
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: fetchPredictions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Generate Predictions',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // In the build method's predictions.isNotEmpty section
          if (predictions.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(0x1A),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Predicted for',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            predictedMonth,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM${totalPredicted.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Add spacing before the list
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                itemCount: predictions.length,
                itemBuilder: (context, index) => _buildPredictionItem(
                  predictions.keys.elementAt(index),
                  predictions.values.elementAt(index),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
