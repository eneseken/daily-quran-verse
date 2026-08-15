import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'models/onboarding_data.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/auth_service.dart';
import 'widgets/breathing_loader.dart';

const _onboardingSeenKey = 'onboarding_seen';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint the very first frame with the right palette already applied, so
  // there's no light-then-dark flash on launch.
  final startDark = computeSystemIsDark();
  AppColors.apply(startDark);
  syncStatusBarStyle(startDark);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MuslimApp());
}

class MuslimApp extends StatelessWidget {
  const MuslimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Quran Verse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootGate(),
    );
  }
}

/// Decides what the user sees: onboarding, auth, or home. Also the single
/// place watching for brightness changes — system dark mode or the evening
/// window — and re-applying [AppColors] for the whole tree.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _onboardingSeen = false;

  /// Answers waiting to be attached to a brand new account.
  OnboardingData? _pendingAnswers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-checks system brightness / time of day, and if it flipped, applies
  /// the new palette and rebuilds the whole tree.
  void _syncBrightness() {
    final dark = computeSystemIsDark();
    if (dark == AppColors.isDark) return;
    AppColors.apply(dark);
    syncStatusBarStyle(dark);
    if (mounted) setState(() {});
  }

  @override
  void didChangePlatformBrightness() => _syncBrightness();

  /// Covers "opened the app in the evening" even when the OS setting itself
  /// hasn't changed — re-checked every time the app comes back to the
  /// foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncBrightness();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingSeen = prefs.getBool(_onboardingSeenKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _finishOnboarding(OnboardingData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    if (!mounted) return;
    setState(() {
      _onboardingSeen = true;
      _pendingAnswers = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _Splash();

    return StreamBuilder<AuthState>(
      stream: AuthService.instance.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ?? AuthService.instance.session;

        if (session != null) return HomeScreen();

        if (!_onboardingSeen) {
          return OnboardingFlow(onComplete: _finishOnboarding);
        }

        return AuthScreen(onboarding: _pendingAnswers);
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: BreathingLoader(glow: AppColors.gold),
      ),
    );
  }
}
