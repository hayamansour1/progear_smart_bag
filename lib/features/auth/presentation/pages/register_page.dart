import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';

import 'package:progear_smart_bag/core/theme/progear_background.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
// import 'package:progear_smart_bag/core/utils/password_utils.dart';
import 'package:progear_smart_bag/core/utils/validators.dart';

import 'package:progear_smart_bag/shared/widgets/progear_text_field.dart';
import 'package:progear_smart_bag/shared/widgets/progear_password_field.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

import 'package:progear_smart_bag/features/auth/data/datasources/auth_service.dart'
    show AuthService, AuthFailure;
import 'package:progear_smart_bag/core/utils/snackbar_utils.dart'; // showErrorSnack

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmailPassword(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
      );

      if (!mounted) return;

      showErrorSnack(
        context,
        'Account created! Please check your email to verify.',
      );

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
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
                  const Text("Create your account",
                      style: AppTextStyles.heading3),
                  const SizedBox(height: AppSizes.xs),
                  Text("Join ProGear to get started.",
                      style: AppTextStyles.secondary),
                  const SizedBox(height: AppSizes.md),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NAME
                          ProGearTextField(
                            controller: _name,
                            label: 'Name',
                            hintText: 'Name',
                            keyboardType: TextInputType.name,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.length < 2) return 'Name is too short';
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSizes.md),

                          // EMAIL
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

                          const SizedBox(height: AppSizes.md),

                          // PASSWORD
                          ProGearPasswordField(
                            controller: _password,
                            label: 'Password',
                            hintText: 'your password',
                            showStrength: false,
                            validator: (v) =>
                                AppValidators.password(v, minLen: 6),
                          ),

                          const SizedBox(height: AppSizes.md),

                          // CONFIRM PASSWORD
                          ProGearPasswordField(
                            controller: _confirm,
                            label: 'Confirm Password',
                            hintText: 're-enter password',
                            validator: (v) => AppValidators.confirmPassword(
                                v, _password.text),
                            onSubmitted: (_) => _signUp(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  ProGearButton.primary(
                    label: _loading ? 'Creating account…' : 'Sign Up',
                    onPressed: _loading ? null : _signUp,
                    size: ProGearButtonSize.xl,
                    expanded: true,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text("Already have an account? Log in"),
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
