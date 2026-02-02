import 'package:flutter/material.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Exit'),
            content: Text(
                'Are you sure you want to exit without saving your changes?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // User pressed No, don't exit
                },
                child: Text(
                  'NO',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User pressed Yes, exit
                },
                child: Text(
                  'YES',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
            ],
          );
        },
      ) ??
      false; // In case the dialog is closed without selecting an option
}

Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Exit'),
            content: Text('Dou you really want to delete this item?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // User pressed No, don't exit
                },
                child: Text(
                  'NO',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User pressed Yes, exit
                },
                child: Text(
                  'YES',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
            ],
          );
        },
      ) ??
      false; // In case the dialog is closed without selecting an option
}

Future<bool> showEditConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Edit Item?'),
            content: Text('Do you really want to edit this item?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // User pressed No, don't exit
                },
                child: Text(
                  'NO',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User pressed Yes, exit
                },
                child: Text(
                  'YES',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                ),
              ),
            ],
          );
        },
      ) ??
      false; // In case the dialog is closed without selecting an option
}
