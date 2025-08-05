import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/activity_provider.dart';
import '../../utils/app_localizations.dart';
import 'home_screen.dart';
import 'exercise_screen.dart';
import 'recommend_screen.dart';
import 'profile_screen.dart';
import '../widgets/check_in_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
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
    // 延迟到下一帧执行，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      await activityProvider.loadActivities();
      await activityProvider.loadRecentRecords(
        userProvider.currentUser!.userId!,
      );
      await activityProvider.loadCheckinStreak(
        userProvider.currentUser!.userId!,
      );
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center button (check-in) tapped
      _showCheckInDialog();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _showCheckInDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return;

    final success = await activityProvider.checkInToday(
      userProvider.currentUser!.userId!,
    );

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context).translate('check_in_success'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                if (activityProvider.checkinStreak != null)
                  Text(
                    '${AppLocalizations.of(context).translate('consecutive_days')}: ${activityProvider.checkinStreak!.currentStreak} ${AppLocalizations.of(context).translate('days')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).translate('confirm')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('already_checked_in'),
            ),
            backgroundColor: Colors.orange,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
