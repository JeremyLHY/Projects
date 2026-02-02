import 'package:flutter/material.dart';
import 'package:test_app/models/user.dart';
import 'package:test_app/modules/authenticate/authenticate.dart';
import 'package:provider/provider.dart';
import 'package:test_app/modules/BudgetTracking/Expense/main_page.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});
  

  @override
  Widget build(BuildContext context) {
    final CustomUser? user = Provider.of<CustomUser?>(context); // Allow user to be nullable
    if (user == null) {
      return Authenticate(); // If no user, show the Authenticate screen
    } else {
      return MainPage(); // If user exists, show the MainPage
    }
  }
}
