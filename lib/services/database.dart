import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid}) {
    // Initialize token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (uid != null) {
        updateUserFCMToken(newToken);
      }
    });
  }

  final CollectionReference spendlyCollection =
      FirebaseFirestore.instance.collection('Spendlys');

  // Initialize Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> updateUserFCMToken(String token) async {
    await spendlyCollection.doc(uid).update({'fcmToken': token});
  }

  Future<void> requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission();
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> setUserData({
    required double accountBalance,
    required Map<String, List<Map<String, dynamic>>> transactions,
    required Map<String, List<Map<String, dynamic>>> budgets,
    required Map<String, List<Map<String, dynamic>>> financialGoals,
    required Map<String, List<Map<String, dynamic>>> billReminders,
    required List<String> linkedAccounts,
  }) async {
    return await spendlyCollection.doc(uid).set({
      'accountBalance': {
        'amount': accountBalance, // Store balance inside a map
        'lastUpdated': FieldValue.serverTimestamp(), // Timestamp
        'frequencyAmount': 0.0, // Default frequency deposit
        'selectedFrequency': "None", // Default frequency
      },
      'transactions': transactions,
      'budgets': budgets,
      'financialGoals': financialGoals,
      'billReminders': billReminders,
      'linkedAccounts': linkedAccounts,
    });
  }

  Future<void> updateAccountBalance(double addedAmount) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        Map<String, dynamic> balanceData =
            (userDoc.data() as Map<String, dynamic>?)?['accountBalance'] ?? {};

        final currentTransactions =
            userDoc['transactions'] as Map<String, dynamic>? ?? {};

        double currentBalance =
            (balanceData['amount'] as num?)?.toDouble() ?? 0.0;

        double newBalance = currentBalance + addedAmount;
        DateTime now = DateTime.now();

        // Create a transaction for adding money to the wallet
        final newTransaction = {
          'amount': addedAmount,
          'category': "Income",
          'date': now.toIso8601String(),
          'time': DateFormat('HH:mm:ss').format(now),
        };

        // Add transaction to "Top-Up Wallet" category
        if (currentTransactions.containsKey("Income")) {
          (currentTransactions["Income"] as List).add(newTransaction);
        } else {
          currentTransactions["Income"] = [newTransaction];
        }

        // Instantly update Firestore
        await userDocRef.update({
          'accountBalance': {
            'amount': newBalance,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          'transactions': currentTransactions,
        });

        debugPrint("Balance updated successfully. New Balance: $newBalance");
      } else {
        debugPrint("User document not found!");
      }
    } catch (e) {
      debugPrint("Error updating account balance: $e");
    }
  }

  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // Retrieve current account balance, transactions, and budgets
        final currentTransactions =
            (userDoc['transactions'] as Map<String, dynamic>?) ?? {};

        final currentBalance = (userDoc['accountBalance']
                as Map<String, dynamic>?)?['amount'] as double? ??
            0.0;

        final budgets = (userDoc['budgets'] as Map<String, dynamic>?) ??
            {}; // Fetch budgets

        // Ensure sufficient balance
        final transactionAmount = transactionData['amount'] as double;
        if (currentBalance < transactionAmount) {
          throw Exception('Insufficient balance');
        }

        // Prepare the new transaction
        final newTransaction = {
          'amount': transactionAmount,
          'category': transactionData['category'],
          'date': transactionData['date'],
          'time': transactionData['time'],
        };

        final category = transactionData['category'];

        // Add transaction to the correct category
        if (currentTransactions.containsKey(category)) {
          (currentTransactions[category] as List).add(newTransaction);
        } else {
          currentTransactions[category] = [newTransaction];
        }

        // Update the budget's spent amount if the category exists
        if (budgets.containsKey(category)) {
          final budgetList = budgets[category] as List;
          for (var budget in budgetList) {
            double currentSpent = budget['progressSpending'] as double? ?? 0.0;
            currentSpent += transactionAmount;

            // Update the progressSpending with the exact spent amount
            budget['progressSpending'] = currentSpent;
          }
        }

        // Deduct the transaction amount from accountBalance correctly
        final newBalance = currentBalance - transactionAmount;

        // Update Firestore with the modified transactions, account balance, and budgets
        await userDocRef.update({
          'transactions': currentTransactions,
          'accountBalance.amount':
              newBalance, // 🔹 Correctly updating the nested amount field
          'budgets':
              budgets, // Update the budgets with the new progressSpending
        });

        debugPrint("Transaction added. New Balance: $newBalance");
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      rethrow; // Re-throw exception so it can be handled elsewhere
    }
  }

  Future<void> addBudget(Map<String, dynamic> budgetData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentBudgets =
            userDoc['budgets'] as Map<String, dynamic>? ?? {};
        final amount = budgetData['amount'] as double;

        // FIRST get the category from budgetData
        final category = budgetData['category']; // <-- MOVE THIS LINE UP

        // THEN use it in newBudget
        final newBudget = {
          'name': budgetData['name'],
          'amount': amount,
          'date': budgetData['date'],
          'progressSpending': 0.0,
          'category': category, // Now using already declared variable
        };

        // Rest of your code remains the same...
        if (currentBudgets.containsKey(category)) {
          (currentBudgets[category] as List).add(newBudget);
        } else {
          currentBudgets[category] = [newBudget];
        }

        await userDocRef.update({
          'budgets': currentBudgets,
        });
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error adding budget: $e");
      rethrow;
    }
  }

  Future<void> deleteBudget(String category, String budgetName) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final Map<String, dynamic> budgets =
            Map<String, dynamic>.from(userData['budgets'] ?? {});

        if (budgets.containsKey(category)) {
          final List<dynamic> budgetList = List.from(budgets[category]);

          // Remove the specific budget by name
          budgetList.removeWhere((budget) => budget['name'] == budgetName);

          // If the category is empty, remove it; otherwise, update the list
          if (budgetList.isEmpty) {
            budgets.remove(category);
          } else {
            budgets[category] = budgetList;
          }

          // Update Firestore using update() instead of set()
          await userDocRef.update({'budgets': budgets});

          log("Budget deleted successfully.");
        } else {
          log("Category not found.");
        }
      } else {
        log("User document does not exist.");
      }
    } catch (e) {
      log("Error deleting budget: $e");
    }
  }

  // DatabaseService.dart
  Future<void> editBudget(Map<String, dynamic> budgetData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentBudgets =
            userDoc['budgets'] as Map<String, dynamic>? ?? {};

        final String category = budgetData['category']?.toString() ?? '';
        final String oldName = budgetData['oldName']?.toString() ?? '';
        final String newName = budgetData['newName']?.toString() ?? oldName;
        final double amount = (budgetData['amount'] ?? 0.0).toDouble();

        if (currentBudgets.containsKey(category)) {
          final List<dynamic> categoryBudgets =
              List.from(currentBudgets[category] as List? ?? []);

          // Find the budget index
          int index = categoryBudgets.indexWhere(
              (b) => (b as Map<String, dynamic>)['name'] == oldName);

          if (index != -1) {
            // Create updated budget
            final updatedBudget = {
              ...categoryBudgets[index],
              'name': newName,
              'amount': amount,
            };

            // Update the array
            categoryBudgets[index] = updatedBudget;

            // Update Firestore
            await userDocRef.update({'budgets.$category': categoryBudgets});

            debugPrint("Budget updated successfully.");
          } else {
            debugPrint("Budget '$oldName' not found in category '$category'");
          }
        } else {
          debugPrint("Category '$category' not found.");
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error editing budget: $e");
      rethrow;
    }
  }

  Future<void> addGoals(Map<String, dynamic> goalData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid); // User document reference
      final userDoc = await userDocRef.get(); // Fetch user document

      if (userDoc.exists) {
        // Get the current goals map or initialize an empty map if not present
        final currentGoals =
            userDoc['financialGoals'] as Map<String, dynamic>? ?? {};

        final String goalName = goalData['name']; // Goal name as unique key
        final double targetAmount = goalData['targetAmount'] as double;
        final double savedAmount = goalData['savedAmount'] as double;
        final String noteDesc = goalData['note']; // Note for the goal
        final String datePicked = goalData['date']; // Date for the goal

        // Create a new goal data structure
        final newGoal = {
          'date': datePicked,
          'goalReach': false, // Initial goalReach value
          'targetAmount': targetAmount,
          'savedAmount': savedAmount,
          'note': noteDesc,
        };

        // Add the new goal under the goal name (unique identifier)
        currentGoals[goalName] = newGoal;

        // Update the user's financial goals in Firestore
        await userDocRef.update({
          'financialGoals': currentGoals, // Save the updated financialGoals map
        });

        debugPrint("Goal added successfully.");
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error adding goal: $e");
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalName) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentGoals =
            userDoc['financialGoals'] as Map<String, dynamic>? ?? {};

        // Check if the goal exists
        if (currentGoals.containsKey(goalName)) {
          // Remove the goal by its name
          currentGoals.remove(goalName);

          // Update the document with the modified goals list
          await userDocRef.update({
            'financialGoals': currentGoals,
          });
          debugPrint('Goal "$goalName" has been deleted successfully.');
        } else {
          debugPrint('Goal "$goalName" not found.');
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error deleting goal: $e");
      rethrow;
    }
  }

  Future<void> editGoal(Map<String, dynamic> goalData) async {
    try {
      final userDocRef =
          spendlyCollection.doc(uid); // Reference to the user's document
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentGoals =
            userDoc['financialGoals'] as Map<String, dynamic>? ?? {};

        final String oldGoalName = goalData['name']; // Existing goal name
        final String newGoalName =
            goalData['newName']; // New goal name after edit
        final targetAmount = goalData['targetAmount'] as double;
        final savedAmount = goalData['savedAmount'] as double;
        final goalReach = goalData['goalReach'] as bool;
        final note = goalData['note']; // Optional note for the goal
        final date = goalData['date']; // Date for the goal

        // Check if the old goal exists
        if (currentGoals.containsKey(oldGoalName)) {
          // Goal exists, now we will modify it

          // Remove the old goal using the old name
          currentGoals.remove(oldGoalName);

          // Add the goal with the new name
          currentGoals[newGoalName] = {
            'targetAmount': targetAmount,
            'savedAmount': savedAmount,
            'goalReach': goalReach,
            'note': note,
            'date': date,
          };

          // Update the Firestore document with the modified goals
          await userDocRef.update({
            'financialGoals': currentGoals,
          });

          debugPrint("Goal updated successfully with new name.");
        } else {
          debugPrint("Goal with name $oldGoalName not found.");
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error editing goal: $e");
      rethrow;
    }
  }

  Future<void> addMoneyToGoal(
      String goalName, double amount, Map<String, dynamic> goalData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      final currentBalance = (userDoc['accountBalance']
              as Map<String, dynamic>?)?['amount'] as double? ??
          0.0;
      final currentTransactions =
          userDoc['transactions'] as Map<String, dynamic>? ?? {};

      if (!userDoc.exists) {
        log('User document not found!');
        return;
      }

      final currentGoals =
          userDoc['financialGoals'] as Map<String, dynamic>? ?? {};

      if (currentBalance < amount) {
        throw Exception("Insufficient balance!");
      }

      if (currentGoals.containsKey(goalName)) {
        var goal = currentGoals[goalName];

        // Update savedAmount for the goal
        goal['savedAmount'] += amount;

        // Deduct balance
        double newBalance = currentBalance - amount;

        // Check if the goal is reached
        double targetAmount = (goal['targetAmount'] as num?)?.toDouble() ?? 0.0;
        if (goal['savedAmount'] >= targetAmount) {
          goal['goalReach'] = true;
        }

        // Save updated goal
        currentGoals[goalName] = goal;
        final DateTime now = DateTime.now();

        // Create a transaction for adding money to the financial goal
        final newTransaction = {
          'amount': amount,
          'category': "Financial Goal",
          'goalName': goalName, // Track which goal it was added to
          'date': DateTime.now().toIso8601String(),
          'time': DateFormat('HH:mm:ss').format(now),
        };

        // Add transaction to "financialGoal" category
        if (currentTransactions.containsKey("Financial Goal")) {
          (currentTransactions["Financial Goal"] as List).add(newTransaction);
        } else {
          currentTransactions["Financial Goal"] = [newTransaction];
        }

        // Update Firestore with new transactions, goals, and balance
        await userDocRef.update({
          'financialGoals': currentGoals,
          'accountBalance.amount': newBalance,
          'transactions': currentTransactions, // Save transaction
        });

        log('Money added successfully to the goal and recorded as transaction');
      } else {
        log('Goal not found!');
      }
    } catch (e) {
      log('Error adding money to goal: $e');
      rethrow;
    }
  }

  Future<void> addMoneyToBudget(String budgetCategory, String budgetName,
      double amount, Map<String, dynamic> budgetData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        log('User document not found!');
        return;
      }

      final currentBalance = (userDoc['accountBalance']
              as Map<String, dynamic>?)?['amount'] as double? ??
          0.0;

      final currentTransactions =
          userDoc['transactions'] as Map<String, dynamic>? ?? {};

      final currentBudgets = userDoc['budgets'] as Map<String, dynamic>? ?? {};

      if (currentBalance < amount) {
        throw Exception("Insufficient balance!");
      }

      if (!currentBudgets.containsKey(budgetCategory)) {
        log('Budget category not found!');
        return;
      }

      List<dynamic> budgetList = List.from(currentBudgets[budgetCategory]);

      // Find the budget inside the list
      int budgetIndex =
          budgetList.indexWhere((budget) => budget['name'] == budgetName);

      if (budgetIndex == -1) {
        log('Budget not found!');
        return;
      }

      // Update progressSpending
      budgetList[budgetIndex]['progressSpending'] =
          (budgetList[budgetIndex]['progressSpending'] as double? ?? 0.0) +
              amount;

      double newBalance = currentBalance - amount;

      final DateTime now = DateTime.now();
      final newTransaction = {
        'amount': amount,
        'category': budgetData['category'] ?? budgetCategory,
        'budgetName': budgetName,
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('HH:mm:ss').format(now),
      };

      if (!currentTransactions.containsKey(budgetCategory)) {
        currentTransactions[budgetCategory] = [];
      }
      (currentTransactions[budgetCategory] as List).add(newTransaction);

      await userDocRef.update({
        'budgets.$budgetCategory': budgetList,
        'accountBalance.amount': newBalance,
        'transactions': currentTransactions,
      });

      log('Money added successfully to $budgetName in $budgetCategory');
    } catch (e) {
      log('Error adding money to budget: $e');
      rethrow;
    }
  }

  Future<void> markAsReach(
      String goalName, bool goalReach, Map<String, dynamic> goalData) async {
    try {
      final userDocRef =
          spendlyCollection.doc(uid); // Reference to user document
      final userDoc = await userDocRef.get(); // Fetch user document

      if (userDoc.exists) {
        final currentGoals =
            userDoc['financialGoals'] as Map<String, dynamic>? ?? {};

        // Find the specific goal by name (make sure goal name is unique)
        if (currentGoals.containsKey(goalName)) {
          var goal = currentGoals[goalName];

          // Update goalReach status
          goal['goalReach'] = goalReach;

          // Save the updated goal back into the financialGoals map
          currentGoals[goalName] = goal;

          // Update the Firestore document with the new financialGoals map
          await userDocRef.update({
            'financialGoals': currentGoals,
          });

          log('Successfully marked as reached');
        } else {
          log('Goal not found!');
        }
      } else {
        log('User document not found!');
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  Future<void> addBill(Map<String, dynamic> billData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // Retrieve current account balance, transactions, and budgets
        final currentBill =
            userDoc['billReminders'] as Map<String, dynamic>? ?? {};

        final billName = billData['billName'] as String;
        final dueDate = billData['dueDate'];
        final billStatus = billData['status'] = false;

        final billAmount = (billData.containsKey('billAmount') &&
                billData['billAmount'] != null)
            ? (billData['billAmount'] as num).toDouble() // Ensure it's a double
            : 0.0; // Default value

        // Prepare the new transaction
        final newBill = {
          'billAmount': billAmount,
          'dueDate': dueDate,
          'status': billStatus,
        };

        currentBill[billName] = newBill;

        // Update the user's financial goals in Firestore
        await userDocRef.update({
          'billReminders': currentBill, // Save the updated financialGoals map
        });

        debugPrint("Bill added successfully.");
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error adding bill: $e");
      rethrow;
    }
  }

  Future<void> deleteBill(String billName) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentBills =
            userDoc['billReminders'] as Map<String, dynamic>? ?? {};

        // Check if the goal exists
        if (currentBills.containsKey(billName)) {
          // Remove the goal by its name
          currentBills.remove(billName);

          // Update the document with the modified goals list
          await userDocRef.update({
            'billReminders': currentBills,
          });
          debugPrint('BIll "$billName" has been deleted successfully.');
        } else {
          debugPrint('Bill "$billName" not found.');
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error deleting bill: $e");
      rethrow;
    }
  }

  Future<void> updateStatus(String billName) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentBills =
            (userDoc['billReminders'] as Map<String, dynamic>?) ?? {};

        // Check if the bill exists
        if (currentBills.containsKey(billName)) {
          // Update the status of the specific bill
          currentBills[billName]['status'] = true;

          // Update the document in Firestore
          await userDocRef.update({
            'billReminders': currentBills,
          });

          debugPrint('Bill "$billName" status has been updated to paid.');
        } else {
          debugPrint('Bill "$billName" not found.');
        }
      } else {
        debugPrint("User document does not exist.");
      }
    } catch (e) {
      debugPrint("Error updating bill status: $e");
      rethrow;
    }
  }

  // Updated editBill function
  Future<void> editBill(Map<String, dynamic> billData) async {
    try {
      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final currentBills =
            userDoc['billReminders'] as Map<String, dynamic>? ?? {};

        final String oldBillName = billData['oldBillName'];
        final String newBillName = billData['newBillName'];

        if (currentBills.containsKey(oldBillName)) {
          // Get existing bill data

          // Remove old entry
          currentBills.remove(oldBillName);

          // Add updated entry
          currentBills[newBillName] = {
            'billAmount': billData['billAmount'],
            'dueDate': billData['dueDate'],
            'status': billData['status'],
          };

          await userDocRef.update({
            'billReminders': currentBills,
          });
        }
      }
    } catch (e) {
      debugPrint("Error editing bill: $e");
      rethrow;
    }
  }

  Future<Map<String, double>> fetchExpenses(String selectedMonthYear) async {
    try {
      if (uid == null || uid!.isEmpty) throw "No user logged in";

      final userDoc = await spendlyCollection.doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw "User data not found";
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final transactions = data['transactions'] as Map<String, dynamic>?;

      if (transactions == null) throw "No transactions found";

      final Map<String, double> monthlyExpenses = {};

      for (final entry in transactions.entries) {
        final category = entry.key;

        // Skip the "Income" category
        if (category == "Income") {
          continue;
        }

        final expenses = entry.value;

        if (expenses is List) {
          for (final expense in expenses) {
            if (expense is Map<String, dynamic> &&
                expense.containsKey('date') &&
                expense.containsKey('amount')) {
              final formattedDate = _formatDate(expense['date']);
              if (formattedDate.isEmpty) continue;

              final expenseDate = DateTime.parse(formattedDate);
              final monthYear =
                  "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}";

              if (monthYear == selectedMonthYear) {
                monthlyExpenses[category] = (monthlyExpenses[category] ?? 0) +
                    (expense['amount'] as num).toDouble();
              }
            }
          }
        }
      }

      return monthlyExpenses;
    } catch (e) {
      throw "Error fetching expenses: $e";
    }
  }

  Future<void> editTransaction(Map<String, dynamic> transactionData) async {
    try {
      // Validate transactionIndex exists and is valid
      final transactionIndex = transactionData['transactionIndex'] ??
          transactionData['categoryIndex'];
      if (transactionIndex == null) {
        throw Exception('Transaction index is required');
      }

      final userDocRef = spendlyCollection.doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) return;

      final currentTransactions = Map<String, dynamic>.from(
          userDoc['transactions'] as Map<String, dynamic>? ?? {});

      final String oldCategory = transactionData['oldCategory'];
      final String newCategory = transactionData['newCategory'];

      if (!currentTransactions.containsKey(oldCategory)) {
        throw Exception('Category $oldCategory not found');
      }

      final oldTransactions = List<Map<String, dynamic>>.from(
          currentTransactions[oldCategory] ?? []);

      if (transactionIndex < 0 || transactionIndex >= oldTransactions.length) {
        throw Exception('Invalid transaction index: $transactionIndex');
      }

      // Remove the old transaction
      oldTransactions.removeAt(transactionIndex);
      currentTransactions[oldCategory] = oldTransactions;

      // Add the new transaction
      final newTransaction = {
        'amount': transactionData['newAmount'],
        'category': newCategory,
        'date': transactionData['newDate'],
        'time': transactionData['newTime'],
      };

      if (!currentTransactions.containsKey(newCategory)) {
        currentTransactions[newCategory] = [];
      }
      currentTransactions[newCategory]!.add(newTransaction);

      // Update Firestore
      await userDocRef.update({'transactions': currentTransactions});
    } catch (e) {
      debugPrint("Error editing transaction: $e");
      rethrow;
    }
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // Stream to listen for real-time updates on the user document
  Stream<DocumentSnapshot> get userInfoStream {
    return spendlyCollection.doc(uid).snapshots();
  }

  // Stream for Budget data
  Stream<QuerySnapshot> get userInfo {
    return spendlyCollection.snapshots();
  }
}
