// import '/shared/widgets/progear_password_field.dart';
import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/utils/password_utils.dart';

class ProGearPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  final bool autocorrect;
  final bool enableSuggestions;
  final bool showStrength;

  final void Function(String)? onChanged;

  const ProGearPasswordField({
    super.key,
    required this.controller,
    this.label,
    this.hintText = 'password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.showStrength = false,
    this.onChanged,
  });

  @override
  State<ProGearPasswordField> createState() => _ProGearPasswordFieldState();
}

class _ProGearPasswordFieldState extends State<ProGearPasswordField> {
  bool _obscure = true;
  PasswordValidationResult _live = const PasswordValidationResult(
    isValid: false,
    errors: [],
    strength: PasswordStrength.weak,
  );

  void _handleChanged(String v) {
    if (widget.showStrength) {
      setState(() => _live = validatePassword(v));
    }
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final tf = TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: _handleChanged, // <—
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );

    final label = widget.label;

    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: AppTextStyles.heading2),
          const SizedBox(height: AppSizes.sm),
        ],
        tf,
        if (widget.showStrength) ...[
          const SizedBox(height: 8),
          _StrengthBar(result: _live),
        ],
      ],
    );

    return field;
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.result});
  final PasswordValidationResult result;

  @override
  Widget build(BuildContext context) {
    final fill = switch (result.strength) {
      PasswordStrength.weak => 0.25,
      PasswordStrength.fair => 0.5,
      PasswordStrength.good => 0.75,
      PasswordStrength.strong => 1.0,
    };

    final label = strengthLabel(result.strength);

    final color = Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 5,
            backgroundColor: const Color(0x36E0E0E0),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 26),
        Text(label, style: AppTextStyles.secondary),
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('• ${result.errors.first}', style: AppTextStyles.secondary),
        ],
      ],
    );
  }
}
