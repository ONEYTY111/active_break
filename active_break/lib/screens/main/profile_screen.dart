import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/edit_profile_dialog.dart';
import '../../widgets/change_password_dialog.dart';
import '../../services/database_service.dart';
import '../../models/physical_activity.dart';
import '../achievements/achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info card
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: user?.avatarUrl != null
                              ? (user!.avatarUrl!.startsWith('http')
                                    ? NetworkImage(user.avatarUrl!)
                                    : (File(user.avatarUrl!).existsSync()
                                              ? FileImage(File(user.avatarUrl!))
                                              : null)
                                          as ImageProvider?)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.username
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? 'User',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (user?.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.phone!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                              if (user?.gender != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.gender == 'male'
                                      ? AppLocalizations.of(
                                          context,
                                        ).translate('male')
                                      : AppLocalizations.of(
                                          context,
                                        ).translate('female'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                              if (user?.birthday != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${user!.birthday!.year}-${user.birthday!.month.toString().padLeft(2, '0')}-${user.birthday!.day.toString().padLeft(2, '0')}',
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
                        ),
                        IconButton(
                          onPressed: () => _showEditProfileDialog(context),
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Settings section
            Text(
              AppLocalizations.of(context).translate('settings'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Theme setting
            Card(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('theme'),
                    ),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system
                          ? AppLocalizations.of(
                              context,
                            ).translate('system_mode')
                          : themeProvider.isDarkMode
                          ? AppLocalizations.of(context).translate('dark_mode')
                          : AppLocalizations.of(
                              context,
                            ).translate('light_mode'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showThemeDialog(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Language setting
            Card(
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      AppLocalizations.of(context).translate('language'),
                    ),
                    subtitle: Text(
                      languageProvider.isChinese
                          ? AppLocalizations.of(context).translate('chinese')
                          : AppLocalizations.of(context).translate('english'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showLanguageDialog(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // My Favorites
            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(
                  AppLocalizations.of(context).translate('my_favorites'),
                ),
                subtitle: Text(
                  AppLocalizations.of(context).translate('view_favorite_tips'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
            ),
            const SizedBox(height: 8),

            // My Achievements
            Card(
              child: Consumer<AchievementProvider>(
                builder: (context, achievementProvider, child) {
                  return ListTile(
                    leading: const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('my_achievements'),
                    ),
                    subtitle: Text(
                      '${achievementProvider.achievedAchievements.length}/${achievementProvider.allAchievements.length} ${AppLocalizations.of(context).translate('completed')}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Change password
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: Text(
                  AppLocalizations.of(context).translate('change_password'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ),

            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: Text(AppLocalizations.of(context).translate('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('theme')),
        content: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(
                    AppLocalizations.of(context).translate('light_mode'),
                  ),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(
                    AppLocalizations.of(context).translate('dark_mode'),
                  ),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(
                    AppLocalizations.of(context).translate('system_mode'),
                  ),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('language')),
        content: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(
                    AppLocalizations.of(context).translate('chinese'),
                  ),
                  value: 'zh',
                  groupValue: languageProvider.locale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.setLanguage(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                RadioListTile<String>(
                  title: Text(
                    AppLocalizations.of(context).translate('english'),
                  ),
                  value: 'en',
                  groupValue: languageProvider.locale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.setLanguage(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('logout')),
        content: Text(AppLocalizations.of(context).translate('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text(AppLocalizations.of(context).translate('confirm')),
          ),
        ],
      ),
    );
  }
}
