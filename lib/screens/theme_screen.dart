import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/quran_language.dart';
import '../core/theme.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late AppThemeMode _choice = AppThemeController.instance.mode;

  @override
  void initState() {
    super.initState();
    QuranLanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    QuranLanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                AppStrings.t('theme'),
                textAlign: TextAlign.center,
                style: AppText.serif(size: 38, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t('theme_subtitle'),
                textAlign: TextAlign.center,
                style: AppText.sans(
                  size: 16,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 42),
              _ThemeOption(
                label: AppStrings.t('theme_system'),
                selected: _choice == AppThemeMode.system,
                onTap: () => _select(AppThemeMode.system),
              ),
              const SizedBox(height: 18),
              _ThemeOption(
                label: AppStrings.t('theme_light'),
                selected: _choice == AppThemeMode.light,
                onTap: () => _select(AppThemeMode.light),
              ),
              const SizedBox(height: 18),
              _ThemeOption(
                label: AppStrings.t('theme_dark'),
                selected: _choice == AppThemeMode.dark,
                onTap: () => _select(AppThemeMode.dark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(AppThemeMode choice) async {
    setState(() => _choice = choice);
    await AppThemeController.instance.setMode(choice);
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
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
              _ThemeRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeRadio extends StatelessWidget {
  const _ThemeRadio({required this.selected});

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
