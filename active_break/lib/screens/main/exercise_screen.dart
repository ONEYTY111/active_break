import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/activity_icons.dart';
import '../../models/physical_activity.dart';
import '../../services/database_service.dart';
import '../../widgets/reminder_settings_dialog.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  bool _isAutoCompleting = false; // Prevent duplicate auto-completion

  @override
  void initState() {
    super.initState();
    // Ensure activities are loaded when entering this tab (handles auto-login case)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      if (activityProvider.activities.isEmpty) {
        print(
          'Loading activities - current count: ${activityProvider.activities.length}',
        );
        await activityProvider.loadActivities();
        print(
          'After loadActivities - count: ${activityProvider.activities.length}',
        );
        for (final activity in activityProvider.activities) {
          print(
            'Activity: ID=${activity.activityTypeId}, Name=${activity.name}',
          );
        }
      }
      await loadLocalizedDescriptions();
      print(
        'After localization - count: ${activityProvider.activities.length}',
      );
      for (final activity in activityProvider.activities) {
        print(
          'Localized Activity: ID=${activity.activityTypeId}, Name=${activity.name}',
        );
      }
    });
  }

  Future<void> loadLocalizedDescriptions() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final databaseService = DatabaseService();

    try {
      // Query localized descriptions for current locale
      final db = await databaseService.database;
      final locale = languageProvider.locale.languageCode;
      final rows = await db.rawQuery(
        'SELECT activity_type_id, name, description FROM t_physical_activities_i18n WHERE language_code = ?',
        [locale],
      );

      final i18nMap = {
        for (final row in rows) row['activity_type_id'] as int: row,
      };

      // Update activities with localized names and descriptions
      final updatedActivities = activityProvider.activities.map((activity) {
        final i18n = i18nMap[activity.activityTypeId];
        if (i18n != null) {
          return PhysicalActivity(
            activityTypeId: activity.activityTypeId,
            name: i18n['name'] as String? ?? activity.name,
            description: i18n['description'] as String? ?? activity.description,
            caloriesPerMinute: activity.caloriesPerMinute,
            defaultDuration: activity.defaultDuration,
            iconUrl: activity.iconUrl,
          );
        }
        return activity;
      }).toList();

      activityProvider.setActivities(updatedActivities);
    } catch (e) {
      // Fallback: i18n table doesn't exist, skip localization
      debugPrint('Could not load localized descriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('exercise')),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          // Check if auto-completion is needed
          if (activityProvider.needsAutoComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoCompleteActivity(context);
            });
          }

          if (activityProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activityProvider.activities.length,
            itemBuilder: (context, index) {
              final activity = activityProvider.activities[index];
              final isCurrentActivity =
                  activityProvider.isTimerRunning &&
                  activityProvider.currentActivityId == activity.activityTypeId;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon and title
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isCurrentActivity
                                ? Theme.of(context).colorScheme.primary
                                : ActivityIcons.getColorByActivityType(
                                    activity.activityTypeId!,
                                  ).withValues(alpha: 0.8),
                            child: Icon(
                              // Prefer mapped icon by activity type id; if none, derive by name
                              ActivityIcons.activityTypeIcons.containsKey(
                                    activity.activityTypeId!,
                                  )
                                  ? ActivityIcons.getIconByActivityType(
                                      activity.activityTypeId!,
                                    )
                                  : ActivityIcons.getFallbackIcon(
                                      activity.name,
                                    ),
                              color: isCurrentActivity
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : ActivityIcons.getColorByActivityType(
                                      activity.activityTypeId!,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: null,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrentActivity) ...[
                            // Active: Timer, End, Reminder
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Consumer<ActivityProvider>(
                                builder: (context, provider, _) {
                                  // Display countdown remaining time
                                  final duration = provider.remainingTime;
                                  final hours = duration.inHours;
                                  final minutes = duration.inMinutes % 60;
                                  final seconds = duration.inSeconds % 60;

                                  // Check if auto-completion is needed
                                  if (provider.needsAutoComplete &&
                                      !_isAutoCompleting) {
                                    _isAutoCompleting = true;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _autoCompleteActivity(context);
                                        });
                                  }

                                  return Text(
                                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _stopAndSaveActivity(context),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(36, 36),
                                ),
                                child: const Icon(Icons.stop, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () => _showReminderSettings(
                                  context,
                                  activity.activityTypeId!,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(36, 36),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  size: 18,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Inactive: Start, Reminder
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _startActivity(
                                  context,
                                  activity.activityTypeId!,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(36, 36),
                                ),
                                child: const Icon(Icons.play_arrow, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () => _showReminderSettings(
                                  context,
                                  activity.activityTypeId!,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(36, 36),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                          // Removed duplicate trailing controls (extra reminder and start/stop buttons)
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Activity information row
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

                      // Keep bottom compact, no extra button row
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
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

    // Check if there's already an exercise in progress
    if (activityProvider.isTimerRunning) {
      // Get the name of the currently ongoing exercise
      final currentActivity = activityProvider.activities.firstWhere(
        (activity) =>
            activity.activityTypeId == activityProvider.currentActivityId,
        orElse: () => PhysicalActivity(
          activityTypeId: 0,
          name: AppLocalizations.of(context).translate('unknown_activity'),
          description: '',
          caloriesPerMinute: 0,
          defaultDuration: 0,
          iconUrl: '',
        ),
      );

      // Show prompt information
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)
                .translate('already_exercising')
                .replaceAll('{activity}', currentActivity.name),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    activityProvider.startTimer(activityId);
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
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return;

    final success = await activityProvider.saveActivityRecord(
      userProvider.currentUser!.userId!,
    );

    // If exercise record is saved successfully, check achievements
    if (success) {
      await achievementProvider.checkAchievementsAfterExercise(context);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('record_saved'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('save_record_failed'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Save record silently without showing notifications
  /// @author Author
  /// @date Current date and time
  /// @param context Build context
  /// @return Future<bool> Returns true if save was successful
  Future<bool> _saveRecordSilently(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return false;

    final success = await activityProvider.saveActivityRecord(
      userProvider.currentUser!.userId!,
    );

    // If exercise record is saved successfully, check achievements
    if (success) {
      await achievementProvider.checkAchievementsAfterExercise(context);
    }

    return success;
  }

  Future<void> _stopAndSaveActivity(BuildContext context) async {
    // Do not stop timer first; saveActivityRecord will stop it upon success
    await _saveRecord(context);
  }

  Future<void> _autoCompleteActivity(BuildContext context) async {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    // Clear auto-completion flag to avoid repeated triggers
    activityProvider.clearAutoCompleteFlag();

    // Auto-complete exercise and save record
    final success = await _saveRecordSilently(context);

    // Reset duplicate prevention flag
    _isAutoCompleting = false;

    // Show auto-completion prompt only if save was successful
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('activity_auto_completed'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showReminderSettings(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (context) => ReminderSettingsDialog(activityTypeId: activityId),
    );
  }
}
