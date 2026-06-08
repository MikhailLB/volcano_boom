import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized colors, gradients and text styles for Volcano Boom.
class AppColors {
  static const Color bgDark = Color(0xFF0B0710);
  static const Color bgPanel = Color(0xFF1A1320);
  static const Color bgPanelLight = Color(0xFF2A1E33);
  static const Color lava = Color(0xFFFF7A18);
  static const Color lavaBright = Color(0xFFFFB347);
  static const Color ember = Color(0xFFFF3D2E);
  static const Color gold = Color(0xFFFFD24A);
  static const Color crystal = Color(0xFF7AE0FF);
  static const Color magma = Color(0xFFB14CFF);
  static const Color textPrimary = Color(0xFFFFF3E6);
  static const Color textMuted = Color(0xFFB9A6C4);
  static const Color success = Color(0xFF54E08A);
  static const Color locked = Color(0xFF5A4A66);

  static const LinearGradient lavaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC24A), Color(0xFFFF7A18), Color(0xFFFF2E2E)],
  );

  static const LinearGradient crystalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB14CFF), Color(0xFF6A3DFF)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE89A), Color(0xFFFFC24A), Color(0xFFE89B27)],
  );
}

class AppText {
  static TextStyle display(double size, {Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color, height: 1.05);

  static TextStyle body(double size, {Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
}

class Assets {
  static const String _a = 'assets/';
  static const String logo = '${_a}logo_1.webp';
  static const String gameName = '${_a}Game_Name.webp';
  static const String loadingVertical = '${_a}Vertizal_Loading_Screen.webp';
  static const String loadingHorizontal = '${_a}Horizontal_Loading_Screen.webp';
  static const String notificationsVertical = '${_a}Vertical_Notifications_Screen.webp';
  static const String nowifiVertical = '${_a}Vertical_Nowifi_Screen.webp';

  /// Volcano sprite for index 0..9.
  static String volcano(int i) => '${_a}volcano_asset_${(i + 1).toString().padLeft(2, '0')}.webp';

  /// Matching background for index 0..9.
  static String background(int i) => '${_a}bg_asset_${(i + 1).toString().padLeft(2, '0')}.webp';
}
