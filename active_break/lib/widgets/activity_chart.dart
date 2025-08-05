import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/physical_activity.dart';

class ActivityChart extends StatelessWidget {
  final List<ActivityRecord> weeklyRecords;

  const ActivityChart({super.key, required this.weeklyRecords});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity Trend',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final weekData = _getWeekData();

    if (weekData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No activity data this week',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: weekData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = _getDayName(group.x.toInt());
              return BarTooltipItem(
                '$day\n${rod.toY.round()} min',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _getDayAbbr(value.toInt()),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: weekData.map((data) {
          return BarChartGroupData(
            x: data.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: data.y,
                color: Theme.of(context).colorScheme.primary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<FlSpot> _getWeekData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final weekData = <FlSpot>[];

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayRecords = weeklyRecords.where((record) {
        return record.beginTime.year == day.year &&
            record.beginTime.month == day.month &&
            record.beginTime.day == day.day;
      });

      final totalMinutes = dayRecords.fold<int>(
        0,
        (sum, record) => sum + record.durationMinutes,
      );

      weekData.add(FlSpot(i.toDouble(), totalMinutes.toDouble()));
    }

    return weekData;
  }

  String _getDayName(int dayIndex) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayIndex];
  }

  String _getDayAbbr(int dayIndex) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayIndex];
  }
}
