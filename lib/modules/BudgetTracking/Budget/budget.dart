import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/modules/BudgetTracking/Budget/budget_details.dart';
import 'package:test_app/modules/BudgetTracking/Budget/new_budget.dart';
import 'package:provider/provider.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final databaseService = DatabaseService(uid: user.uid);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Budget',
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: databaseService.userInfoStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final budgets =
                      userData['budgets'] as Map<String, dynamic>? ?? {};

                  bool hasBudgets = budgets.isNotEmpty;

                  return hasBudgets
                      ? Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewBudgetPage(),
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
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                            ),
                            label: const Text(
                              'CREATE NEW BUDGET',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.asset(
                                      './images/wallet.png',
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Budget',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Manage your spending limits effectively with personalized budget tracking.',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NewBudgetPage(),
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
                                    'CREATE NEW BUDGET',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<DocumentSnapshot>(
                stream: databaseService.userInfoStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return Center(child: Text('No budgets available.'));
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final budgets = userData['budgets'] as Map<String, dynamic>?;

                  if (budgets == null || budgets.isEmpty) {
                    return Center(child: Text('No budgets available.'));
                  }

                  // Group budgets by category
                  Map<String, List<Map<String, dynamic>>> groupedBudgets = {};
                  budgets.forEach((category, budgetList) {
                    if (budgetList is List) {
                      groupedBudgets[category] = budgetList
                          .map((e) => e as Map<String, dynamic>)
                          .toList();
                    }
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedBudgets.entries.map((entry) {
                      String category = entry.key;
                      List<Map<String, dynamic>> categoryBudgets = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: Colors.grey, thickness: 0.3),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.blueAccent),
                              Text(' In limit '),
                              SizedBox(width: 20),
                              Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.orangeAccent),
                              Text(' Near Limit '),
                              SizedBox(width: 20),
                              Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.redAccent),
                              Text(' Overspend '),
                            ],
                          ),
                          SizedBox(height: 5),
                          ...categoryBudgets.map((budgetData) {
                            double spentAmount =
                                (budgetData['progressSpending'] ?? 0)
                                    .toDouble();
                            double totalAmount =
                                (budgetData['amount'] ?? 1).toDouble();
                            double progress = spentAmount / totalAmount;
                            double leftover = totalAmount - spentAmount;
                            double percentage = progress * 100;
                            if (progress > 1) progress = 1;

                            String formattedDate = "No Date";
                            if (budgetData.containsKey('date') &&
                                budgetData['date'] != null) {
                              var dateRaw = budgetData['date'];
                              if (dateRaw is Timestamp) {
                                DateTime date = dateRaw.toDate();
                                formattedDate =
                                    "${date.day}/${date.month}/${date.year}";
                              } else if (dateRaw is String) {
                                formattedDate = dateRaw;
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BudgetDetailPage(
                                        budgetData: budgetData),
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            budgetData['name'] ??
                                                'Unnamed Budget',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 0,
                                          child: Text(
                                            '${percentage.toInt()}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[300],
                                      color: progress >= 1
                                          ? Colors.redAccent
                                          : (progress > 0.8
                                              ? Colors.orangeAccent
                                              : Colors.blueAccent),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Created on: $formattedDate",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        Spacer(),
                                        Text(
                                          "Remaining: ",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        Text(
                                          'RM ${leftover.toStringAsFixed(2)}', // Format to 2 decimal places
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
