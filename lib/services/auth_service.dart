import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';
import 'quran_service.dart';

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
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    QuranService.instance.reset();
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
}
