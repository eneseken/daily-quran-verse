import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../services/app_icon_service.dart';

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  static const _icons = ['1', '2', '3', '4', '5', '6'];

  String _selected = '1';
  String? _pending;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final icon = await AppIconService.currentIcon();
    if (!mounted) return;
    setState(() => _selected = icon);
  }

  Future<void> _select(String id) async {
    if (_pending != null) return;
    setState(() => _pending = id);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    try {
      await AppIconService.setIcon(id);
      if (!mounted) return;
      setState(() => _selected = id);
    } on PlatformException {
      // Simulator/unsupported launchers can reject dynamic icon changes.
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  'Which icon style do\nyou like?',
                  textAlign: TextAlign.center,
                  style: AppText.serif(
                    size: 39,
                    color: AppColors.ink,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Choose how the app appears on your\nhome screen',
                  textAlign: TextAlign.center,
                  style: AppText.sans(
                    size: 22,
                    color: AppColors.inkSoft,
                    height: 1.32,
                  ),
                ),
              ),
              const SizedBox(height: 54),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 42,
                  childAspectRatio: 0.93,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final id = _icons[index];
                  return _IconOption(
                    id: id,
                    selected: _selected == id,
                    onTap: () => _select(id),
                  );
                },
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
          height: 34,
          width: 34,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 27,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 74,
            height: 74,
            padding: EdgeInsets.all(selected ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: selected
                  ? Border.all(color: AppColors.inkSoft, width: 2)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/app-custom-logos/$id.png',
                fit: BoxFit.cover,
                cacheWidth: 160,
              ),
            ),
          ),
          Positioned(
            top: -9,
            right: 2,
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'FREE',
                style: AppText.sans(
                  size: 10,
                  color: AppColors.ctaOnBg,
                  weight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
