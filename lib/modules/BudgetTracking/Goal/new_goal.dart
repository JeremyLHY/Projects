// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../shared/popup_message.dart';
import 'package:intl/intl.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';

class NewGoalPage extends StatefulWidget {
  const NewGoalPage({super.key});

  @override
  State<NewGoalPage> createState() => _NewGoalPageState();
}

class _NewGoalPageState extends State<NewGoalPage> {
  final _formKey = GlobalKey<FormState>();

  String goalName = '';
  String targetAmount = '';
  String savedAmount = '';
  String datePicked = '';
  String noteDesc = '';

  DateTime? selectedDate;
  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();

  Future<bool> _onWillPop() async {
    bool exit = await showExitConfirmationDialog(context);
    return exit;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today, // ✅ Prevents selection of past dates
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        datePicked = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
            'New Goal',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please fill in the name'
                      : null,
                  onChanged: (value) => goalName = value,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
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
                const SizedBox(height: 40),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please fill in the target amount';
                    }
                    // Validate that only numbers are entered
                    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onChanged: (value) => targetAmount = value,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: 'RM ',
                    prefixStyle: TextStyle(
                      color: Colors.black, // ✅ RM text color
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.5,
                        color: Colors.blue,
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please fill in the saved amount';
                    }
                    // Validate that only numbers are entered
                    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onChanged: (value) => savedAmount = value,
                  decoration: const InputDecoration(
                    labelText: 'Saved already',
                    prefixText: 'RM ',
                    prefixStyle: TextStyle(
                      color: Colors.black, // ✅ RM prefix text color
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.5,
                        color: Colors.blue,
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                        color: Colors.red,
                      ),
                    ),
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
                      suffixIcon: Icon(Icons.calendar_today),
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
                    child: Text(
                      datePicked.isEmpty ? 'Select date' : datePicked,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  onChanged: (value) => noteDesc = value,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
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
                const SizedBox(height: 40),
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
                      _formKey.currentState?.save();

                      try {
                        final goalData = {
                          'name': goalName,
                          'targetAmount': double.tryParse(targetAmount) ?? 0.0,
                          'savedAmount': double.tryParse(savedAmount) ?? 0.0,
                          'date': datePicked,
                          'note': noteDesc,
                        };

                        await databaseService.addGoals(goalData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Goal added successfully!')),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error occurred: $e')),
                        );
                      }
                    }
                  },
                  child:
                  
                      const Text('Create Goal', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
