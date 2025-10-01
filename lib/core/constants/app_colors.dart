import 'package:flutter/material.dart';

// RBG Colors
// Red 12
// Blue 12
// green 12
// hex color 16 digits (0-9, A-F)

class AppColors {
  // Background
  static const Color background = Color(0xFF121212); // #121212

  // background light
  static const Color backgroundLight = Color(0xFF1E1E1E);

  // Primary button
  static const Color primaryBlue = Color.fromARGB(186, 41, 75, 199); // #294BC7

  // Secondary button (base color #338ACA)
  static const Color secondaryBlue = Color(0xFF338ACA); // full opacity base
  // Fill  7% opacity
  static const Color secondaryBlueFill07 = Color(0x12338ACA); // 7%
  // Border  57% opacity
  static const Color secondaryBlueBorder57 = Color(0x91338ACA); // 57%

  // Text gradient colors
  // static const Color textGradStart = Color(0xFF338ACA); // 100%
  // static const Color textGradEndTransparent = Color(0x00194464); // 0% opacity

  // BLE status gradients (radial)
  // Green: inner #29C739 @41%, outer #142561 @0%
  static const Color bleGreenInner41 = Color(0x6929C739); // 41% opacity
  static const Color bleGreenOuter0 = Color(0x00142561); // 0%

  // Red: inner #C72929 @49%, outer #142561 @0%
  static const Color bleRedInner49 = Color(0x7DC72929); // 49% opacity
  static const Color bleRedOuter0 = Color(0x00142561); // 0%
}
