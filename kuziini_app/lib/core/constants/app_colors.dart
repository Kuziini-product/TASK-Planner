import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary Palette ──
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0A5C5F);
  static const Color primaryContainer = Color(0xFFB2DFDB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002020);

  // ── Secondary Palette ──
  static const Color secondary = Color(0xFF4A6572);
  static const Color secondaryLight = Color(0xFF7694A3);
  static const Color secondaryDark = Color(0xFF233944);
  static const Color secondaryContainer = Color(0xFFCFD8DC);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1A2C34);

  // ── Surface Colors (Light) ──
  static const Color surfaceLight = Color(0xFFF8FAFA);
  static const Color surfaceVariantLight = Color(0xFFF0F4F4);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color scaffoldLight = Color(0xFFF5F7F7);
  static const Color dividerLight = Color(0xFFE0E5E5);

  // ── Surface Colors (Dark) ──
  static const Color surfaceDark = Color(0xFF1A1C1E);
  static const Color surfaceVariantDark = Color(0xFF252829);
  static const Color backgroundDark = Color(0xFF121314);
  static const Color cardDark = Color(0xFF1E2022);
  static const Color scaffoldDark = Color(0xFF121314);
  static const Color dividerDark = Color(0xFF2E3234);

  // ── Text Colors (Light) ──
  static const Color textPrimaryLight = Color(0xFF1A1C1E);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textTertiaryLight = Color(0xFF9AA0A6);
  static const Color textDisabledLight = Color(0xFFBDC1C6);

  // ── Text Colors (Dark) ──
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color textDisabledDark = Color(0xFF4B5563);

  // ── Semantic Colors ──
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // ── Priority Colors ──
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityUrgentBg = Color(0xFFFEE2E2);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityHighBg = Color(0xFFFED7AA);
  static const Color priorityMedium = Color(0xFFEAB308);
  static const Color priorityMediumBg = Color(0xFFFEF9C3);
  static const Color priorityLow = Color(0xFF3B82F6);
  static const Color priorityLowBg = Color(0xFFDBEAFE);
  static const Color priorityNone = Color(0xFF9CA3AF);
  static const Color priorityNoneBg = Color(0xFFF3F4F6);

  // ── Status Colors ──
  static const Color statusTodo = Color(0xFF9CA3AF);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusDone = Color(0xFF10B981);
  static const Color statusBlocked = Color(0xFFEF4444);
  static const Color statusCancelled = Color(0xFF6B7280);

  // ── Misc ──
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A2A);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3A);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
}
