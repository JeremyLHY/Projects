import 'package:flutter/material.dart';
import 'package:test_app/models/user.dart';
import 'package:test_app/services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillHistoryPage extends StatefulWidget {
  const BillHistoryPage({super.key});

  @override
  State<BillHistoryPage> createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bill History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body:
          user == null ? _buildErrorState() : _buildMainContent(context, user),
    );
  }

  Widget _buildMainContent(BuildContext context, CustomUser user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService(uid: user.uid).userInfoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                Text('Loading history...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    )),
              ],
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.data() == null) {
          return _buildErrorState();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final bills = userData['billReminders'] as Map<String, dynamic>?;

        if (bills == null || bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text('No payment history found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    )),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> flattenedBills = [];

        bills.forEach((billName, billData) {
          if (billData is Map<String, dynamic> && billData['status'] == true) {
            flattenedBills.add({
              'billName': billName,
              'billAmount': billData['billAmount'],
              'dueDate': billData['dueDate'],
              'status': billData['status'],
            });
          }
        });

        if (flattenedBills.isEmpty) {
          return Center(
              child: Text('No bills history activities.',
                  style: TextStyle(color: Colors.grey[600])));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: flattenedBills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final billData = flattenedBills[index];
            double billAmount = (billData['billAmount'] ?? 0).toDouble();

            // Date parsing
            String formattedDate = "No Date";
            var dateRaw = billData['dueDate'];
            if (dateRaw is Timestamp) {
              final date = dateRaw.toDate();
              formattedDate = "${date.day}/${date.month}/${date.year}";
            } else if (dateRaw is String) {
              formattedDate = dateRaw;
            }

            return GestureDetector(
              onTap: () => _showDeleteBottomSheet(
                context,
                DatabaseService(uid: user.uid),
                billData,
              ),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    billData['billName'] ?? 'Unnamed Bill',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'RM${billAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid on $formattedDate',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.blueAccent, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Completed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteBottomSheet(
    BuildContext context,
    DatabaseService databaseService,
    Map<String, dynamic> billData,
  ) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // Fixed typo: was 'isScrollControlled'
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 30,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      billData['billName'] ?? 'Unnamed Bill',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // Delete Option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Bill'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet first

                  // Use the context from the parent widget, not the bottom sheet
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text(
                          'Are you sure you want to delete this bill?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await databaseService.deleteBill(billData['billName']);
                      // Use the scaffoldMessenger we saved earlier
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Bill deleted successfully'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error deleting bill: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 60, color: Colors.red[300]),
          const SizedBox(height: 20),
          const Text('Error loading data', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
