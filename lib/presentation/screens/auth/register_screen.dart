import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/auth/auth_form_cubit.dart';
import '../../../logic/form_status.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';
import 'password_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(context.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthFormCubit>().register(_name.text, _email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return BlocListener<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        if (state.status == FormStatus.failure) showAppSnack(context, state.error!, error: true);
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AuthLayout(
          title: 'Get Started',
          subtitle: 'Create your account with your ALU email. We will send a link to verify it.',
          leading: IconButton.filledTonal(
            tooltip: 'Back to sign in',
            icon: const Icon(Symbols.arrow_back_rounded),
            onPressed: () => context.go(Routes.login),
          ),
          children: [
            const FieldLabel('Full name'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(hintText: 'Your full name', prefixIcon: Icon(Symbols.person_rounded)),
              validator: Validators.fullName,
            ),
            const SizedBox(height: 16),
            const FieldLabel('ALU email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'name@alustudent.com', prefixIcon: Icon(Symbols.mail_rounded)),
              validator: Validators.aluEmail,
            ),
            AluOnlyBanner(email: _email),
            const SizedBox(height: 16),
            const FieldLabel('Password'),
            PasswordField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters',
              validator: Validators.newPassword,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _StrengthMeter(password: _password.text),
            const SizedBox(height: 12),
            const FieldLabel('Confirm password'),
            PasswordField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              onChanged: (_) => setState(() {}),
              validator: (v) => Validators.confirmPassword(v, _password.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            BlocBuilder<AuthFormCubit, AuthFormState>(
              builder: (context, state) => Column(children: [
                GradientButton(label: 'Sign up', loading: state.isSubmitting, onPressed: _submit),
                const SizedBox(height: 20),
                SocialSignIn(
                  caption: 'Or sign up with',
                  onGoogle: state.isSubmitting ? null : context.read<AuthFormCubit>().signInWithGoogle,
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: t.bodyMedium?.copyWith(color: c.textMuted)),
                TextButton(onPressed: () => context.go(Routes.login), child: const Text('Sign in')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-segment strength bar (length, number, mixed case/symbol) with the
/// rules spelled out, so it is not colour-only.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final checks = [
      Validators.hasMinLength(password),
      Validators.hasNumber(password),
      password.contains(RegExp(r'[A-Z]')) || password.contains(RegExp(r'[^A-Za-z0-9]')),
    ];
    final score = checks.where((ok) => ok).length;
    final (label, color) = switch (score) {
      0 => ('', c.border),
      1 => ('Weak', c.error),
      2 => ('Okay', c.submitted),
      _ => ('Strong', c.resolved),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: i < score ? color : c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: 10),
        SizedBox(width: 48, child: Text(label, style: t.labelSmall?.copyWith(color: color))),
      ]),
      const SizedBox(height: 6),
      Text('Use 8+ characters with a number. A capital letter or symbol makes it stronger.', style: t.bodySmall),
    ]);
  }
}
