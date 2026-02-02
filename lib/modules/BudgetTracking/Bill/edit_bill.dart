// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../shared/popup_message.dart'; // Import the popup file
import 'package:intl/intl.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';

class EditBillDetailsPage extends StatefulWidget {
  final Map<String, dynamic> billData;

  const EditBillDetailsPage({super.key, required this.billData});

  @override
  State<EditBillDetailsPage> createState() => _EditBillDetailsPageState();
}

class _EditBillDetailsPageState extends State<EditBillDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  late String billName = '';
  late String billAmount = '';
  late String selectedFrequency = '';
  late String datePicked = '';

  final List<String> frequencies = ['Weekly', 'Monthly', 'Yearly', 'One Time'];

  DateTime? selectedDate;

  Future<bool> _onWillPop() async {
    bool exit = await showExitConfirmationDialog(context);
    return exit;
  }

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing bill data
    billName = widget.billData['billName'] ?? '';
    billAmount = (widget.billData['billAmount'] ?? 0.0).toString();
    selectedFrequency = widget.billData['frequency'] ?? '';
    datePicked = widget.billData['dueDate'] ?? '';

    // Initialize selectedDate from existing dueDate
    if (datePicked.isNotEmpty) {
      selectedDate = DateFormat('yyyy-MM-dd').parse(datePicked);
    }
  }

 Future<void> _selectDate(BuildContext context) async {
  final DateTime today = DateTime.now(); // Today's date

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: selectedDate ?? today, // Default to today if no date is selected
    firstDate: today, // Prevent past dates from being selected
    lastDate: DateTime(2101),
  );

  if (picked != null) {
    setState(() {
      selectedDate = picked;
      datePicked = DateFormat('yyyy-MM-dd').format(picked); // Ensure it's saved
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
            'New Bill',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Name Input
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please fill in the name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    billName = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Bill Name',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
                  ),
                ),
                const SizedBox(height: 30),

                // Bill Amount Input
                TextFormField(
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please fill in the bill amount';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    billAmount = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Amount',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
                  ),
                ),
                const SizedBox(height: 30),

                // Due Date Picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      labelStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
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
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select a date'
                          : '${selectedDate!.toLocal()}'.split(' ')[0],
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
                  ),
                  value:
                      selectedFrequency.isNotEmpty ? selectedFrequency : null,
                  items: frequencies.map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFrequency = newValue!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a frequency'
                      : null,
                ),
                const SizedBox(height: 40),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (datePicked.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a due date!')),
                          );
                          return;
                        }

                        try {
                          final billData = {
                            'oldBillName':
                                widget.billData['billName'], // Original name
                            'newBillName': billName, // Updated name
                            'billAmount': double.tryParse(billAmount) ?? 0.0,
                            'dueDate': datePicked,
                            'frequency': selectedFrequency,
                            'status': widget.billData['status'] ??
                                false, // Preserve existing status
                          };

                          await databaseService.editBill(billData);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Bill updated successfully!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error occurred: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Edit Bill',
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
          ),
        ),
      ),
    );
  }
}
