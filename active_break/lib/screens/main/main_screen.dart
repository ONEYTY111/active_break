import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement.dart';
import '../../widgets/achievement_notification.dart';
import '../../utils/app_localizations.dart';
import 'home_screen.dart';
import 'exercise_screen.dart';
import 'recommend_screen.dart';
import 'profile_screen.dart';
import '../widgets/check_in_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() {
    print('=== MainScreen: Creating MainScreen instance ===');
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExerciseScreen(),
    const SizedBox(), // Placeholder for center button
    const RecommendScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    print('=== MainScreen: initState called ===');
    // Delay to next frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== MainScreen: PostFrameCallback executed ===');
      _waitForUserAndLoadData();
    });
  }

  Future<void> _waitForUserAndLoadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Wait for UserProvider to complete initialization
    int attempts = 0;
    while (userProvider.isLoading && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('=== MainScreen: Starting to load initial data ===');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    print('MainScreen: Current user: ${userProvider.currentUser}');
    print('MainScreen: Login status: ${userProvider.isLoggedIn}');

    if (userProvider.currentUser != null) {
      final userId = userProvider.currentUser!.userId!;
      print('MainScreen: Loading data for user ID $userId');
      await activityProvider.loadActivities();
      await activityProvider.loadRecentRecords(userId);
      await activityProvider.loadCheckinStreak(userId);
      
      // Initialize achievement data
      achievementProvider.setUserProvider(userProvider);
      await achievementProvider.initialize();
      
      print('MainScreen: Data loading completed');
    } else {
      print('MainScreen: No current user, skipping data loading');
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _showCheckInDialog();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _showCheckInDialog() async {
    debugPrint('=== _showCheckInDialog starting execution ===');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) {
      debugPrint('=== User not logged in, exiting check-in process ===');
      return;
    }

    debugPrint('=== Starting check-in operation, user ID: ${userProvider.currentUser!.userId} ===');
    final success = await activityProvider.checkInToday(
      userProvider.currentUser!.userId!,
    );
    debugPrint('=== Check-in operation result: $success ===');

    List<Achievement> newAchievements = [];
    // If check-in successful, check achievements (but don't show popup immediately)
    if (success) {
      newAchievements = await achievementProvider.checkAndUpdateAchievements();
      // Reload achievement data
      await achievementProvider.loadUserAchievements();
      await achievementProvider.loadAchievementStats();
    }

    if (mounted) {
      debugPrint('=== Widget mounted, preparing to show dialog ===');
      if (success) {
        debugPrint('=== Check-in successful, showing success dialog ===');
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon and animation effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.celebration, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 20),

                // Main title
                Text(
                  AppLocalizations.of(
                    context,
                  ).translate('check_in_congratulations'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppLocalizations.of(context).translate('check_in_success'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Consecutive check-in information
                if (activityProvider.checkinStreak != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context).translate('consecutive_days')}: ${activityProvider.checkinStreak!.currentStreak} ${AppLocalizations.of(context).translate('days')}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('keep_it_up'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Show achievement popup after check-in success dialog closes
                      if (newAchievements.isNotEmpty) {
                        // Use WidgetsBinding.instance.addPostFrameCallback to ensure display in next frame
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && context.mounted) {
                            AchievementNotification.show(
                              context,
                              newAchievements,
                            );
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('confirm'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        debugPrint('=== Check-in failed or already checked in, showing alert dialog ===');
        showDialog(
          context: context,
          barrierDismissible: true,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alert icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),

                // Prompt text
                Text(
                  AppLocalizations.of(context).translate('already_checked_in'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  AppLocalizations.of(
                    context,
                  ).translate('already_checked_in_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('confirm'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home,
                  AppLocalizations.of(context).translate('home'),
                ),
                _buildNavItem(
                  1,
                  Icons.fitness_center,
                  AppLocalizations.of(context).translate('exercise'),
                ),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(
                  3,
                  Icons.recommend,
                  AppLocalizations.of(context).translate('recommend'),
                ),
                _buildNavItem(
                  4,
                  Icons.person,
                  AppLocalizations.of(context).translate('profile'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: CheckInButton(
        onPressed: () => _showCheckInDialog(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
