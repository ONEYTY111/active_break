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
    print('=== MainScreen: 创建 MainScreen 实例 ===');
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
    print('=== MainScreen: initState 被调用 ===');
    // 延迟到下一帧执行，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== MainScreen: PostFrameCallback 执行 ===');
      _waitForUserAndLoadData();
    });
  }

  Future<void> _waitForUserAndLoadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 等待UserProvider完成初始化
    int attempts = 0;
    while (userProvider.isLoading && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('=== MainScreen: 开始加载初始数据 ===');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    print('MainScreen: 当前用户: ${userProvider.currentUser}');
    print('MainScreen: 登录状态: ${userProvider.isLoggedIn}');

    if (userProvider.currentUser != null) {
      final userId = userProvider.currentUser!.userId!;
      print('MainScreen: 为用户ID $userId 加载数据');
      await activityProvider.loadActivities();
      await activityProvider.loadRecentRecords(userId);
      await activityProvider.loadCheckinStreak(userId);
      
      // 初始化成就数据
      achievementProvider.setUserProvider(userProvider);
      await achievementProvider.initialize();
      
      print('MainScreen: 数据加载完成');
    } else {
      print('MainScreen: 没有当前用户，跳过数据加载');
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
    debugPrint('=== _showCheckInDialog 开始执行 ===');
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
      debugPrint('=== 用户未登录，退出打卡流程 ===');
      return;
    }

    debugPrint('=== 开始执行打卡操作，用户ID: ${userProvider.currentUser!.userId} ===');
    final success = await activityProvider.checkInToday(
      userProvider.currentUser!.userId!,
    );
    debugPrint('=== 打卡操作结果: $success ===');

    List<Achievement> newAchievements = [];
    // 如果打卡成功，检查成就（但不立即显示弹窗）
    if (success) {
      newAchievements = await achievementProvider.checkAndUpdateAchievements();
      // 重新加载成就数据
      await achievementProvider.loadUserAchievements();
      await achievementProvider.loadAchievementStats();
    }

    if (mounted) {
      debugPrint('=== Widget已挂载，准备显示对话框 ===');
      if (success) {
        debugPrint('=== 打卡成功，显示成功对话框 ===');
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
                // 庆祝图标和动画效果
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.celebration, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 20),

                // 主标题
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

                // 副标题
                Text(
                  AppLocalizations.of(context).translate('check_in_success'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 连续打卡信息
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

                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 在打卡成功对话框关闭后显示成就弹窗
                      if (newAchievements.isNotEmpty) {
                        // 使用WidgetsBinding.instance.addPostFrameCallback确保在下一帧显示
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
        debugPrint('=== 打卡失败或已打卡，显示提示对话框 ===');
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
                // 提示图标
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

                // 提示文字
                Text(
                  AppLocalizations.of(context).translate('already_checked_in'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 副标题
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

                // 确认按钮
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
