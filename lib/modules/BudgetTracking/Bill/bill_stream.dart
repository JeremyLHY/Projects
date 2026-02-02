import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/modules/BudgetTracking/Bill/edit_bill.dart';
import 'package:test_app/services/bill_notification.dart';
import 'package:test_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/models/user.dart';

class UpcomingBills extends StatefulWidget {
  const UpcomingBills({super.key});

  @override
  State<UpcomingBills> createState() => _UpcomingBillsState();
}

class _UpcomingBillsState extends State<UpcomingBills> {
  late BillNotificationManager _notificationManager;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final notificationService = BillNotificationService();
    await notificationService.init();
    _notificationManager = BillNotificationManager(notificationService);
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return Center(child: Text('No user found.'));
    }

    final databaseService = DatabaseService(uid: user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: databaseService.userInfoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return Center(child: Text('No bills available.'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final bills = userData['billReminders'] as Map<String, dynamic>?;

        if (_initialized && bills != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notificationManager.checkAndSendNotifications(bills);
          });
        }

        if (bills == null || bills.isEmpty) {
          return Center(child: Text('No bills available.'));
        }

        List<Map<String, dynamic>> flattenedBills = [];
        DateTime currentDate = DateTime.now();

        bills.forEach((billName, billData) {
          if (billData is Map<String, dynamic> && billData['status'] != true) {
            DateTime? dueDate;
            var dateRaw = billData['dueDate'];

            if (dateRaw is Timestamp) {
              dueDate = dateRaw.toDate();
            } else if (dateRaw is String) {
              List<String> dateParts = dateRaw.split('-');
              if (dateParts.length == 3) {
                int year = int.parse(dateParts[0]);
                int month = int.parse(dateParts[1]);
                int day = int.parse(dateParts[2]);
                dueDate = DateTime(year, month, day);
              }
            }

            if (dueDate != null && dueDate.isAfter(currentDate)) {
              flattenedBills.add({
                'billName': billName,
                'billAmount': billData['billAmount'],
                'dueDate': billData['dueDate'],
                'frequency': billData['frequency'],
                'status': billData['status'],
              });
            }
          }
        });

        if (flattenedBills.isEmpty) {
          return Center(child: Text('No bills found.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: flattenedBills.map((billData) {
            double billAmount = (billData['billAmount'] ?? 0).toDouble();
            String formattedDate = "No Date";
            int daysRemaining = 0;

            if (billData.containsKey('dueDate') &&
                billData['dueDate'] != null) {
              var dateRaw = billData['dueDate'];
              DateTime? dueDate;

              if (dateRaw is Timestamp) {
                dueDate = dateRaw.toDate();
                formattedDate =
                    "${dueDate.year}-${dueDate.month}-${dueDate.day}";
              } else if (dateRaw is String) {
                formattedDate = dateRaw;
                List<String> dateParts = formattedDate.split('-');
                if (dateParts.length == 3) {
                  int year = int.parse(dateParts[0]);
                  int month = int.parse(dateParts[1]);
                  int day = int.parse(dateParts[2]);
                  dueDate = DateTime(year, month, day);
                }
              }

              if (dueDate != null) {
                daysRemaining = dueDate.difference(DateTime.now()).inDays;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GestureDetector(
                onTap: () => _showBillOptionsBottomSheet(
                    context, databaseService, billData),
                child: Container(
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              size: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        billData['billName'] ?? 'Unnamed Bill',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Text(
                                      'RM${billAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Due Date: $formattedDate",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 5),
                                        if (billData['status'])
                                          Icon(Icons.check,
                                              color: Colors.blueAccent,
                                              size: 16),
                                        SizedBox(
                                            width: billData['status'] ? 5 : 0),
                                        Text(
                                          '$daysRemaining days left',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orangeAccent),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

void _showBillOptionsBottomSheet(
  BuildContext context,
  DatabaseService databaseService,
  Map<String, dynamic> billData,
) {
  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
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
              Divider(),
              // Options List
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit Bill'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              EditBillDetailsPage(billData: billData),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: const Text('Mark As Paid'),
                    onTap: () async {
                      try {
                        await databaseService
                            .updateStatus(billData['billName']);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Marked "${billData['billName']}" as paid!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error marking bill: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Bill'),
                    onTap: () async {
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
                          await databaseService
                              .deleteBill(billData['billName']);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bill deleted successfully'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
            ],
          ),
        ),
      );
    },
  );
}

void _showBillOptionsBottomSheetForOverdue(
  BuildContext context,
  DatabaseService databaseService,
  Map<String, dynamic> billData,
) {
  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
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
              Divider(),
              // Options List
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: const Text('Mark As Paid'),
                    onTap: () async {
                      try {
                        await databaseService
                            .updateStatus(billData['billName']);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Marked "${billData['billName']}" as paid!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error marking bill: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Bill'),
                    onTap: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
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
                          await databaseService
                              .deleteBill(billData['billName']);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bill deleted successfully'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
            ],
          ),
        ),
      );
    },
  );
}

class OverdueBills extends StatefulWidget {
  const OverdueBills({super.key});

  @override
  State<OverdueBills> createState() => _OverdueBillsState();
}

class _OverdueBillsState extends State<OverdueBills> {
  final BillNotificationService _notificationService =
      BillNotificationService();
  bool _notificationsInitialized = false;
  int notificationId = 0; // Counter

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.init();
    setState(() {
      _notificationsInitialized = true;
    });
  }

  Future<void> _checkAndNotifyOverdueBills(Map<String, dynamic>? bills) async {
    if (!_notificationsInitialized || bills == null) return;

    DateTime currentDate = DateTime.now();
    int notificationCounter = 0; // Reset counter each time

    // Convert to list to maintain order
    final billEntries = bills.entries.toList();

    for (final entry in billEntries) {
      final billData = entry.value;
      if (billData is! Map<String, dynamic> || billData['status'] == true) {
        continue;
      }

      DateTime? dueDate;
      final dateRaw = billData['dueDate'];

      // Parse due date
      if (dateRaw is Timestamp) {
        dueDate = dateRaw.toDate();
      } else if (dateRaw is String) {
        final dateParts = dateRaw.split('-');
        if (dateParts.length == 3) {
          dueDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      }

      // Only notify if overdue (isBefore current date) AND status is false (unpaid)
      if (dueDate != null && dueDate.isBefore(currentDate)) {
        final billAmount = (billData['billAmount'] ?? 0).toDouble();
        final formattedDate = dateRaw is Timestamp
            ? "${dueDate.year}-${dueDate.month}-${dueDate.day}"
            : dateRaw;

        // Show notification with sequential delay
        await Future.delayed(Duration(milliseconds: 300 * notificationCounter));
        await _notificationService.showOverdueBillNotification(
          id: notificationCounter, // Unique ID
          billName: entry.key,
          amount: billAmount,
          dueDate: formattedDate,
        );
        notificationCounter++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return Center(child: Text('No user found.'));
    }

    final databaseService = DatabaseService(uid: user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: databaseService.userInfoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return Center(child: Text('No bills available.'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final bills = userData['billReminders'] as Map<String, dynamic>?;

        // Check and notify bills when data is loaded
        if (_notificationsInitialized && bills != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndNotifyOverdueBills(bills);
          });
        }

        if (bills == null || bills.isEmpty) {
          return Center(child: Text('No overdue bills.'));
        }

        List<Map<String, dynamic>> overdueBills = [];
        DateTime currentDate = DateTime.now();

        bills.forEach((billName, billData) {
          if (billData is Map<String, dynamic> && billData['status'] != true) {
            DateTime? dueDate;
            var dateRaw = billData['dueDate'];

            // Parse due date
            if (dateRaw is Timestamp) {
              dueDate = dateRaw.toDate();
            } else if (dateRaw is String) {
              List<String> dateParts = dateRaw.split('-');
              if (dateParts.length == 3) {
                int year = int.parse(dateParts[0]);
                int month = int.parse(dateParts[1]);
                int day = int.parse(dateParts[2]);
                dueDate = DateTime(year, month, day);
              }
            }

            // Only add if overdue (isBefore current date)
            if (dueDate != null && dueDate.isBefore(currentDate)) {
              overdueBills.add({
                'billName': billName,
                'billAmount': billData['billAmount'],
                'dueDate': billData['dueDate'],
                'formattedDueDate':
                    '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                'daysOverdue': currentDate.difference(dueDate).inDays,
              });
            }
          }
        });

        if (overdueBills.isEmpty) {
          return Center(child: Text('No overdue bills.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: overdueBills.map((billData) {
            double billAmount = (billData['billAmount'] ?? 0).toDouble();
            String formattedDate = billData['formattedDueDate'] ?? 'No Date';
            int daysOverdue = billData['daysOverdue'] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GestureDetector(
                onTap: () => _showBillOptionsBottomSheetForOverdue(
                    context, databaseService, billData),
                child: Container(
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              size: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        billData['billName'] ?? 'Unnamed Bill',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Text(
                                      'RM${billAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Due Date: $formattedDate",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const SizedBox(width: 5),
                                        if (billData['status'] == true)
                                          const Icon(Icons.check,
                                              color: Colors.blueAccent,
                                              size: 16),
                                        if (billData['status'] == true)
                                          const SizedBox(width: 5),
                                        Text(
                                          '$daysOverdue days overdue',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
