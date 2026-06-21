import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// 네트워크 에러 공통 위젯
class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final String? errorCode;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.errorCode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 에러 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_outlined,
                  size: 36, color: Color(0xFFD93030)),
            ),
            const SizedBox(height: 16),

            const Text('연결할 수 없어요',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2939))),
            const SizedBox(height: 8),

            Text(
              message ?? '네트워크 연결을 확인하고\n다시 시도해주세요',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),

            // 에러 코드 (디버깅용)
            if (errorCode != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(errorCode!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace')),
              ),
            ],

            // 재시도 버튼
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined, size: 16),
                label: const Text('다시 시도',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
