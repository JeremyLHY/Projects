import 'package:flutter/material.dart';
import 'package:test_app/modules/BudgetTracking/Bill/bill_history.dart';
import 'package:test_app/modules/BudgetTracking/Bill/bill_details.dart';
import 'package:provider/provider.dart';

import 'package:test_app/models/user.dart';
import 'package:test_app/modules/BudgetTracking/Bill/bill_stream.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  String selectedButton = 'Upcoming'; // Default selected button

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bill Tracking',
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // Navigate to History Page
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BillHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedButton = 'Upcoming'; // Change selected button
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: selectedButton == 'Upcoming'
                            ? Colors.black
                            : Colors.grey, // Highlight the selected button
                        foregroundColor: Colors.white, // Text color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Upcoming',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis, // Prevents overflow
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Reduce space to fit better
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedButton = 'Overdue'; // Change selected button
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: selectedButton == 'Overdue'
                            ? Colors.black
                            : Colors.grey, // Highlight the selected button
                        foregroundColor: Colors.white, // Text color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis, // Prevents overflow
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keeps the column size minimal
                children: [
                  // Conditional UI for Upcoming or Overdue
                  if (selectedButton == 'Upcoming')
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.black),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BillDetailsPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.3),
                              ),
                              label: const Text(
                                'CREATE BILL REMINDER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const UpcomingBills(),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: const [
                        SizedBox(height: 20),
                        OverdueBills(), // Now only appears in Overdue section
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
