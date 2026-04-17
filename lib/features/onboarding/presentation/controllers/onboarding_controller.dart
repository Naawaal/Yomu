import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_controller.g.dart';

const String _onboardingCompletedKey = 'onboarding_completed';

/// Stores and exposes onboarding completion state.
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  Future<bool> build() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Marks onboarding as completed for future launches.
  Future<void> complete() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
    state = const AsyncData<bool>(true);
  }

  /// Resets onboarding visibility, intended for future logout flows.
  Future<void> reset() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, false);
    state = const AsyncData<bool>(false);
  }
}