import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fall back to UTC if the device timezone name isn't recognized by
      // the IANA database; scheduling will still work, just in UTC.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String company,
    required String position,
    required DateTime followUpDate,
  }) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      followUpDate.year,
      followUpDate.month,
      followUpDate.day,
      9,
    );

    // If 9am on the follow-up date has already passed, don't schedule into
    // the past; flutter_local_notifications would throw.
    final now = tz.TZDateTime.now(tz.local);
    final effectiveDate =
        scheduledDate.isBefore(now) ? now.add(const Duration(seconds: 5)) : scheduledDate;

    final title = position.isNotEmpty
        ? 'Follow up: $company — $position'
        : 'Follow up: $company';

    await _plugin.zonedSchedule(
      id,
      title,
      'It\'s time to follow up on your application.',
      effectiveDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'follow_up_channel',
          'Follow-up Reminders',
          channelDescription: 'Reminders to follow up on job applications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}
