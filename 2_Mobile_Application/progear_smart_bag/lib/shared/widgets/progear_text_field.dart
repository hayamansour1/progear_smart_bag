// lib/shared/widgets/progear_text_field.dart
import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';

class ProGearTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool obscureText;

  const ProGearTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      enabled: enabled,
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppTextStyles.heading2),
        const SizedBox(height: AppSizes.sm),
        field,
      ],
    );
  }
}
