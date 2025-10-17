import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/utils/snackbar_utils.dart';
import 'package:progear_smart_bag/features/auth/data/datasources/auth_service.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';


class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _busy = false;

  final _auth = AuthService();

  Future<void> _send() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _busy = true);
    try {
      await _auth.sendPasswordReset(_emailCtrl.text.trim());
      if (!mounted) return;
      showSuccessSnack(context, 'Reset email sent. Check your inbox.');
      Navigator.of(context).pop(); // اغلاق الشيت بعد الارسال
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSizes.md),
              const Text('Reset password', style: AppTextStyles.heading),
              const SizedBox(height: AppSizes.md),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _send,
                  child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send reset email'),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
