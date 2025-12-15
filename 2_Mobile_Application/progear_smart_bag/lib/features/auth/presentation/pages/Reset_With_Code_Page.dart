import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/utils/validators.dart';
import 'package:progear_smart_bag/core/utils/snackbar_utils.dart';
import 'package:progear_smart_bag/features/auth/data/datasources/auth_service.dart';

import 'package:progear_smart_bag/shared/widgets/progear_text_field.dart';
import 'package:progear_smart_bag/shared/widgets/progear_password_field.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/core/theme/progear_background.dart';

class ResetWithCodePage extends StatefulWidget {
  const ResetWithCodePage({super.key, this.prefilledEmail});
  final String? prefilledEmail;

  @override
  State<ResetWithCodePage> createState() => _ResetWithCodePageState();
}

class _ResetWithCodePageState extends State<ResetWithCodePage> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    if ((widget.prefilledEmail ?? '').isNotEmpty) {
      _email.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      await _auth.verifyRecoveryCodeAndUpdatePassword(
        email: _email.text.trim(),
        token: _code.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'Password updated. Please sign in.');
      context.go('/login');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Failed to reset password. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProGearBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSizes.lg),
                children: [
                  const SizedBox(height: AppSizes.xl),
                  const Text(
                    'Reset password (OTP)',
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Enter the email that received the code, paste the code, '
                    'and set a new password.',
                    style: AppTextStyles.bodySM,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          ProGearTextField(
                            controller: _email,
                            label: 'Email',
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.email,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Recovery code
                          ProGearTextField(
                            controller: _code,
                            label: 'Recovery code',
                            hintText: 'Paste the code from your email',
                            validator: (v) {
                              final val = (v ?? '').trim();
                              if (val.isEmpty) return 'Please enter the code.';
                              if (val.length < 4) {
                                return 'Code seems too short.';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // New password
                          ProGearPasswordField(
                            controller: _password,
                            label: 'New password',
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            validator: (v) =>
                                AppValidators.password(v, minLen: 6),
                            showStrength: true,
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Confirm new password
                          ProGearPasswordField(
                            controller: _confirm,
                            label: 'Confirm new password',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _busy ? null : _submit(),
                            validator: (v) {
                              final base = AppValidators.password(v, minLen: 6);
                              if (base != null) return base;
                              if (v != _password.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.xl),

                          ProGearButton.primary(
                            label: _busy ? 'Updating…' : 'Update password',
                            onPressed: _busy ? null : _submit,
                            expanded: true,
                            size: ProGearButtonSize.xl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),


              Positioned(
                top: AppSizes.md,
                left: AppSizes.xs,
                child: IconButton(
                  onPressed: () => context.go('/login'),
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
