import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _dailyReminder = true;
  bool _workoutReminder = true;
  bool _achievementNotification = true;
  bool _communityNotification = true;
  bool _weeklyReport = true;
  
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dailyReminder = prefs.getBool('daily_reminder') ?? true;
        _workoutReminder = prefs.getBool('workout_reminder') ?? true;
        _achievementNotification = prefs.getBool('achievement_notification') ?? true;
        _communityNotification = prefs.getBool('community_notification') ?? true;
        _weeklyReport = prefs.getBool('weekly_report') ?? true;
        
        final dailyHour = prefs.getInt('daily_reminder_hour') ?? 9;
        final dailyMinute = prefs.getInt('daily_reminder_minute') ?? 0;
        _dailyReminderTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);
        
        final workoutHour = prefs.getInt('workout_reminder_hour') ?? 18;
        final workoutMinute = prefs.getInt('workout_reminder_minute') ?? 0;
        _workoutReminderTime = TimeOfDay(hour: workoutHour, minute: workoutMinute);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('workout_reminder', _workoutReminder);
    await prefs.setBool('achievement_notification', _achievementNotification);
    await prefs.setBool('community_notification', _communityNotification);
    await prefs.setBool('weekly_report', _weeklyReport);
    
    await prefs.setInt('daily_reminder_hour', _dailyReminderTime.hour);
    await prefs.setInt('daily_reminder_minute', _dailyReminderTime.minute);
    await prefs.setInt('workout_reminder_hour', _workoutReminderTime.hour);
    await prefs.setInt('workout_reminder_minute', _workoutReminderTime.minute);
    
    // 실제 알림 설정 적용
    final notificationService = NotificationService();
    
    // 일일 알림 설정
    if (_dailyReminder) {
      await notificationService.scheduleDailyNotification(
        hour: _dailyReminderTime.hour,
        minute: _dailyReminderTime.minute,
        title: '오늘의 운동 목표를 확인하세요! 💪',
        body: '건강한 하루를 시작해보세요!',
      );
    } else {
      await notificationService.cancelNotification(0);
    }
    
    // 운동 시간 알림 설정
    if (_workoutReminder) {
      await notificationService.scheduleWorkoutReminder(
        hour: _workoutReminderTime.hour,
        minute: _workoutReminderTime.minute,
      );
    } else {
      await notificationService.cancelNotification(1);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 설정이 저장되었습니다'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDaily) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDaily ? _dailyReminderTime : _workoutReminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C853),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Color(0xFFE0E0E0),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isDaily) {
          _dailyReminderTime = picked;
        } else {
          _workoutReminderTime = picked;
        }
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2196F3).withOpacity(0.15),
                            const Color(0xFF2196F3).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF2196F3),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '알림 설정',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '운동 목표 달성을 위해 알림을 받아보세요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 일일 알림
                    _buildSectionTitle('일일 알림', Icons.today_rounded),
                    const SizedBox(height: 16),
                    _buildNotificationCard(
                      title: '매일 알림',
                      description: '매일 설정한 시간에 운동 알림을 받습니다',
                      icon: Icons.alarm_rounded,
                      value: _dailyReminder,
                      onChanged: (value) async {
                        setState(() => _dailyReminder = value);
                        await _saveSettings();
                      },
                      child: _dailyReminder
                          ? _buildTimeSelector(
                              label: '알림 시간',
                              time: _dailyReminderTime,
                              onTap: () => _selectTime(context, true),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildNotificationCard(
                      title: '운동 시간 알림',
                      description: '운동하기 좋은 시간에 알림을 받습니다',
                      icon: Icons.fitness_center_rounded,
                      value: _workoutReminder,
                      onChanged: (value) async {
                        setState(() => _workoutReminder = value);
                        await _saveSettings();
                      },
                      child: _workoutReminder
                          ? _buildTimeSelector(
                              label: '알림 시간',
                              time: _workoutReminderTime,
                              onTap: () => _selectTime(context, false),
                            )
                          : null,
                    ),
                    const SizedBox(height: 32),

                    // 활동 알림
                    _buildSectionTitle('활동 알림', Icons.local_fire_department_rounded),
                    const SizedBox(height: 16),
                    _buildNotificationCard(
                      title: '업적 알림',
                      description: '새로운 업적을 달성했을 때 알림을 받습니다',
                      icon: Icons.emoji_events_rounded,
                      value: _achievementNotification,
                      onChanged: (value) async {
                        setState(() => _achievementNotification = value);
                        await _saveSettings();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNotificationCard(
                      title: '커뮤니티 알림',
                      description: '내 게시글에 댓글이 달렸을 때 알림을 받습니다',
                      icon: Icons.people_rounded,
                      value: _communityNotification,
                      onChanged: (value) async {
                        setState(() => _communityNotification = value);
                        await _saveSettings();
                      },
                    ),
                    const SizedBox(height: 32),

                    // 주간 리포트
                    _buildSectionTitle('주간 리포트', Icons.timeline_rounded),
                    const SizedBox(height: 16),
                    _buildNotificationCard(
                      title: '주간 운동 리포트',
                      description: '매주 월요일 나의 운동 통계를 받아보세요',
                      icon: Icons.analytics_rounded,
                      value: _weeklyReport,
                      onChanged: (value) async {
                        setState(() => _weeklyReport = value);
                        await _saveSettings();
                      },
                    ),
                    const SizedBox(height: 32),

                    // 모든 알림 끄기
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCF6679).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_off_rounded,
                              color: Color(0xFFCF6679),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '모든 알림 끄기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '모든 알림을 비활성화합니다',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () async {
                              setState(() {
                                _dailyReminder = false;
                                _workoutReminder = false;
                                _achievementNotification = false;
                                _communityNotification = false;
                                _weeklyReport = false;
                              });
                              await _saveSettings();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFCF6679),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('끄기'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00C853), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value 
              ? const Color(0xFF00C853).withOpacity(0.3)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFF00C853).withOpacity(0.1)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: value ? const Color(0xFF00C853) : const Color(0xFF616161),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: value ? const Color(0xFFE0E0E0) : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF00C853),
                activeTrackColor: const Color(0xFF00C853).withOpacity(0.5),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFF00C853),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00E676)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


