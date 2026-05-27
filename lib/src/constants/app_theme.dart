import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 및 테마 토큰
/// - 모든 색상값은 여기서 중앙 관리
/// - 변경 시 이 파일만 수정하면 됨
class AppColors {
  AppColors._();

  // ── Primary ──
  static const primary = Color(0xFF6144B0);
  static const primaryLight = Color(0xFFEDE9FF);
  static const primaryDark = Color(0xFF4F35A8);

  // ── 배경색 ──
  static const background = Color(0xFFF4F3FF);
  static const surface = Color(0xFFFFFFFF);

  // ── Text ──
  static const textPrimary = Color(0xFF2D2A5E);
  static const textSecondary = Color(0xFF9993C4);

  // ── Avatar 색상 팔레트 ──
  static const avatarPurple = Color(0xFFEDE9FF);
  static const avatarPurpleText = Color(0xFF6144B0);
  static const avatarPink = Color(0xFFFFE9F5);
  static const avatarPinkText = Color(0xFFC0527A);
  static const avatarTeal = Color(0xFFE1F5EE);
  static const avatarTealText = Color(0xFF0F6E56);
  static const avatarAmber = Color(0xFFFAEEDA);
  static const avatarAmberText = Color(0xFF854F0B);
  static const avatarBlue = Color(0xFFE6F1FB);
  static const avatarBlueText = Color(0xFF185FA5);

  // ── 상태 ──
  static const online = Color(0xFF1D9E75);
  static const border = Color(0x1A7C5CBF); // 10% opacity
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Pretendard', // pubspec.yaml에 폰트 등록 필요
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
