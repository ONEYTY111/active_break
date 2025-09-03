import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_and_tips.dart';
import '../providers/activity_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_localizations.dart';
import '../services/reminder_scheduler_service.dart' as scheduler;
import '../services/notification_service.dart';
import '../utils/notification_test.dart';
import '../utils/reminder_debug_helper.dart';
import '../screens/debug_log_viewer_screen.dart';

class ReminderSettingsDialog extends StatefulWidget {
  final int activityTypeId;

  const ReminderSettingsDialog({super.key, required this.activityTypeId});

  @override
  State<ReminderSettingsDialog> createState() => _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<ReminderSettingsDialog> {
  bool _enabled = false;
  int _intervalValue = 30;
  int _intervalWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  Future<void> _loadExistingSettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      final existing = await activityProvider.getReminderSetting(
        userProvider.currentUser!.userId!,
        widget.activityTypeId,
      );

      if (existing != null && mounted) {
        setState(() {
          _enabled = existing.enabled;
          _intervalValue = existing.intervalValue;
          _intervalWeek = existing.intervalWeek;
          _startTime = TimeOfDay.fromDateTime(existing.startTime);
          _endTime = TimeOfDay.fromDateTime(existing.endTime);
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    final setting = ReminderSetting(
      userId: userProvider.currentUser!.userId!,
      activityTypeId: widget.activityTypeId,
      enabled: _enabled,
      intervalValue: _intervalValue,
      intervalWeek: _intervalWeek,
      startTime: startDateTime,
      endTime: endDateTime,
      createdAt: now,
      updatedAt: now,
    );

    await activityProvider.updateReminderSetting(
      userProvider.currentUser!.userId!,
      widget.activityTypeId,
      setting,
    );

    // Update reminder schedule
    try {
      final schedulerService = scheduler.ReminderSchedulerService();
      await schedulerService.initialize();

      if (_enabled) {
        // Schedule reminder tasks when enabling reminders
        await schedulerService.scheduleReminders(
          userProvider.currentUser!.userId!,
        );
      } else {
        // When disabling reminders, cancel reminders for this user
        await schedulerService.cancelReminders(
          userProvider.currentUser!.userId!,
        );
      }
    } catch (e) {
      debugPrint('Failed to update reminder scheduling: $e');
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('reminder_saved'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Test reminder functionality with enhanced feedback
  /// @author Author
  /// @date Current date and time
  /// @return Future<void>
  Future<void> _testReminder() async {
    try {
      final notificationService = NotificationService();
      final result = await notificationService.showTestReminder();
      
      if (mounted) {
        final success = result['success'] ?? false;
        final message = result['message'] ?? '';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '测试通知发送成功！$message' : '测试通知发送失败：$message'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '查看详情',
              textColor: Colors.white,
              onPressed: () {
                _openDebugLogViewer();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试通知发送异常：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Run diagnostic test for notification issues
  /// @author Author
  /// @date Current date and time
  /// @return Future<void>
  Future<void> _runDiagnostic() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser?.userId == null) return;

    try {
      final notificationTest = NotificationTest();
      await notificationTest.runFullDiagnostic(userProvider.currentUser!.userId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('诊断完成，请查看控制台日志'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Diagnostic test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('诊断失败: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Debug 5-minute reminder specifically
  /// @author Author
  /// @date Current date and time
  /// @return Future<void>
  Future<void> _debug5MinuteReminder() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser?.userId == null) return;

    try {
      debugPrint('开始5分钟提醒专项调试...');
      await ReminderDebugHelper.runFullDiagnostic(userProvider.currentUser!.userId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('5分钟提醒调试完成'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '查看日志',
              onPressed: () {
                _openDebugLogViewer();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('5分钟提醒调试失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('5分钟提醒调试失败: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Open debug log viewer screen
  /// @author Author
  /// @date Current date and time
  /// @return void
  void _openDebugLogViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugLogViewerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate('reminder_settings')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enable reminder switch
            SwitchListTile(
              title: Text(
                AppLocalizations.of(context).translate('enable_reminder'),
              ),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Interval setting
            if (_enabled) ...[
              Text(
                AppLocalizations.of(context).translate('interval_minutes'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _intervalValue.toDouble(),
                min: 1, // Changed to 1 minute for easier debugging
                max: 120,
                divisions: 119, // Updated divisions to accommodate new range (120-1)/1 = 119
                label: '$_intervalValue min',
                onChanged: (value) {
                  setState(() {
                    _intervalValue = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Week interval
              DropdownButtonFormField<int>(
                value: _intervalWeek,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('repeat_every'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text(
                      AppLocalizations.of(context).translate('every_day'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(
                      AppLocalizations.of(context).translate('every_2_days'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text(
                      AppLocalizations.of(context).translate('every_3_days'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 7,
                    child: Text(
                      AppLocalizations.of(context).translate('weekly'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _intervalWeek = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Time range
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context).translate('start_time'),
                      ),
                      subtitle: Text(_startTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) {
                          setState(() {
                            _startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context).translate('end_time'),
                      ),
                      subtitle: Text(_endTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) {
                          setState(() {
                            _endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context).translate('save')),
        ),
      ],
    );
  }
}
