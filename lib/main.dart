import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'models/onboarding_data.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/paywall_screen.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'widgets/breathing_loader.dart';

const _onboardingSeenKey = 'onboarding_seen';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint the very first frame with the saved palette already applied, so
  // there's no light-then-dark flash on launch.
  await AppThemeController.instance.restore();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Deliberately not awaited: entitlement is only needed once the feed is on
  // screen, and a slow network shouldn't hold up the first frame.
  unawaited(SubscriptionService.instance.init());

  runApp(const MuslimApp());
}

class MuslimApp extends StatefulWidget {
  const MuslimApp({super.key});

  @override
  State<MuslimApp> createState() => _MuslimAppState();
}

class _MuslimAppState extends State<MuslimApp> {
  final AppThemeController _themeController = AppThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Quran Verse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => AppThemeScope(
        controller: _themeController,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RootGate(),
    );
  }
}

/// Decides what the user sees: onboarding, auth, or home. Also the single
/// place watching for brightness changes ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â system dark mode or the evening
/// window ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â and re-applying [AppColors] for the whole tree.
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

  /// Re-checks system brightness / time of day when Theme is set to System.
  void _syncBrightness() {
    AppThemeController.instance.syncSystem();
  }

  @override
  void didChangePlatformBrightness() => _syncBrightness();

  /// Covers "opened the app in the evening" even when the OS setting itself
  /// hasn't changed ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â re-checked every time the app comes back to the
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
        final session = snapshot.data?.session ?? AuthService.instance.session;

        if (session != null) return const _SignedIn();

        if (!_onboardingSeen) {
          return OnboardingFlow(onComplete: _finishOnboarding);
        }

        return AuthScreen(onboarding: _pendingAnswers);
      },
    );
  }
}

/// The home feed, with the paywall presented once per app open for users who
/// don't hold the entitlement.
///
/// The feed builds first and stays mounted underneath, so dismissing the
/// paywall lands the user straight in the app rather than on a loading state.
class _SignedIn extends StatefulWidget {
  const _SignedIn();

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  /// Guards against showing the paywall twice ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â on a rebuild, or when
  /// RevenueCat's entitlement callback lands after the first frame.
  bool _offerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  Future<void> _maybeOffer() async {
    if (_offerShown || !mounted) return;

    final subscriptions = SubscriptionService.instance;

    // Give RevenueCat a moment to report entitlement on a cold start; showing
    // a paywall to someone who already pays is the one unacceptable outcome.
    if (!subscriptions.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    if (!mounted || subscriptions.isPremium || !subscriptions.isConfigured) {
      return;
    }

    _offerShown = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: BreathingLoader(glow: AppColors.gold)),
    );
  }
}
