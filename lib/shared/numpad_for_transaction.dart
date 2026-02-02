import 'package:flutter/material.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import 'package:test_app/shared/loading.dart';
import 'package:intl/intl.dart';
import 'package:test_app/services/database.dart';
import 'package:provider/provider.dart';
import 'package:test_app/models/user.dart';

class NumpadfortransactionPage extends StatefulWidget {
  const NumpadfortransactionPage({super.key});

  @override
  State<NumpadfortransactionPage> createState() =>
      _NumpadfortransactionPageState();
}

class _NumpadfortransactionPageState extends State<NumpadfortransactionPage> {
  bool loading = false;
  String selectedCategory = '';
  final List<String> categories = [
    'Food & Drinks',
    'Transport',
    'Shopping',
    'Healthcare',
    'Groceries',
    'Entertainment',
    'Bills & Fees',
  ];
  final TextEditingController _textController =
      TextEditingController(text: '0.00');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addDigit(int digit) {
    setState(() {
      String currentText =
          _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;
      currentValue = currentValue * 10 + digit;
      _textController.text = (currentValue / 100).toStringAsFixed(2);
    });
  }

  void _backspace() {
    setState(() {
      String currentText =
          _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;
      currentValue = currentValue ~/ 10;
      _textController.text = (currentValue / 100).toStringAsFixed(2);
    });
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        loading = true;
      });

      try {
        final amount = double.tryParse(_textController.text) ?? 0.0;
        final category = selectedCategory;

        if (category.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category.')),
          );
          setState(() {
            loading = false;
          });
          return;
        }

        final DateTime now = DateTime.now();
        final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
        final String formattedTime = DateFormat('HH:mm:ss').format(now);

        final transactionData = {
          'amount': amount,
          'category': category,
          'date': formattedDate,
          'time': formattedTime,
        };

        final user = Provider.of<CustomUser?>(context, listen: false);

        if (user == null) {
          throw Exception('User not logged in.');
        }

        final databaseService = DatabaseService(uid: user.uid);

        try {
          await databaseService.addTransaction(transactionData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully!')),
          );

          Navigator.pop(context);

          _textController.text = '0.00';
          setState(() {
            selectedCategory = '';
          });
        } catch (e) {
          // Display a SnackBar for specific or general errors
          String errorMessage = 'Failed to add transaction.';
          if (e.toString().contains('Insufficient balance')) {
            errorMessage = 'Insufficient balance. Please top up your account.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        debugPrint("Unexpected error submitting transaction: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form is invalid. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white,),
            body: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Transaction',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextFormField(
                            controller: _textController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: 'CASH',
                              labelStyle:
                                  TextStyle(fontSize: 25.0, color: Colors.grey),
                              contentPadding: EdgeInsets.only(right: 10.0),
                              suffix: Text(
                                'MYR',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.grey),
                              ),
                            ),
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 40.0),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value == '0.00') {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true, // Enables background color
                              fillColor: Colors
                                  .white, // Explicitly set white background
                              labelText: 'Category',
                              labelStyle:
                                  TextStyle(color: Colors.grey, fontSize: 18.0),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              // 👇 Ensure there's no unwanted overlay color
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            dropdownColor: Colors
                                .white, // Ensures dropdown menu is also white
                            value: selectedCategory.isNotEmpty
                                ? selectedCategory
                                : null,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: NumberPadKeyboard(
                      addDigit: _addDigit,
                      backspace: _backspace,
                      enterButtonText: 'Done',
                      onEnter: _submitTransaction,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
