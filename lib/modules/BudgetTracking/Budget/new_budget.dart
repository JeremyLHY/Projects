// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../shared/popup_message.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NewBudgetPage extends StatefulWidget {
  const NewBudgetPage({super.key});

  @override
  State<NewBudgetPage> createState() => _NewBudgetPageState();
}

class _NewBudgetPageState extends State<NewBudgetPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String selectedCategory = '';
  bool isBudgetOverspentEnabled = false;
  double amount = 0.0;

  final List<String> periods = ['Week', 'Month', 'Year', 'One Time'];
  final List<String> categories = [
    'Food & Drinks',
    'Transport',
    'Shopping',
    'Health',
    'Groceries',
    'Entertainment',
    'Bills & Fees',
  ];

  Future<bool> _onWillPop() async {
    bool exit = await showExitConfirmationDialog(context);
    return exit;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final databaseService = DatabaseService(uid: user.uid);

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
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'New Budget',
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                TextFormField(
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a name'
                      : null,
                  onSaved: (value) => name = value!,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 0.5, color: Colors.grey), // Normal state
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 2.5, color: Colors.blue), // Focused state
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 2.0, color: Colors.red), // Error state
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 0.5, color: Colors.grey), // Normal state
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 2.5, color: Colors.blue), // Focused state
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 2.0, color: Colors.red), // Error state
                    ),
                    border: UnderlineInputBorder(),
                  ),
                  value: selectedCategory.isNotEmpty ? selectedCategory : null,
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                  dropdownColor:
                      Colors.white, // Set dropdown background to white
                ),

                const SizedBox(height: 30),

                // Amount Field
                TextFormField(
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    // Check if the input is a valid number (positive or decimal number)
                    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'RM ',
                    prefixStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 0.5, color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 2.5, color: Colors.blue),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 2.0, color: Colors.red),
                    ),
                    border: UnderlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 50),

                // Create Budget Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save(); // Save form values

                      try {
                        final DateTime now = DateTime.now();
                        final String formattedDate =
                            DateFormat('yyyy-MM-dd').format(now);

                        final budgetData = {
                          'name': name,
                          'category': selectedCategory,
                          'amount': amount,
                          'date': formattedDate,
                        };

                        await databaseService.addBudget(budgetData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Budget added successfully!')),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error occurred: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Create Budget',
                    style: TextStyle(fontSize: 18),
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
