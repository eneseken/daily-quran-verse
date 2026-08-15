/// Everything collected during onboarding. Held in memory while the user walks
/// the flow, then written to `profiles` once they create an account.
class OnboardingData {
  String name = '';
  String? ageRange;
  String? sex;
  String? screenTime;
  List<String> goals = [];
  String? vision;
  int readingDays = 3;
  String? faithStatus;
  String? prayerStatus;
  List<String> obstacles = [];
  int reminderStartHour = 8;
  int reminderEndHour = 22;

  /// Trimmed first name, falling back to a neutral address so copy never reads
  /// "Alright , consider this...".
  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'friend';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Map<String, dynamic> toProfileUpdate() => {
        'name': name.trim(),
        'age_range': ageRange,
        'sex': sex,
        'screen_time': screenTime,
        'goals': goals,
        'vision': vision,
        'reading_days': readingDays,
        'faith_status': faithStatus,
        'prayer_status': prayerStatus,
        'obstacles': obstacles,
        'reminder_start': '${_two(reminderStartHour)}:00:00',
        'reminder_end': '${_two(reminderEndHour)}:00:00',
        'onboarding_completed': true,
      };
}
