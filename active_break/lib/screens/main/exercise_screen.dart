import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/activity_icons.dart';
import '../../widgets/reminder_settings_dialog.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('exercise')),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          if (activityProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Timer display (if running)
              if (activityProvider.isTimerRunning)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('timer_running'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<ActivityProvider>(
                        builder: (context, provider, child) {
                          final duration = provider.elapsedTime;
                          final minutes = duration.inMinutes;
                          final seconds = duration.inSeconds % 60;

                          return Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _stopTimer(context),
                            icon: const Icon(Icons.stop),
                            label: Text(
                              AppLocalizations.of(context).translate('stop'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _saveRecord(context),
                            icon: const Icon(Icons.save),
                            label: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('save_record'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Activities list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activityProvider.activities.length,
                  itemBuilder: (context, index) {
                    final activity = activityProvider.activities[index];
                    final isCurrentActivity =
                        activityProvider.isTimerRunning &&
                        activityProvider.currentActivityId ==
                            activity.activityTypeId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: isCurrentActivity
                              ? Theme.of(context).colorScheme.primary
                              : ActivityIcons.getColorByActivityType(
                                  activity.activityTypeId!,
                                ).withValues(alpha: 0.2),
                          child: Icon(
                            ActivityIcons.getIconByActivityType(
                              activity.activityTypeId!,
                            ),
                            color: isCurrentActivity
                                ? Theme.of(context).colorScheme.onPrimary
                                : ActivityIcons.getColorByActivityType(
                                    activity.activityTypeId!,
                                  ),
                          ),
                        ),
                        title: Text(
                          activity.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(activity.description),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${activity.defaultDuration} ${AppLocalizations.of(context).translate('minutes')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${activity.caloriesPerMinute}/min',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 80,
                              child: ElevatedButton(
                                onPressed: isCurrentActivity
                                    ? null
                                    : () => _startActivity(
                                        context,
                                        activity.activityTypeId!,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: Text(
                                  isCurrentActivity
                                      ? AppLocalizations.of(
                                          context,
                                        ).translate('timer_running')
                                      : AppLocalizations.of(
                                          context,
                                        ).translate('start'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: OutlinedButton(
                                onPressed: () => _showReminderSettings(
                                  context,
                                  activity.activityTypeId!,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('set_reminder'),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startActivity(BuildContext context, int activityId) {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (activityProvider.isTimerRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please stop the current timer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    activityProvider.startTimer(activityId);

    // Start a timer to update the UI every second
    _startTimerUpdates();
  }

  void _startTimerUpdates() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      if (activityProvider.isTimerRunning) {
        activityProvider.updateTimer();
        return true;
      }
      return false;
    });
  }

  void _stopTimer(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    activityProvider.stopTimer();
  }

  Future<void> _saveRecord(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return;

    final success = await activityProvider.saveActivityRecord(
      userProvider.currentUser!.userId!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('record_saved'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save record'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReminderSettings(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (context) => ReminderSettingsDialog(activityTypeId: activityId),
    );
  }
}
