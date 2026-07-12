// lib/src/features/profile/presentation/screens/app_info_screen.dart

import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text('앱정보',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          // 앱 아이콘 + 버전
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: const Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7c5cbf), Color(0xFF4f35a8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Center(
                        child:
                            Icon(Icons.flight, size: 36, color: Colors.white),
                      )),
                ),
                SizedBox(height: 12),
                Text('Tripto',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
                Text('버전 1.0.0',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 메뉴 목록
          ...[
            ('버전 정보', '1.0.0'),
            ('이용약관', ''),
            ('개인정보처리방침', ''),
            ('오픈소스 라이선스', ''),
            ('문의하기', ''),
          ].map((item) => Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(item.$1,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E2939)))),
                          if (item.$2.isNotEmpty)
                            Text(item.$2,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary))
                          else
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0EEFF)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
