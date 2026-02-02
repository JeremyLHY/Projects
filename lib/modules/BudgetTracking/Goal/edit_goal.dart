// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../shared/popup_message.dart';
import 'package:intl/intl.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';

class EditGoalPage extends StatefulWidget {
  final Map<String, dynamic> goalData; // Received goal data

  const EditGoalPage({super.key, required this.goalData});

  @override
  State<EditGoalPage> createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  final _formKey = GlobalKey<FormState>();

  late String oldGoalName;
  late String newGoalName;

  late String targetAmount;
  late String savedAmount;
  late String datePicked;
  late String noteDesc;
  late bool goalReach;

  DateTime? selectedDate;
  bool isBudgetOverspentEnabled = false;
  bool isRiskOverspendingEnabled = false;
  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields with existing goal data
    oldGoalName = widget.goalData['name'] ?? '';
    newGoalName = oldGoalName; // Initialize newGoalName with oldGoalName
    targetAmount = widget.goalData['targetAmount']?.toString() ?? '';
    savedAmount = widget.goalData['savedAmount']?.toString() ?? '';
    datePicked = widget.goalData['date'] ?? '';
    noteDesc = widget.goalData['note'] ?? '';
    goalReach = widget.goalData['goalReach'] ?? false;
  }

  Future<bool> _onWillPop() async {
    bool exit = await showExitConfirmationDialog(context);
    return exit;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now(); // Today date

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today, // Prevents selection of past dates
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        datePicked =
            DateFormat('yyyy-MM-dd').format(picked); // Store formatted date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop:
          false, // Prevent the user from popping the route without confirmation
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldLeave = await _onWillPop();
        if (shouldLeave) {
          // Allow the pop to happen
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Edit Goal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();

                  try {
                    final goalData = {
                      'name': oldGoalName, // The existing goal name
                      'newName':
                          newGoalName, // The new goal name entered by the user
                      'targetAmount': double.tryParse(targetAmount) ?? 0.0,
                      'savedAmount': double.tryParse(savedAmount) ?? 0.0,
                      'date': datePicked,
                      'note': noteDesc,
                      'goalReach': goalReach,
                    };

                    Navigator.pop(context); // Close the dialog
                    _editGoal(context, goalData); // Call edit logic here

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Goal changed successfully!')),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error occurred: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: oldGoalName,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please fill in the name'
                            : null,
                        onChanged: (value) {
                          newGoalName = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        initialValue: targetAmount,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please fill in the target amount'
                            : null,
                        onChanged: (value) {
                          targetAmount = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        initialValue: savedAmount,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please fill in the saved amount'
                            : null,
                        onChanged: (value) {
                          savedAmount = value;
                        },
                        enabled: false, // Make the TextFormField uneditable
                        decoration: const InputDecoration(
                          labelText: 'Saved already',
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Desired date',
                            labelStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                            border: UnderlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            datePicked.isEmpty ? 'Select date' : datePicked,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        initialValue: noteDesc,
                        onChanged: (value) {
                          noteDesc = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _editGoal(BuildContext context, Map<String, dynamic> goalData) async {
  try {
    // Get the goal name to identify the goal
    String goalName = goalData['name'];

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) {
      return;
    }

    final databaseService = DatabaseService(uid: user.uid);

    // Perform the goal editing logic
    await databaseService.editGoal(goalData);

    // Show a snackbar or dialog to confirm the goal has been updated
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Goal "$goalName" has been updated successfully.')),
    );

    Navigator.pop(context); // Close the current goal detail page after editing
  } catch (e) {
    // Handle any errors that occur during the goal update process
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating goal: $e')),
    );
  }
}
