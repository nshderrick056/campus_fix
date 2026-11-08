import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/auth/auth_form_cubit.dart';
import '../../../logic/form_status.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import 'password_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthFormCubit>().signIn(_email.text, _password.text);
    }
  }

  void _forgotPassword() {
    final error = Validators.aluEmail(_email.text);
    if (error != null) {
      showAppSnack(context, 'Enter your ALU email above first, then tap "Forgot password?".', error: true);
      return;
    }
    context.read<AuthFormCubit>().sendPasswordReset(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return BlocListener<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        if (state.status == FormStatus.failure) showAppSnack(context, state.error!, error: true);
        if (state.status == FormStatus.success && state.info != null) showAppSnack(context, state.info!);
      },
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
                const SizedBox(height: 12),
                Text(AppConstants.appName, style: t.labelLarge?.copyWith(color: c.primary)),
                const SizedBox(height: 8),
                Text('Welcome back', style: t.headlineMedium),
                const SizedBox(height: 6),
                Text('Sign in with your ALU account to report campus issues and track their progress.',
                    style: t.bodyLarge?.copyWith(color: c.textMuted)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
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
                  validator: Validators.loginPassword,
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
                ),
                const SizedBox(height: 8),
                BlocBuilder<AuthFormCubit, AuthFormState>(
                  builder: (context, state) =>
                      LoadingButton(label: 'Sign in', loading: state.isSubmitting, onPressed: _submit),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('New to CampusFix?', style: t.bodyMedium?.copyWith(color: c.textMuted)),
                    TextButton(onPressed: () => context.go(Routes.register), child: const Text('Create an account')),
                  ],
                ),
                const SizedBox(height: 32),
                const InfoBanner(
                  icon: Symbols.verified_user_rounded,
                  message: 'Only verified @alustudent.com and @alueducation.com accounts can sign in.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
