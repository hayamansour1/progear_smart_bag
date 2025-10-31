import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/utils/validators.dart';
import 'package:progear_smart_bag/core/utils/snackbar_utils.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/shared/widgets/progear_text_field.dart';
import 'package:progear_smart_bag/features/auth/data/datasources/auth_service.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  final _auth = AuthService();

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final email = _email.text.trim();

      await _auth.sendPasswordReset(email);
      if (!mounted) return;

      final router = GoRouter.of(context);

      Navigator.of(context).pop();

      Future.microtask(() {
        router.push('/reset-with-code?email=${Uri.encodeComponent(email)}');
      });

      showSuccessSnack(
        router.routerDelegate.navigatorKey.currentContext ?? context,
        'We emailed you a recovery code.',
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.lg,
          right: AppSizes.lg,
          top: AppSizes.lg,
          bottom: AppSizes.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset password', style: AppTextStyles.heading2),
              const SizedBox(height: AppSizes.md),
              ProGearTextField(
                controller: _email,
                label: 'Email',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _busy ? null : _send(),
              ),
              const SizedBox(height: AppSizes.lg),
              ProGearButton.primary(
                label: _busy ? 'Sending…' : 'Send reset email',
                onPressed: _busy ? null : _send,
                expanded: true,
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}
