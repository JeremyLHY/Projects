import 'package:flutter/material.dart';
import 'package:test_app/modules/BudgetTracking/Goal/new_goal.dart';
import 'package:provider/provider.dart';
import 'package:test_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/models/user.dart';
import 'package:test_app/modules/BudgetTracking/Goal/goal_details.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
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
          'Goals',
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
                      userData['financialGoals'] as Map<String, dynamic>? ?? {};

                  bool hasBudgets = budgets.isNotEmpty;

                  return hasBudgets
                      ? Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewGoalPage(),
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
                              'CREATE FINANCIAL GOAL',
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
                                      './images/financial-goals.png',
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
                                          'Goals',
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
                                            const NewGoalPage(),
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
                                    'CREATE FINANCIAL GOAL',
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
              Divider(color: Colors.black),
              StreamBuilder<DocumentSnapshot>(
                stream: databaseService.userInfoStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return const Center(child: Text('No goals available.'));
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final goals =
                      userData['financialGoals'] as Map<String, dynamic>?;

                  if (goals == null || goals.isEmpty) {
                    return const Center(child: Text('No goals available.'));
                  }

                  // Flatten the goals map into a list
                  List<Map<String, dynamic>> flattenedGoals = [];

                  goals.forEach((goalName, goalData) {
                    if (goalData is Map<String, dynamic>) {
                      flattenedGoals.add({
                        'name': goalName,
                        'date': goalData['date'],
                        'goalReach': goalData['goalReach'],
                        'targetAmount': goalData['targetAmount'],
                        'savedAmount': goalData['savedAmount'],
                        'note': goalData['note'],
                      });
                    }
                  });

                  if (flattenedGoals.isEmpty) {
                    return const Center(child: Text('No goals found.'));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: flattenedGoals.map((goalData) {
                      double savedAmount =
                          (goalData['savedAmount'] ?? 0).toDouble();
                      double targetAmount =
                          (goalData['targetAmount'] ?? 1).toDouble();
                      double progress = savedAmount / targetAmount;
                      double percentage = (progress * 100).clamp(0, 100);
                      bool status = goalData['goalReach'] == true;

                      DateTime? targetDate;
                      var rawDate = goalData['date'];
                      if (rawDate is Timestamp) {
                        targetDate = rawDate.toDate();
                      } else if (rawDate is String) {
                        // Try to parse the string date if needed
                        try {
                          var parts = rawDate.split('/');
                          if (parts.length == 3) {
                            targetDate = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                          }
                        } catch (e) {
                          targetDate = null;
                        }
                      }

                      String formattedDate = targetDate != null
                          ? "${targetDate.day}/${targetDate.month}/${targetDate.year}"
                          : "No Date";

                      // Determine status text and color
                      String displayStatus;
                      Color statusColor;

                      if (status) {
                        displayStatus = 'Completed';
                        statusColor = Colors.green;
                      } else if (targetDate != null &&
                          DateTime.now().isAfter(targetDate)) {
                        displayStatus = 'Expired';
                        statusColor = Colors.red;
                      } else {
                        displayStatus = 'In Progress';
                        statusColor = Colors.blueAccent;
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GoalDetailPage(goalData: goalData),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            children: [
                              // Goal Title and Arrow
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      goalData['name'] ?? 'Unnamed Goal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),

                              // Target & Progress %
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'RM${targetAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${percentage.toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Progress Bar
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[300],
                                color: progress >= 1
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                              ),

                              const SizedBox(height: 5),

                              // Target Date and Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Target Date: $formattedDate",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
