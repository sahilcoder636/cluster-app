import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for local push notifications.
/// Handles permission requests, daily reminder scheduling, and cancellation.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification channel constants ─────────────────────────────────────────
  static const String _channelId = 'cluster_daily';
  static const String _channelName = 'Daily Puzzle Reminder';
  static const int _notificationId = 0;

  // ── Android notification details ───────────────────────────────────────────
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  /// Initialises the plugin and timezone database.
  /// Must be called once in [main] before [runApp].
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    tz.initializeTimeZones();

    _initialized = true;
  }

  /// Shows a friendly explanation dialog, then — if the user agrees — requests
  /// the system notification permission.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermission(BuildContext context) async {
    // Show our own rationale dialog first.
    final userAgreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Stay in your streak 🔥'),
        content: const Text(
          "Get a daily reminder when today's Cluster is ready.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Maybe later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sure!'),
          ),
        ],
      ),
    );

    if (userAgreed != true) return false;

    // Ask the OS for permission.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Cancels any existing daily notification and schedules a new one at 08:00
  /// every day. If 08:00 has already passed today, the first fire will be
  /// tomorrow.
  Future<void> scheduleDailyReminder() async {
    // Cancel existing reminder with same id.
    await _plugin.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // 08:00 AM
    );

    // If 8 AM has already passed, roll forward to tomorrow.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId,
      'Cluster 🔥',
      "Today's puzzle is ready. Can you keep your streak alive?",
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
