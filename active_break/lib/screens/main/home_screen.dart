import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/activity_icons.dart';
import '../../widgets/activity_chart.dart';
import '../../models/physical_activity.dart';
import '../../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<ActivityRecord> _weeklyRecords = [];
  bool _isLoadingWeekly = false;
  int _lastRecordsCount = 0;

  @override
  void initState() {
    super.initState();
    // Delay execution to next frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadLocalizedDescriptions();
      _loadWeeklyData();
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

  Future<void> _loadWeeklyData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      setState(() {
        _isLoadingWeekly = true;
      });

      _weeklyRecords = await activityProvider.getWeeklyRecords(
        userProvider.currentUser!.userId!,
      );

      setState(() {
        _isLoadingWeekly = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Reload localized descriptions when language changes
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await loadLocalizedDescriptions();
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).translate('home')),
            actions: [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      backgroundImage:
                          userProvider.currentUser?.avatarUrl != null
                          ? NetworkImage(userProvider.currentUser!.avatarUrl!)
                          : null,
                      child: userProvider.currentUser?.avatarUrl == null
                          ? Text(
                              userProvider.currentUser?.username
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.waving_hand,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('hello_user').replaceAll('{username}', userProvider.currentUser?.username ?? 'User'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('welcome_message'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Check-in streak section
                Consumer<ActivityProvider>(
                  builder: (context, activityProvider, child) {
                    final streak = activityProvider.checkinStreak;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_fire_department,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('consecutive_days'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${streak?.currentStreak ?? 0} ${AppLocalizations.of(context).translate('days')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent activities section
                Text(
                  AppLocalizations.of(context).translate('recent_activities'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Consumer<ActivityProvider>(
                  builder: (context, activityProvider, child) {
                    if (activityProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (activityProvider.recentRecords.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('no_recent_activities'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('start_exercising_now'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activityProvider.recentRecords.take(5).length,
                      itemBuilder: (context, index) {
                        final record = activityProvider.recentRecords[index];
                        final activity = activityProvider.activities.firstWhere(
                          (a) => a.activityTypeId == record.activityTypeId,
                          orElse: () => activityProvider.activities.first,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  ActivityIcons.getColorByActivityType(
                                    activity.activityTypeId!,
                                  ).withValues(alpha: 0.8),
                              child: Icon(
                                ActivityIcons.getIconByActivityType(
                                  activity.activityTypeId!,
                                ),
                                color: ActivityIcons.getColorByActivityType(
                                  activity.activityTypeId!,
                                ),
                              ),
                            ),
                            title: Text(activity.name),
                            subtitle: Builder(
                              builder: (context) {
                                final start = record.beginTime;
                                final end = record.endTime;
                                String two(int n) =>
                                    n.toString().padLeft(2, '0');
                                final startStr =
                                    '${two(start.hour)}:${two(start.minute)}:${two(start.second)}';
                                final endStr =
                                    '${two(end.hour)}:${two(end.minute)}:${two(end.second)}';
                                final durationStr =
                                    '${record.durationMinutes} ${AppLocalizations.of(context).translate('minutes')}';
                                final caloriesStr =
                                    '${record.caloriesBurned} ${AppLocalizations.of(context).translate('calories')}';
                                return Text(
                                  '$startStr - $endStr • $durationStr • $caloriesStr',
                                );
                              },
                            ),
                            trailing: Builder(
                              builder: (context) {
                                final languageProvider =
                                    Provider.of<LanguageProvider>(context);

                                // Use "MMM d" format for English (e.g., "Dec 12"), M/D format for Chinese
                                final dateStr = languageProvider.isEnglish
                                    ? DateFormat(
                                        'MMM d',
                                      ).format(record.beginTime)
                                    : '${record.beginTime.month}/${record.beginTime.day}';

                                return Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Weekly summary placeholder
                Text(
                  AppLocalizations.of(context).translate('weekly_summary'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Weekly summary card
                Consumer<ActivityProvider>(
                  builder: (context, activityProvider, child) {
                    // Only reload weekly data when recent records change (indicating new activity was added)
                    final currentRecordsCount =
                        activityProvider.recentRecords.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && currentRecordsCount != _lastRecordsCount) {
                        _lastRecordsCount = currentRecordsCount;
                        _loadWeeklyData();
                      }
                    });

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    context,
                                    Icons.timer,
                                    AppLocalizations.of(
                                      context,
                                    ).translate('total_duration'),
                                    '${_getTotalDuration()} ${AppLocalizations.of(context).translate('minutes')}',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSummaryItem(
                                    context,
                                    Icons.local_fire_department,
                                    AppLocalizations.of(
                                      context,
                                    ).translate('total_calories'),
                                    '${_getTotalCalories()} ${AppLocalizations.of(context).translate('calories')}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Activity chart
                if (!_isLoadingWeekly)
                  ActivityChart(weeklyRecords: _weeklyRecords),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getTotalDuration() {
    return _weeklyRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );
  }

  int _getTotalCalories() {
    return _weeklyRecords.fold<int>(
      0,
      (sum, record) => sum + record.caloriesBurned,
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
