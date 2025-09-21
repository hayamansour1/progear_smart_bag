import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';

enum ProGearButtonVariant { primary, outline }

enum ProGearButtonSize { sm, md, lg, xl }

class ProGearButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ProGearButtonVariant variant;
  final ProGearButtonSize size;
  final bool expanded;
  final Widget? leading;
  final Widget? trailing;

  const ProGearButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = ProGearButtonSize.md,
    this.expanded = false,
    this.leading,
    this.trailing,
  }) : variant = ProGearButtonVariant.primary;

  const ProGearButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = ProGearButtonSize.md,
    this.expanded = false,
    this.leading,
    this.trailing,
  }) : variant = ProGearButtonVariant.outline;

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case ProGearButtonSize.sm:
        return const EdgeInsets.symmetric(vertical: 10, horizontal: 18);
      case ProGearButtonSize.md:
        return const EdgeInsets.symmetric(vertical: 14, horizontal: 22);
      case ProGearButtonSize.lg:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 28);
      case ProGearButtonSize.xl:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 32);
    }
  }

  double get _height {
    switch (size) {
      case ProGearButtonSize.sm:
        return 44;
      case ProGearButtonSize.md:
        return 52;
      case ProGearButtonSize.lg:
        return 56;
      case ProGearButtonSize.xl:
        return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child =
        _ProGearButtonChild(label: label, leading: leading, trailing: trailing);

    final btn = switch (variant) {
      ProGearButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: _padding,
            shape: const StadiumBorder(),
            minimumSize:
                Size(0, _height),
          ),
          child: child,
        ),
      ProGearButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: _padding,
            shape: const StadiumBorder(),
            minimumSize: Size(0, _height),
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class _ProGearButtonChild extends StatelessWidget {
  final String label;
  final Widget? leading, trailing;
  const _ProGearButtonChild({required this.label, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: AppSizes.sm)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          const SizedBox(width: AppSizes.sm),
          trailing!
        ],
      ],
    );
  }
}



// ===============================================



// 1)
// ProGearButton.primary(
//   label: 'Sign In',
//   onPressed: _login,
//   size: ProGearButtonSize.xl,
//   expanded: true,
// ),

// 2)
// ProGearButton.outlined(
//   label: 'Sign in',
//   onPressed: () => context.go('/login'),
//   size: ProGearButtonSize.sm,
// ),

// 3)
// ProGearButton.primary(
//   label: 'Register',
//   onPressed: () => context.go('/register'),
//   size: ProGearButtonSize.lg,
// ),

// 4)
// ProGearButton.outlined(
//   label: 'Reset Weight',
//   onPressed: _onResetWeight,
//   size: ProGearButtonSize.xl,
//   expanded: true,
// ),