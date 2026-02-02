import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/modules/BudgetTracking/Goal/edit_goal.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';

class GoalDetailPage extends StatelessWidget {
  final Map<String, dynamic> goalData;

  const GoalDetailPage({super.key, required this.goalData});

  @override
  Widget build(BuildContext context) {
    // Get the progress as a percentage
    double currentAmount = goalData['savedAmount']?.toDouble() ?? 0.0;
    double targetAmount = goalData['targetAmount']?.toDouble() ?? 1.0;
    double progress = currentAmount / targetAmount;
    double percentage = progress * 100;

    if (progress > 1) progress = 1.0; // Ensure progress does not exceed 100%

    // Get the target date from goalData (assuming it's stored as a Timestamp or String)
    var targetDateRaw = goalData['date'];
    DateTime targetDate = DateTime.now(); // Default if no date provided
    if (targetDateRaw is DateTime) {
      targetDate = targetDateRaw;
    } else if (targetDateRaw is String) {
      targetDate = DateTime.parse(targetDateRaw);
    }

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Calculate the remaining amount to save
    double remainingAmount = targetAmount - currentAmount;

    // Calculate the number of days remaining
    Duration duration = targetDate.difference(currentDate);

    // Calculate the number of weeks remaining
    int weeksRemaining =
        (duration.inDays / 7).ceil(); // Round up to avoid fractions of weeks

    // Calculate the amount to save per week
    double amountPerWeek = remainingAmount / weeksRemaining;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Goal Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit), // Trash can icon
            onPressed: () {
              // Handle delete action
              _showOptionsBottomSheet(
                  context, goalData); // Show options when clicked
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "${goalData['name'] ?? 'Unnamed Goal'}",
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Due date: ${goalData['date'] ?? 'Unnamed date'}",
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: Colors.red),
            ),
            const SizedBox(height: 40),

            // Circular Progress Bar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Progress Bar with text in the center
                Stack(
                  alignment:
                      Alignment.center, // Center the widgets inside the Stack
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 250, // Set width
                          height: 250, // Set height
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0
                                  ? Colors.green
                                  : Colors
                                      .blue, // Color change based on progress
                            ),
                            backgroundColor: Colors
                                .grey[300], // Background color of the circle
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${percentage.toInt()}%", // Convert to integer for display
                          style: TextStyle(
                            fontSize: 50,
                            color: (percentage.toInt() == 100)
                                ? Colors.green
                                : Colors.blue, // Change color when 100%
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text('RM'),
                        Text(
                          "${goalData['savedAmount'].toStringAsFixed(2) ?? '0.00'} / ${goalData['targetAmount'].toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center the content
              children: [
                Text('Minimum amount per week to reach goal'),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'RM ${amountPerWeek.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Note : ${goalData['note']}',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goalData['status'] == 'completed'
                        ? Colors.grey
                        : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    minimumSize: const Size(350, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: goalData['status'] == 'completed'
                      ? null
                      : () {
                          _showNumpadDialog(context, goalData);
                        },
                  child: const Text(
                    'Add Money',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (goalData['status'] !=
                    'completed') // Only show mark-as-reached if not completed
                  GestureDetector(
                    onTap: () {
                      _markAsReach(context, goalData);
                    },
                    child: Text(
                      'MARK GOAL AS REACHED',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'GOAL COMPLETED',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showOptionsBottomSheet(
    BuildContext context, Map<String, dynamic> goalData) {
  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose an action',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Options List
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Goal'),
              onTap: () {
                // Close BottomSheet
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        EditGoalPage(goalData: goalData),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Goal'),
              onTap: () {
                Navigator.pop(context); // Close BottomSheet
                _showDeleteConfirmationDialog(
                    context, goalData); // Show confirmation dialog
              },
            ),
          ],
        ),
      );
    },
  );
}

// Show confirmation dialog before deleting
void _showDeleteConfirmationDialog(
    BuildContext context, Map<String, dynamic> goalData) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the confirmation dialog
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.blueAccent, fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteGoal(
                  context, goalData); // Call delete method after confirmation
              Navigator.pop(
                  context); // This will pop the current goal detail page
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.blueAccent, fontSize: 15),
            ),
          ),
        ],
      );
    },
  );
}

