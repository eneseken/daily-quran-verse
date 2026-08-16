import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/arabic_visibility.dart';
import '../core/quran_language.dart';
import '../core/theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _choice = QuranLanguageController.instance.code;
  late bool _showArabic = ArabicVisibilityController.instance.showArabic;

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 28,
                          color: AppColors.ink,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          height: 42,
                          width: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.t('language_title'),
                textAlign: TextAlign.center,
                style: AppText.serif(size: 38, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t('language_subtitle'),
                textAlign: TextAlign.center,
                style: AppText.sans(
                  size: 16,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 30),
              _ArabicToggleCard(value: _showArabic, onChanged: _setShowArabic),
              const SizedBox(height: 30),
              for (final entry in supportedQuranLanguages.entries) ...[
                _LanguageOption(
                  label: entry.value,
                  selected: _choice == entry.key,
                  onTap: () => _select(entry.key),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(String code) async {
    setState(() => _choice = code);
    await QuranLanguageController.instance.select(code);
  }

  Future<void> _setShowArabic(bool value) async {
    setState(() => _showArabic = value);
    await ArabicVisibilityController.instance.setShowArabic(value);
  }
}

/// Sits above the language list â€” a plain on/off switch for whether the
/// Arabic script renders on the home feed at all, independent of which
/// language the translation itself shows in below it.
class _ArabicToggleCard extends StatelessWidget {
  const _ArabicToggleCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.t('show_arabic_title'),
                      style: AppText.sans(
                        size: 18,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppStrings.t('show_arabic_subtitle'),
                      style: AppText.sans(
                        size: 13.5,
                        color: AppColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.ink,
                activeTrackColor: AppColors.ink.withValues(alpha: 0.28),
                inactiveThumbColor: AppColors.inkFaint,
                inactiveTrackColor: AppColors.surface,
                trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                  return value ? Colors.transparent : AppColors.inkFaint;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same visual as ThemeScreen's option row, so picking a language feels like
/// the same control the user already used for Theme.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.ink : Colors.transparent;
    return Material(
      color: selected ? AppColors.bg : AppColors.surface,
      borderRadius: BorderRadius.circular(38),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.sans(
                    size: 20,
                    color: AppColors.ink,
                    height: 1.0,
                  ),
                ),
              ),
              _LanguageRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRadio extends StatelessWidget {
  const _LanguageRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.inkFaint,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: selected ? 16 : 0,
          width: selected ? 16 : 0,
          decoration: BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
