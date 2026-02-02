import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:test_app/services/database.dart';
import '../../../shared/popup_message.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const EditTransactionPage({super.key, required this.transactionData});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late String oldCategory;
  late String newCategory;
  late String amount;
  late String datePicked;
  late String timePicked;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final List<String> categories = [
    'Food & Drinks',
    'Transport',
    'Shopping',
    'Healthcare',
    'Groceries',
    'Entertainment',
    'Bills & Fees',
    'Financial Goal'
  ];

  @override
  void initState() {
    super.initState();
    oldCategory = widget.transactionData['category'] ?? '';
    newCategory = oldCategory;
    amount = widget.transactionData['amount']?.toString() ?? '';
    datePicked = widget.transactionData['date'] ?? '';
    timePicked = widget.transactionData['time'] ?? '';
  }

  Future<bool> _onWillPop() async {
    bool exit = await showExitConfirmationDialog(context);
    return exit;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2023),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
        datePicked = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        timePicked = picked.format(context);
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
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Edit Transaction',
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
                    final databaseService = DatabaseService(uid: user.uid);
                    Map<String, dynamic> updatedTransaction = {
                      'oldCategory': oldCategory,
                      'newCategory': newCategory,
                      'transactionIndex':
                          widget.transactionData['transactionIndex'],
                      'newAmount': double.parse(amount),
                      'newDate': selectedDate?.toIso8601String() ?? datePicked,
                      'newTime': timePicked,
                    };

                    await databaseService.editTransaction(updatedTransaction);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Transaction updated successfully!')),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to update transaction.')),
                    );
                    debugPrint("Error updating transaction: $e");
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
                      DropdownButtonFormField<String>(
                        value: newCategory,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select a category'
                            : null,
                        onChanged: (value) {
                          setState(() {
                            newCategory = value!;
                          });
                        },
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1.5,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        initialValue: amount,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please fill in the amount'
                            : null,
                        onChanged: (value) {
                          amount = value;
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1.5,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.5,
                                color: Colors.blue,
                              ),
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            datePicked.isEmpty ? 'Select date' : datePicked,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.5,
                                color: Colors.blue,
                              ),
                            ),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            timePicked.isEmpty ? 'Select time' : timePicked,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
