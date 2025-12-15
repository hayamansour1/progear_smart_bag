import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';

import 'package:progear_smart_bag/core/theme/progear_background.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/utils/validators.dart';
import 'package:progear_smart_bag/features/auth/presentation/widgets/forgot_password_sheet.dart';

import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/shared/widgets/progear_text_field.dart';
import 'package:progear_smart_bag/shared/widgets/progear_password_field.dart';

import 'package:progear_smart_bag/features/auth/data/datasources/auth_service.dart'
    show AuthService, AuthFailure;
import 'package:progear_smart_bag/core/utils/snackbar_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailPassword(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      context.go('/auth-gate');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProGearBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.lg,
                ),
                children: [
                  const SizedBox(height: AppSizes.xxl),
                  const Text("Let’s sign you in", style: AppTextStyles.heading),
                  const SizedBox(height: AppSizes.sm),
                  Text("We’re glad you’re here.",
                      style: AppTextStyles.secondary),
                  const SizedBox(height: AppSizes.xl),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProGearTextField(
                            controller: _email,
                            label: 'Email',
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            enableSuggestions: false,
                            validator: AppValidators.email,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          ProGearPasswordField(
                            controller: _password,
                            label: 'Password',
                            hintText: 'your password',
                            validator: (v) =>
                                AppValidators.password(v, minLen: 6),
                            onSubmitted: (_) => _login(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) => const ForgotPasswordSheet(),
                        );
                      },
                      child: const Text("Forget password?"),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  ProGearButton.primary(
                    label: _loading ? 'Signing in…' : 'Sign In',
                    onPressed: _loading ? null : _login,
                    size: ProGearButtonSize.xl,
                    expanded: true,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text("Don’t have account? Register"),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: AppSizes.md,
                left: AppSizes.xs,
                child: IconButton(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Positioned(
                top: AppSizes.lg,
                right: AppSizes.md,
                child: Opacity(
                  opacity: .9,
                  child: Image.asset(
                    AppImages.logoBag,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
