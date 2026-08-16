import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

/// Lets the user change the name collected during onboarding. Pops with the
/// new value on save, so the profile screen can update its row without
/// another round trip to Supabase.
class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key, required this.initial});

  final String initial;

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _ready {
    final trimmed = _controller.text.trim();
    return trimmed.isNotEmpty && trimmed != widget.initial.trim();
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    final name = _controller.text.trim();
    setState(() => _saving = true);
    await AuthService.instance.updateProfile({'name': name});
    if (!mounted) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "What's your name?",
                          style: AppText.serif(size: 32, color: AppColors.ink),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _save(),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            cursorColor: AppColors.ink,
                            style: AppText.sans(size: 16, color: AppColors.ink),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your name',
                              hintStyle: AppText.sans(
                                size: 16,
                                color: AppColors.inkFaint,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Save',
                busy: _saving,
                onPressed: _ready ? _save : null,
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
