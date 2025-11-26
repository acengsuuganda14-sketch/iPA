import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';

class FinanceChart extends StatelessWidget {
  final TransactionProvider transactionProvider;

  const FinanceChart({Key? key, required this.transactionProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Statistik 7 Hari Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final dates = _getLast7Days();
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${dates[index].day}/${dates[index].month}',
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 100000 == 0) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}k',
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _prepareIncomeData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: _prepareExpenseData(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.green, 'Pemasukan'),
                SizedBox(width: 16),
                _buildLegend(Colors.red, 'Pengeluaran'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<FlSpot> _prepareIncomeData() {
    List<FlSpot> data = [];
    final weeklyData = transactionProvider.weeklyIncomeData;
    final dates = _getLast7Days();

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final amount = weeklyData[date] ?? 0;
      data.add(FlSpot(i.toDouble(), amount));
    }
    return data;
  }

  List<FlSpot> _prepareExpenseData() {
    List<FlSpot> data = [];
    final weeklyData = transactionProvider.weeklyExpenseData;
    final dates = _getLast7Days();

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final amount = weeklyData[date] ?? 0;
      data.add(FlSpot(i.toDouble(), amount));
    }
    return data;
  }

  List<DateTime> _getLast7Days() {
    List<DateTime> days = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      days.add(DateTime(now.year, now.month, now.day - i));
    }
    return days;
  }
}