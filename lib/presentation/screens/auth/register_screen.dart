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
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to sign in',
            icon: const Icon(Symbols.arrow_back_rounded),
            onPressed: () => context.go(Routes.login),
          ),
          title: const Text('Create account'),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            children: [
              Text('Use your ALU email. We will send a link to confirm it is really you.',
                  style: t.bodyLarge?.copyWith(color: c.textMuted)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Symbols.person_rounded)),
                validator: Validators.fullName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'ALU email',
                  hintText: 'name@alustudent.com',
                  prefixIcon: Icon(Symbols.mail_rounded),
                ),
                validator: Validators.aluEmail,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: 'Password',
                validator: Validators.newPassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _Rule(ok: Validators.hasMinLength(_password.text), text: 'At least 8 characters'),
              _Rule(ok: Validators.hasNumber(_password.text), text: 'Contains a number'),
              _Rule(
                ok: _confirm.text.isNotEmpty && _confirm.text == _password.text,
                text: 'Passwords match',
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.confirmPassword(v, _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              const InfoBanner(
                icon: Symbols.badge_rounded,
                message: 'Every new account starts as a Student. Staff access is granted by the Facilities Office.',
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthFormCubit, AuthFormState>(
                builder: (context, state) =>
                    LoadingButton(label: 'Create account', loading: state.isSubmitting, onPressed: _submit),
              ),
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
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = ok ? c.resolved : c.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(ok ? Symbols.check_circle_rounded : Symbols.radio_button_unchecked_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}
