import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'feed_theme.dart';

const supportedLanguages = {'en': 'English', 'tr': 'Türkçe'};

/// Language picker + sign out, opened from the feed's account button.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  static Future<void> show(
    BuildContext context, {
    required String currentLanguage,
    required ValueChanged<String> onLanguageChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsSheet(
        currentLanguage: currentLanguage,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF171715),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FeedColors.chipBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verse language', style: FeedText.label(color: FeedColors.ink)),
            const SizedBox(height: 14),
            for (final entry in supportedLanguages.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LanguageRow(
                  label: entry.value,
                  selected: entry.key == currentLanguage,
                  onTap: () {
                    onLanguageChanged(entry.key);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            const SizedBox(height: 6),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 6),
            _SignOutRow(
              onTap: () {
                Navigator.of(context).pop();
                AuthService.instance.signOut();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FeedColors.chip : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: FeedText.label(color: FeedColors.ink).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: FeedColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: FeedColors.inkSoft),
              const SizedBox(width: 12),
              Text('Sign out', style: FeedText.label(color: FeedColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
