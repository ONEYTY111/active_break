import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_localizations.dart';
import '../../models/achievement.dart';
import '../../models/user_achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final achievementProvider = Provider.of<AchievementProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      // Set UserProvider and load data based on current language
      achievementProvider.setUserProvider(userProvider);
      _loadAchievementsWithLanguage(achievementProvider, languageProvider);
    });
  }

  /// Load achievements with specific language
  Future<void> _loadAchievementsWithLanguage(
    AchievementProvider achievementProvider,
    LanguageProvider languageProvider,
  ) async {
    final languageCode = languageProvider.locale.languageCode;
    await achievementProvider.reloadWithLanguage(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('my_achievements')),
        elevation: 0,
      ),
      body: Consumer2<AchievementProvider, LanguageProvider>(
        builder: (context, achievementProvider, languageProvider, child) {
          // Reload achievement data when language changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentLanguage = languageProvider.locale.languageCode;
            // Always reload when language changes, regardless of current data
            _loadAchievementsWithLanguage(
              achievementProvider,
              languageProvider,
            );
          });
          if (achievementProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (achievementProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    achievementProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => achievementProvider.initialize(),
                    child: Text(
                      AppLocalizations.of(context).translate('retry'),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Achievement statistics card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          Icons.emoji_events,
                          '${achievementProvider.achievedAchievements.length}',
                          AppLocalizations.of(context).translate('completed'),
                        ),
                        _buildStatItem(
                          context,
                          Icons.flag,
                          '${achievementProvider.userAchievements.length}',
                          AppLocalizations.of(context).translate('total'),
                        ),
                        _buildStatItem(
                          context,
                          Icons.percent,
                          '${achievementProvider.userAchievements.isNotEmpty ? (achievementProvider.achievedAchievements.length / achievementProvider.userAchievements.length * 100).toStringAsFixed(0) : "0"}%',
                          AppLocalizations.of(
                            context,
                          ).translate('completion_rate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: achievementProvider.userAchievements.isNotEmpty
                          ? achievementProvider.achievedAchievements.length /
                                achievementProvider.userAchievements.length
                          : 0,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Achievement list
              Expanded(
                child: achievementProvider.userAchievements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).translate('no_achievements_yet'),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: achievementProvider.userAchievements.length,
                        itemBuilder: (context, index) {
                          final userAchievement =
                              achievementProvider.userAchievements[index];
                          return _buildAchievementCard(
                            context,
                            userAchievement,
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

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    UserAchievement userAchievement,
  ) {
    final achievement = userAchievement.achievement;
    final isCompleted = userAchievement.isAchieved;
    final progress = userAchievement.progressPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.1),
              ),
              child: Icon(
                _getAchievementIcon(achievement?.icon ?? ''),
                size: 32,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 16),

            // Achievement information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement?.name ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement?.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  if (!isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).translate('completed'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (userAchievement.achievedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${userAchievement.achievedAt!.year}-${userAchievement.achievedAt!.month.toString().padLeft(2, '0')}-${userAchievement.achievedAt!.day.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'first_login':
        return Icons.login;
      case 'check_in_streak':
        return Icons.calendar_today;
      case 'monthly_active':
        return Icons.calendar_month;
      case 'exercise_beginner':
        return Icons.fitness_center;
      case 'exercise_expert':
        return Icons.sports_gymnastics;
      case 'calorie_burner':
        return Icons.local_fire_department;
      case 'time_master':
        return Icons.timer;
      default:
        return Icons.emoji_events;
    }
  }
}
