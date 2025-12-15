import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: AppSizes.fontXXl,
    // fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: AppSizes.fontXl,
    // fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: AppSizes.fontLg,
    // fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: AppSizes.fontXll,
    // fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle body = TextStyle(
    fontSize: AppSizes.fontLg,
    // fontWeight: FontWeight.w400,
    color: Colors.white,
  );
  static const TextStyle secondarybody = TextStyle(
    fontSize: AppSizes.fontMd,
    // fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: AppSizes.fontLg,
    // fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static const TextStyle bodySM = TextStyle(
    fontSize: AppSizes.fontMd,
    // fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  // AppTextStyles
  static const TextStyle button = TextStyle(
    fontSize: AppSizes.fontMd,
    // fontWeight: FontWeight.w700,
  );
}

/// Linear gradient  ( #338ACA to #194464 )
// Shader textLinearGradient(Rect bounds) {
//   return const LinearGradient(
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//     colors: [
//       AppColors.textGradStart,
//       AppColors.textGradEndTransparent,
//     ],
//   ).createShader(bounds);
// }
/// Radial gradient (connected)
RadialGradient bleConnectedRadial() {
  return const RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      AppColors.bleGreenInner41, // 41%
      AppColors.bleGreenOuter0, // 0%
    ],
    stops: [0.0, 1.0],
  );
}

/// Radial gradient (disconnected)
RadialGradient bleDisconnectedRadial() {
  return const RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      AppColors.bleRedInner49, // #C72929 @49%
      AppColors.bleRedOuter0, // 0%
    ],
    stops: [0.0, 1.0],
  );
}