// Example delete goal method
void _deleteGoal(BuildContext context, Map<String, dynamic> goalData) async {
  try {
    // Get the goal name to identify the goal
    String goalName = goalData['name'];

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) {
      return;
    }

    final databaseService = DatabaseService(uid: user.uid);

    // Perform the goal deletion logic
    await databaseService.deleteGoal(goalName);

    // Show a snackbar or dialog to confirm deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Goal "$goalName" has been deleted successfully.')),
    );
    Navigator.pop(context); // This will pop the current goal detail page
  } catch (e) {
    // Handle any errors that occur during deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting goal: $e')),
    );
  }
}

void _markAsReach(BuildContext context, Map<String, dynamic> goalData) async {
  try {
    String goalName = goalData['name'];
    double savedAmount = (goalData['savedAmount'] as num?)?.toDouble() ?? 0.0;
    double targetAmount = (goalData['targetAmount'] as num?)?.toDouble() ?? 0.0;

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) return;

    final databaseService = DatabaseService(uid: user.uid);

    bool isCompleted = goalData['goalReach'] == true;
    if (isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal "$goalName" is already marked as completed.'),
        ),
      );
      return;
    }

    // Determine message based on saved amount
    String message = savedAmount >= targetAmount
        ? "You have reached your target! Do you want to mark this goal as reached?"
        : "You have not reached your target yet. Do you still want to mark this goal as reached?";

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Mark as reached"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    // If user confirms, proceed with marking as reached
    if (confirm) {
      await databaseService.markAsReach(goalName, true, goalData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal "$goalName" has been marked as reached.')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error marking goal as reached: $e')),
    );
  }
}

void _showNumpadDialog(BuildContext context, Map<String, dynamic> goalData) {
  TextEditingController amountController = TextEditingController(text: '0.00');

  bool isCompleted =
      goalData['status'] == 'completed' || goalData['goalReach'] == true;
  if (isCompleted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot add money to a completed goal.')),
    );
    return;
  }

  void addDigit(int digit) {
    String currentText =
        amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    int currentValue = int.tryParse(currentText) ?? 0;
    currentValue = currentValue * 10 + digit;
    amountController.text = (currentValue / 100).toStringAsFixed(2);
  }

  void backspace() {
    String currentText =
        amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    int currentValue = int.tryParse(currentText) ?? 0;
    currentValue = currentValue ~/ 10;
    amountController.text = (currentValue / 100).toStringAsFixed(2);
  }

  // Option 1: Remove the first check entirely
  void submitAmount() async {
    double addedAmount = double.tryParse(amountController.text) ?? 0.0;
    if (addedAmount > 0) {
      final user = Provider.of<CustomUser?>(context, listen: false);
      if (user != null) {
        final databaseService = DatabaseService(uid: user.uid);
        String goalName = goalData['name'];

        try {
          await databaseService.addMoneyToGoal(goalName, addedAmount, goalData);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added RM ${addedAmount.toStringAsFixed(2)} to your goal!',
              ),
            ),
          );
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xff222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: amountController,
                    readOnly: true,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.backspace,
                      size: 30, color: Colors.blueAccent),
                  onPressed: backspace,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [1, 4, 7]
                      .map((i) => _buildNumRow([i, i + 1, i + 2], addDigit))
                      .toList() +
                  [
                    _buildNumRow([0], addDigit)
                  ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => amountController.text = "0.00",
                  child: const Text("Clear",
                      style: TextStyle(color: Colors.redAccent)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 1),
                ElevatedButton(
                  onPressed: submitAmount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Confirm",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildNumRow(List<int> numbers, Function(int) onPressed) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children:
        numbers.map((number) => _buildNumpadButton(number, onPressed)).toList(),
  );
}

Widget _buildNumpadButton(int number, Function(int) onPressed) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
    child: SizedBox(
      width: 65,
      height: 65,
      child: ElevatedButton(
        onPressed: () => onPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff444444),
          shadowColor: Colors.black54,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text("$number",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    ),
  );
}
