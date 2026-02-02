import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChartData {
  final String category;
  final double amount;

  PieChartData({required this.category, required this.amount});
}

class PieChartWidget extends StatefulWidget {
  final Map<String, double> monthlyExpenses;

  const PieChartWidget({super.key, required this.monthlyExpenses});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _explodeIndex = -1; // -1 means no explosion initially

  @override
  Widget build(BuildContext context) {
    double totalAmount =
        widget.monthlyExpenses.values.fold(0, (sum, item) => sum + item);
    List<PieChartData> pieData = [];

    widget.monthlyExpenses.forEach((category, amount) {
      pieData.add(PieChartData(category: category, amount: amount));
    });

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          SfCircularChart(
            title: ChartTitle(
                text: 'Expenses by Category',
                textStyle: TextStyle(fontWeight: FontWeight.w600)),
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              itemPadding: 10,
            ),
            series: <CircularSeries>[
              DoughnutSeries<PieChartData, String>(
                radius: '50%',
                dataSource: pieData,
                xValueMapper: (PieChartData data, _) => data.category,
                yValueMapper: (PieChartData data, _) => data.amount,
                dataLabelMapper: (PieChartData data, _) =>
                    '${data.category} \n${(data.amount / totalAmount * 100).toStringAsFixed(1)}%',
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  connectorLineSettings: ConnectorLineSettings(
                    type: ConnectorType.curve,
                    length: '10%',
                  ),
                  textStyle: TextStyle(
                    fontSize: 10,
                    overflow: TextOverflow.clip,
                  ),
                ),
                explode:
                    _explodeIndex != -1, // Only explode when index is valid
                explodeIndex: _explodeIndex,
                onPointTap: (ChartPointDetails details) {
                  setState(() {
                    // Toggle explosion - tap again to reset
                    _explodeIndex = (_explodeIndex == details.pointIndex!)
                        ? -1
                        : details.pointIndex!;
                  });
                },
                startAngle: 90,
                endAngle: 90,
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Spending',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'RM${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
