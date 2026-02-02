import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BillNotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showBillReminderNotification({
    required int id,
    required String billName,
    required double amount,
    required String dueDate,
    required int daysLeft,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'bill_reminders_channel',
      'Bill Reminders',
      channelDescription: 'Notifications for upcoming bill payments',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await notificationsPlugin.show(
      id,
      'Bill Payment Due Soon!',
      '$billName is due in $daysLeft day${daysLeft > 1 ? 's' : ''} on $dueDate.\nAmount: RM${amount.toStringAsFixed(2)}',
      notificationDetails,
    );
  }

  Future<void> showOverdueBillNotification({
    required int id,
    required String billName,
    required double amount,
    required String dueDate,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'overdue_bills_channel',
      'Overdue Bills',
      channelDescription: 'Notifications for overdue bills',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    await notificationsPlugin.show(
      id,
      'OVERDUE BILL: $billName',
      'RM${amount.toStringAsFixed(2)} was due on $dueDate',
      const NotificationDetails(android: androidNotificationDetails),
    );
  }
}

class BillNotificationManager {
  final BillNotificationService _notificationService;
  bool _notificationsSent = false;

  BillNotificationManager(this._notificationService);

  Future<void> checkAndSendNotifications(Map<String, dynamic>? bills) async {
    if (_notificationsSent || bills == null) return;

    DateTime currentDate = DateTime.now();
    int notificationCounter = 0;

    final billEntries = bills.entries.toList();

    for (final entry in billEntries) {
      final billData = entry.value;
      if (billData is! Map<String, dynamic> || billData['status'] == true) {
        continue;
      }

      DateTime? dueDate;
      final dateRaw = billData['dueDate'];

      if (dateRaw is Timestamp) {
        dueDate = dateRaw.toDate();
      } else if (dateRaw is String) {
        final dateParts = dateRaw.split('-');
        if (dateParts.length == 3) {
          dueDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      }

      if (dueDate != null && dueDate.isAfter(currentDate)) {
        final daysRemaining = dueDate.difference(currentDate).inDays;
        if (daysRemaining <= 7) {
          final billAmount = (billData['billAmount'] ?? 0).toDouble();
          final formattedDate = dateRaw is Timestamp
              ? "${dueDate.year}-${dueDate.month}-${dueDate.day}"
              : dateRaw;

          await Future.delayed(
              Duration(milliseconds: 300 * notificationCounter));
          await _notificationService.showBillReminderNotification(
            id: notificationCounter,
            billName: entry.key,
            amount: billAmount,
            dueDate: formattedDate,
            daysLeft: daysRemaining,
          );
          notificationCounter++;
        }
      }
    }

    _notificationsSent = true;
  }

  void reset() {
    _notificationsSent = false;
  }
}
