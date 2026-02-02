import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePicker({super.key, required this.initialTime});

  @override
  // ignore: library_private_types_in_public_api
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showTimePickerDialog(context);
      },
      child: Text("Pick Time"),
    );
  }

  void _showTimePickerDialog(BuildContext context) async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Time",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Divider
                Positioned(
                  top: 50,
                  left: 40,
                  right: 40,
                  child: Divider(thickness: 2, height: 2),
                ),
                // Bottom Divider
                Positioned(
                  bottom: 50,
                  left: 40,
                  right: 40,
                  child: Divider(thickness: 2, height: 2),
                ),
                // Time Picker using ListWheelScrollView
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeScroll(0, 23, selectedHour, (value) {
                      setState(() {
                        selectedHour = value;
                      });
                    }),
                    const SizedBox(width: 10),
                    const Text(
                      ':',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    _buildTimeScroll(0, 59, selectedMinute, (value) {
                      setState(() {
                        selectedMinute = value;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            // OK Button
            TextButton(
              onPressed: () {
                Navigator.pop(context,
                    TimeOfDay(hour: selectedHour, minute: selectedMinute));
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Handle the result (updated time) here if needed
      setState(() {
        selectedHour = result.hour;
        selectedMinute = result.minute;
      });
    }
  }

  Widget _buildTimeScroll(
      int minValue, int maxValue, int selectedValue, Function(int) onChanged) {
    return Container(
      width: 60,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50.0,
        diameterRatio: 1.5,
        physics: FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final value = (minValue + index) % (maxValue + 1);
            return Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: selectedValue == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selectedValue == value ? Colors.blue : Colors.black,
                ),
              ),
            );
          },
          childCount: maxValue - minValue + 1,
        ),
      ),
    );
  }
}
