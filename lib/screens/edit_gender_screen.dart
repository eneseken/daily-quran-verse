import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

/// Lets the user change the gender collected during onboarding. Picking an
/// option auto-saves and pops shortly after, matching the onboarding
/// single-choice screens' feel rather than needing a separate Save tap.
class EditGenderScreen extends StatefulWidget {
  const EditGenderScreen({super.key, required this.name, required this.initial});

  /// First name, for the "{name}, which describes you best?" heading — falls
  /// back to a neutral address when it's empty, same as onboarding's
  /// OnboardingData.displayName.
  final String name;
  final String? initial;

  static const choices = ['Female', 'Male', 'Prefer not to say'];

  @override
  State<EditGenderScreen> createState() => _EditGenderScreenState();
}

class _EditGenderScreenState extends State<EditGenderScreen> {
  String? _selected;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(String value) {
    setState(() => _selected = value);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 280), _save);
  }

  Future<void> _save() async {
    final value = _selected;
    if (value == null) return;
    await AuthService.instance.updateProfile({'sex': value});
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    final displayName = widget.name.trim().isEmpty
        ? 'You'
        : widget.name.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),
              Text(
                '$displayName, which describes you best?',
                style: AppText.serif(size: 28, color: AppColors.ink, height: 1.15),
              ),
              const SizedBox(height: 26),
              for (final choice in EditGenderScreen.choices)
                OptionTile(
                  label: choice,
                  selected: _selected == choice,
                  onTap: () => _pick(choice),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
