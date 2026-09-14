import 'package:flutter_test/flutter_test.dart';
import 'package:ours/models/cycle_tracker.dart';
import 'package:ours/models/user_profile.dart';

void main() {
  test('profile completion requires both a name and a valid role', () {
    expect(UserProfile.isProfileComplete(null), isFalse);
    expect(UserProfile.isProfileComplete({'displayName': 'Аня'}), isFalse);
    expect(
      UserProfile.isProfileComplete({'displayName': 'Аня', 'role': 'girl'}),
      isTrue,
    );
  });

  test('manual cycle status takes precedence over calendar calculation', () {
    final cycle = CycleTracker(
      lastPeriodStart: DateTime(2026, 9, 1),
      statusOverride: 'calm',
    );
    expect(cycle.statusKey(DateTime(2026, 9, 2)), 'calm');
  });
}
