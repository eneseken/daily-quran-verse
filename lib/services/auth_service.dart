import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';
import 'quran_service.dart';
import 'subscription_service.dart';

/// Thin wrapper over Supabase auth plus the one profile write we need.
class AuthService {
  AuthService._();

  static final instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    await _identifyForPurchases(response.user?.id);
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _identifyForPurchases(response.user?.id);
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    QuranService.instance.reset();
    await SubscriptionService.instance.logout();
  }

  /// Aliases the RevenueCat customer to the Supabase user id, so purchases
  /// follow the account across devices and the webhook can map an incoming
  /// event back to a row in `subscriptions`.
  Future<void> _identifyForPurchases(String? userId) async {
    if (userId == null) return;
    await SubscriptionService.instance.login(userId);
  }

  /// Saves the onboarding answers onto the caller's own profile row. The row is
  /// created by a trigger at signup, so an upsert keeps this safe either way.
  Future<void> saveOnboarding(OnboardingData data) async {
    final id = user?.id;
    if (id == null) return;
    await _client.from('profiles').upsert({
      'id': id,
      ...data.toProfileUpdate(),
    });
  }

  Future<bool> hasCompletedOnboarding() async {
    final id = user?.id;
    if (id == null) return false;
    final row = await _client
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', id)
        .maybeSingle();
    return row?['onboarding_completed'] == true;
  }

  /// The subset of `profiles` the account screen displays â€” both columns
  /// were already collected during onboarding.
  Future<({String? name, String? sex})> fetchProfileSummary() async {
    final id = user?.id;
    if (id == null) return (name: null, sex: null);
    final row = await _client
        .from('profiles')
        .select('name, sex')
        .eq('id', id)
        .maybeSingle();
    return (name: row?['name'] as String?, sex: row?['sex'] as String?);
  }

  /// Updates one or more columns on the caller's own profile row â€” used by
  /// the account screen's Name/Gender edit screens. Upsert for the same
  /// reason as [saveOnboarding]: safe even if the row somehow doesn't exist
  /// yet.
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final id = user?.id;
    if (id == null) return;
    await _client.from('profiles').upsert({'id': id, ...fields});
  }
}
