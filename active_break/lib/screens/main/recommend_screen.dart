import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tips_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/reminder_and_tips.dart';
import '../../utils/app_localizations.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTips();
    });
  }

  Future<void> _loadTips() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      await tipsProvider.loadTodayTips(userProvider.currentUser!.userId!);
      // Load favorite status for today's tips
      await favoritesProvider.loadFavoriteStatus(
        userProvider.currentUser!.userId!,
        tipsProvider.todayTips,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('recommend')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              AppLocalizations.of(context).translate('daily_tips'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tips content
            Consumer<TipsProvider>(
              builder: (context, tipsProvider, child) {
                if (tipsProvider.isLoading) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (tipsProvider.todayTips.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_tips_today'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Daily health tips will be generated at midnight',
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

                return Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    return Column(
                      children: tipsProvider.todayTips.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tip = entry.value;
                        final colors = [Colors.blue, Colors.green, Colors.purple];
                        final icons = [Icons.lightbulb, Icons.favorite, Icons.star];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < tipsProvider.todayTips.length - 1
                                ? 12
                                : 0,
                          ),
                          child: _buildTipCard(
                            context,
                            'Health Tip ${index + 1}',
                            tip,
                            icons[index % icons.length],
                            colors[index % colors.length],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    String title,
    UserTip tip,
    IconData icon,
    Color color,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite button
            if (tip.tipId != null)
              IconButton(
                onPressed: () {
                  if (userProvider.currentUser?.userId != null) {
                    favoritesProvider.toggleFavorite(
                      userProvider.currentUser!.userId!,
                      tip,
                    );
                  }
                },
                tooltip: favoritesProvider.isFavorite(tip.tipId!) 
                    ? AppLocalizations.of(context).translate('remove_from_favorites')
                    : AppLocalizations.of(context).translate('add_to_favorites'),
                icon: Icon(
                  favoritesProvider.isFavorite(tip.tipId!)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: favoritesProvider.isFavorite(tip.tipId!)
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
