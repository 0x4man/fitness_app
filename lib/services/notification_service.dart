import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules fun, "chatpata" push notifications — workout nudges,
/// hydration reminders, and evening habit check-ins — in the same
/// playful tone as apps like Zomato. Purely local/scheduled (no
/// backend), so messages fire at fixed times regardless of that day's
/// actual progress.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _workoutMessages = [
    "Aaj workout skip kiya toh kal wale abs bhi skip honge 👀",
    "Your gym shoes are crying somewhere. Please rescue them 🥲",
    "Streak todne ka mann hai kya? Hume toh nahi lagta 🔥",
    "5 minute ka excuse ban gaya poora din? Chalo ab uth jao 💪",
    "Netflix wait kar sakta hai. Muscles nahi. Chalo!",
    "Ek set hi sahi, shuru toh karo 😤",
    "Kal se karunga wali list me ye bhi add ho gaya kya? Abhi kar lo 😅",
    "Body ko notification bhej diya hai — workout due hai aapka.",
    "Thoda paseena aaj, thoda swagger kal 😎",
    "Sofa comfy hai, pata hai. Par 20 minute workout bhi utna hi zaroori hai.",
    "Weights wait kar rahe hain. Bas aap late ho 🏋️",
    "Aaj chhoti si win chahiye? Ek workout kar lo, done.",
  ];

  static const _waterMessages = [
    "Paani peena bhi ek workout hai bro 💧",
    "Aapki kidneys ek chhota sa complaint file kar rahi hain. Paani piyo!",
    "Coffee count ho gaya, ab paani bhi gin lo ☕➡️💧",
    "Glass bhar paani, thodi der ka break — dono zaroori hain.",
    "Dehydration silently attack karta hai. Ek glass abhi pi lo.",
    "Skin glow chahiye? Step 1: paani piyo. Step 2: wahi phir se.",
    "Bottle bhar ke rakho, bas 2 ghoont abhi le lo.",
  ];

  static const _habitCheckInMessages = [
    "Aaj ke habits check kiye? Protein target abhi bhi adhoora lag raha hai 🍗",
    "Din khatam hone wala hai — sleep aur protein log karna na bhoolna!",
    "Chhoti aadatein, bade results. Aaj ka progress daal do 📊",
    "Habits tab khali baitha hai aapka wait kar raha hai.",
    "2 minute nikaalo, aaj ka data update kar do — future wala aap thank you bolega.",
  ];

  static const _motivationMessages = [
    "Discipline hamesha motivation se zyada tikta hai. Aaj bhi lage raho 🔥",
    "Har chhota step count hota hai — chhod mat do.",
    "Consistency > Perfection. Bas continue karte raho.",
    "Aap kal se behtar ho rahe ho, chahe abhi na dikhe.",
    "Progress slow lag sakta hai, lekin ruka hua nahi hai.",
    "Aaj ka best effort hi kal ka result banega 💪",
    "Comfort zone me results nahi milte. Thoda push karo aaj.",
  ];

  static const _caloriesMessages = [
    "Aaj ka calorie/nutrition log update karna na bhoolna 🍽️",
    "Khana track karna bhi utna hi important hai jitna workout — 2 min me daal do.",
    "Goal ke paas ho ya door, pehle pata toh chale — calories log karo.",
    "Ek chhota sa update: aaj kya khaya, wo bhi daal do 📝",
  ];

  static const _sleepReminderMessages = [
    "Neend bhi ek recovery workout hai. Time pe so jao 😴",
    "Kal ka best version chahiye? Aaj jaldi so jao.",
    "Phone side rakho, 7-8 hours ki neend body ko chahiye.",
  ];

  String _randomFrom(List<String> messages) =>
      messages[Random().nextInt(messages.length)];

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Use UTC as the base location — actual local wall-clock time is
    // computed manually in _nextInstanceOfTime() using the device's
    // current UTC offset. This avoids needing a native plugin just to
    // look up the device's IANA timezone name.
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  bool _permissionRequestInProgress = false;

  /// Requests notification permission — required on Android 13+ and iOS.
  /// Call this from a user-initiated action (e.g. a settings toggle),
  /// not silently on app start. Guards against overlapping calls,
  /// since Android throws if a permission request is triggered while
  /// one is already in flight (e.g. rapid double-taps).
  Future<bool> requestPermission() async {
    if (_permissionRequestInProgress) return false;
    _permissionRequestInProgress = true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted =
          await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosPlugin?.requestPermissions(
          alert: true, badge: true, sound: true);

      return (androidGranted ?? true) || (iosGranted ?? true);
    } catch (_) {
      // Another request was already in progress, or the platform
      // rejected it — treat as "not granted" rather than crashing.
      return false;
    } finally {
      _permissionRequestInProgress = false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_reminders',
          'Viora Reminders',
          channelDescription: 'Workout, hydration, and habit reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Converts a desired *local* wall-clock time (e.g. 6:30 PM in the
  /// user's own timezone) into the correct tz.TZDateTime instant,
  /// using the device's current UTC offset — no native timezone
  /// lookup plugin required.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final deviceOffset = DateTime.now().timeZoneOffset;
    final nowUtc = tz.TZDateTime.now(tz.UTC);

    // Build "hour:minute as if it were UTC", then subtract the local
    // offset to get the actual UTC instant that corresponds to that
    // wall-clock time in the device's own timezone.
    var scheduled = tz.TZDateTime(
            tz.UTC, nowUtc.year, nowUtc.month, nowUtc.day, hour, minute)
        .subtract(deviceOffset);

    if (scheduled.isBefore(nowUtc)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules the default set of daily reminders:
  /// - 8:00 AM — morning motivation
  /// - 11:00 AM & 4:00 PM — hydration nudge
  /// - 1:30 PM — calories/nutrition log reminder
  /// - 6:30 PM — workout reminder
  /// - 9:00 PM — evening habit check-in
  /// - 10:30 PM — wind-down / sleep reminder
  Future<void> scheduleDailyReminders() async {
    await init();
    await cancelAll();

    await _scheduleDaily(
      id: 1,
      hour: 8,
      minute: 0,
      title: '☀️ Good Morning',
      body: _randomFrom(_motivationMessages),
    );
    await _scheduleDaily(
      id: 2,
      hour: 11,
      minute: 0,
      title: '💧 Hydration Check',
      body: _randomFrom(_waterMessages),
    );
    await _scheduleDaily(
      id: 3,
      hour: 13,
      minute: 30,
      title: '🍽️ Nutrition Check',
      body: _randomFrom(_caloriesMessages),
    );
    await _scheduleDaily(
      id: 4,
      hour: 16,
      minute: 0,
      title: '💧 Hydration Check',
      body: _randomFrom(_waterMessages),
    );
    await _scheduleDaily(
      id: 5,
      hour: 18,
      minute: 30,
      title: '🏋️ Workout Time',
      body: _randomFrom(_workoutMessages),
    );
    await _scheduleDaily(
      id: 6,
      hour: 21,
      minute: 0,
      title: '✅ Quick Check-In',
      body: _randomFrom(_habitCheckInMessages),
    );
    await _scheduleDaily(
      id: 7,
      hour: 22,
      minute: 30,
      title: '😴 Wind Down',
      body: _randomFrom(_sleepReminderMessages),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Fires immediately — useful for a streak-at-risk nudge triggered
  /// from within the app (e.g. Home Dashboard notices no workout
  /// logged today and it's getting late).
  Future<void> showStreakWarning(int currentStreak) async {
    await init();
    await _plugin.show(
      99,
      '🔥 $currentStreak-day streak at risk!',
      "Aaj abhi tak workout nahi kiya. Ek quick set maar ke streak bacha lo!",
      _details,
    );
  }

  /// Fires an immediate sample notification — used by the "Send Test
  /// Notification" button so the user can preview the vibe right away
  /// instead of waiting for a scheduled time.
  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      98,
      '🏋️ Workout Time',
      _randomFrom(_workoutMessages),
      _details,
    );
  }
}
