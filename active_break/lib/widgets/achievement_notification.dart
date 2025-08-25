import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../utils/app_localizations.dart';

class AchievementNotification {
  static void show(BuildContext context, List<Achievement> newAchievements) {
    if (newAchievements.isEmpty) return;
    
    for (final achievement in newAchievements) {
      _showSingleAchievement(context, achievement);
    }
  }
  
  static void _showSingleAchievement(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon and animation effect
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 20),
            
            // Main title
            Text(
              AppLocalizations.of(context).translate('achievement_unlocked'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Achievement name
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Achievement description
            Text(
              achievement.description,
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
                  backgroundColor: Colors.amber,
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