import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../widgets/common.dart';

/// Unverified users wait here. The router moves them on once
/// [AuthCubit] reports the email as verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldown = 45;
  int _secondsLeft = _cooldown;
  bool _checking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final verified = await context.read<AuthCubit>().checkVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified) {
      showAppSnack(context, 'Not verified yet. Open the link in your email, then try again.', error: true);
    }
  }

  Future<void> _resend() async {
    await context.read<AuthCubit>().resendVerification();
    if (!mounted) return;
    showAppSnack(context, 'Verification email sent.');
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final email = context.select((AuthCubit a) => a.state.user?.email) ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 74,
                backgroundColor: c.iceSoft,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: c.ice,
                  child: Icon(Symbols.mark_email_unread_rounded, size: 52, color: c.primary),
                ),
              ),
              const SizedBox(height: 28),
              Text('Check your inbox', style: t.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('We sent a verification link to', style: t.bodyLarge?.copyWith(color: c.textMuted)),
              const SizedBox(height: 4),
              Text(email, style: t.labelLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Open the link, then come back and tap continue. You cannot submit reports until your email is verified.',
                style: t.bodyMedium?.copyWith(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                icon: Symbols.badge_rounded,
                message: 'Every new account starts as a Student. Staff access is granted by the Facilities Office.',
              ),
              const Spacer(),
              LoadingButton(label: 'I have verified my email', loading: _checking, onPressed: _check),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _secondsLeft > 0 ? null : _resend,
                  icon: const Icon(Symbols.refresh_rounded),
                  label: const Text('Resend email'),
                ),
              ),
              const SizedBox(height: 8),
              if (_secondsLeft > 0)
                Text('You can resend in 0:${_secondsLeft.toString().padLeft(2, '0')}', style: t.bodySmall),
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: const Text('Use a different email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
