import 'package:flutter/material.dart';
import '../../../shared/popup_message.dart';
import 'package:test_app/services/database.dart';
import 'package:test_app/models/user.dart';
import 'package:provider/provider.dart';

class EditBudgetPage extends StatefulWidget {
  final Map<String, dynamic> budgetData;

  const EditBudgetPage({super.key, required this.budgetData});

  @override
  State<EditBudgetPage> createState() => _EditBudgetPageState();
}

class _EditBudgetPageState extends State<EditBudgetPage> {
  final _formKey = GlobalKey<FormState>();

  late String newName;
  late double amount;
  late bool isChanged;

  @override
  void initState() {
    super.initState();
    newName = widget.budgetData['name'] ?? '';
    amount = (widget.budgetData['amount'] ?? 0.0).toDouble();
    isChanged = false;
  }

  Future<bool> _onWillPop() async {
    return await showExitConfirmationDialog(context);
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
      // ignore: deprecated_member_use
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
            'Edit Budget',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: isChanged
                  ? () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        try {
                          final budgetData = {
                            'category': widget.budgetData['category'],
                            'oldName': widget.budgetData['name'],
                            'newName': newName,
                            'amount': amount,
                          };

                          await DatabaseService(uid: user.uid)
                              .editBudget(budgetData);

                          if (!mounted) return;
                          Navigator.pop(context);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Budget updated successfully!')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error updating budget: $e')),
                          );
                        }
                      }
                    }
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Save'),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name (Editable)
                TextFormField(
                  initialValue: newName,
                  onChanged: (value) {
                    setState(() {
                      newName = value;
                      isChanged = true;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Budget Name', // Floating label
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 0.5, color: Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 2.5, color: Colors.blue),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Category (Disabled with clear indication)
                IgnorePointer(
                  ignoring: true,
                  child: TextFormField(
                    initialValue: widget.budgetData['category'] ?? '',
                    decoration: InputDecoration(
                      labelText: 'Category', // Floating label
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Category (Cannot be changed)',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            width: 0.5,
                            color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            width: 2.5,
                            color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 30),

                // Amount (Editable)
                TextFormField(
                  initialValue: amount.toString(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      amount = double.tryParse(value) ?? amount;
                      isChanged = true;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Amount', // Floating label
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 0.5, color: Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 2.5, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
