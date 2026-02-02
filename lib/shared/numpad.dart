import 'package:flutter/material.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import 'package:test_app/models/user.dart';
import 'package:test_app/shared/loading.dart';
import 'package:test_app/services/database.dart';
import 'package:provider/provider.dart';

class NumpadPage extends StatefulWidget {
  const NumpadPage({super.key});

  @override
  State<NumpadPage> createState() => _NumpadPageState();
}

class _NumpadPageState extends State<NumpadPage> {
  bool loading = false;

  final TextEditingController _textController =
      TextEditingController(text: '0.00');

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addDigit(int digit) {
    setState(() {
      // Get the current text as cents (integer value)
      String currentText =
          _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;

      // Shift existing value left (multiply by 10) and add the new digit
      currentValue = currentValue * 10 + digit;

      // Format as a monetary value
      _textController.text = (currentValue / 100).toStringAsFixed(2);
    });
  }

  void _backspace() {
    setState(() {
      // Get the current text as cents (integer value)
      String currentText =
          _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int currentValue = int.tryParse(currentText) ?? 0;

      // Remove the last digit (divide by 10)
      currentValue = currentValue ~/ 10;

      // Format as a monetary value
      _textController.text = (currentValue / 100).toStringAsFixed(2);
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        loading = true;
      });

      double addedAmount = double.tryParse(_textController.text) ?? 0.0;
      final CustomUser? user = Provider.of<CustomUser?>(context, listen: false);

      if (user != null) {
        DatabaseService(uid: user.uid)
            .updateAccountBalance(addedAmount)
            .then((_) {
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              loading = false;
            });
            Navigator.pop(context);
          });
        }).catchError((e) {
          setState(() {
            loading = false;
          });
          debugPrint("Error during balance update: $e");
        });
      } else {
        setState(() {
          loading = false;
        });
        debugPrint("User is not logged in!");
      }
    } else {
      debugPrint('Form is invalid!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(),
            body: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribute space
                children: <Widget>[
                  // Title
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Account Balance',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Cash TextFormField
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextFormField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              border:
                                  InputBorder.none, // Remove border and lines
                              labelText: 'CASH',
                              labelStyle:
                                  TextStyle(fontSize: 25.0, color: Colors.grey),
                              contentPadding: EdgeInsets.only(
                                  right: 10.0), // Adjust padding for text
                              suffix: Text(
                                'MYR',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.grey),
                              ),
                            ),
                            readOnly: true, // Make it read-only
                            textAlign:
                                TextAlign.center, // Align the text to the right
                            style: const TextStyle(fontSize: 40.0),
                            // Add validator for Cash field
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value == '0.00') {
                                return 'Please enter an amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        ),
                      ],
                    ),
                  ),

                  // Spacer to push the numpad to the bottom
                  const Spacer(),

                  // Submit Button (can also submit when tapping on the numpad)
                  SizedBox(
                    height: 300, // Increase the height of the numpad
                    width: double.infinity,
                    child: NumberPadKeyboard(
                      addDigit: _addDigit,
                      backspace: _backspace,
                      enterButtonText: 'Done',
                      onEnter: _submitForm,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
