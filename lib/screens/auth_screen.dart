import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../models/onboarding_data.dart';
import '../services/auth_service.dart';
import '../services/quran_service.dart';
import '../widgets/common.dart';
import '../widgets/reveal.dart';

/// Sign in / sign up, styled to match the onboarding. When [onboarding] is
/// supplied the answers are written to the profile right after the account is
/// created.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onboarding,
    this.onAuthenticated,
    this.onContinueWithoutAccount,
  });

  final OnboardingData? onboarding;
  final VoidCallback? onAuthenticated;

  /// Offered once signing in has failed for a reason that isn't the
  /// reader's credentials — an unreachable backend shouldn't lock them out
  /// of a Quran that ships inside the app.
  final VoidCallback? onContinueWithoutAccount;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _isRegister = true;
  bool _busy = false;
  String? _error;

  /// Whether the last failure looked like the backend being unreachable
  /// rather than a bad email or password — the case where carrying on
  /// without an account is the reasonable way out.
  bool _authUnreachable = false;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.onboarding != null;
    _name.text = widget.onboarding?.name.trim() ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_isRegister && _name.text.trim().isEmpty) {
      return 'Please enter your name.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _authUnreachable = false;
    });

    try {
      if (_isRegister) {
        await AuthService.instance.signUp(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
        );
        final answers = widget.onboarding;
        if (answers != null && AuthService.instance.user != null) {
          answers.name = _name.text.trim();
          await AuthService.instance.saveOnboarding(answers);
        }
        if (AuthService.instance.user != null) {
          // Seed a sensible starting language for the verse feed from the
          // device locale; the settings sheet lets them change it later.
          await QuranService.instance
              .setPreferredLanguage(detectDeviceLanguageCode());
        }
      } else {
        await AuthService.instance.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      widget.onAuthenticated?.call();
    } on AuthException catch (e) {
      // Supabase reports a paused project or a failed request as an
      // AuthException too, so a 5xx or a transport failure is treated as
      // unreachable while a rejected email/password is not.
      final unreachable = e.statusCode == null ||
          (int.tryParse(e.statusCode!) ?? 0) >= 500;
      if (mounted) {
        setState(() {
          _error = e.message;
          _authUnreachable = unreachable;
        });
      }
    } catch (e) {
      // Anything that isn't an auth rejection — no connection, DNS, TLS,
      // a timeout — means the account system simply can't be reached.
      if (mounted) {
        setState(() {
          _error = "Couldn't reach the server. Check your connection.";
          _authUnreachable = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          cursorColor: AppColors.ink,
          style: AppText.sans(size: 16, color: AppColors.ink),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: AppText.sans(size: 16, color: AppColors.inkFaint),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: RevealColumn(
                    step: const Duration(milliseconds: 260),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40, bottom: 8),
                        child: Text(
                          _isRegister ? 'Save your journey' : 'Welcome back',
                          style: AppText.serif(size: 28),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Text(
                          _isRegister
                              ? 'Create an account so your plan and streak stay '
                                  'with you.'
                              : 'Sign in to pick up where you left off.',
                          style: AppText.sans(size: 15),
                        ),
                      ),
                      if (_isRegister)
                        _field(
                          controller: _name,
                          hint: 'Your name',
                          capitalization: TextCapitalization.words,
                        ),
                      _field(
                        controller: _email,
                        hint: 'Email',
                        keyboard: TextInputType.emailAddress,
                      ),
                      _field(
                        controller: _password,
                        hint: 'Password',
                        obscure: true,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 8),
                          child: Text(
                            _error!,
                            style: AppText.sans(
                              size: 13.5,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: _isRegister ? 'Create account' : 'Sign in',
                busy: _busy,
                onPressed: _submit,
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _isRegister = !_isRegister;
                          _error = null;
                        }),
                child: Text(
                  _isRegister
                      ? 'Already have an account?  Sign in'
                      : "New here?  Create an account",
                  style: AppText.sans(size: 14, color: AppColors.inkSoft),
                ),
              ),
              // Only after the account system itself turned out to be
              // unreachable — the whole Quran is bundled with the app, so
              // there is no reason to hold someone at this screen over it.
              if (_authUnreachable && widget.onContinueWithoutAccount != null)
                TextButton(
                  onPressed: _busy ? null : widget.onContinueWithoutAccount,
                  child: Text(
                    'Continue without an account',
                    style: AppText.sans(size: 14, color: AppColors.gold),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
