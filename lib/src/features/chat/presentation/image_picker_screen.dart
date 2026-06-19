import 'package:flutter/material.dart';

class ImagePickerScreen extends StatelessWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 피그마 상단 내비게이션 탑 바 바인딩 (X, 최근 항목 ▾, 전송 아이콘)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '최근 항목',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter'),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.black),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF7145D0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 피그마 3열 격자(Grid) 사진첩 리스트 시스템 매핑
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                childAspectRatio: 1,
              ),
              itemCount: 16, // 가상의 더미 에셋 개수
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 피그마 1번째 슬롯: 카메라 셔터 촬영 모듈 아이콘 배치
                  return Container(
                    color: const Color(0xFFB5B0B0),
                    child: const Icon(Icons.camera_alt_outlined, size: 35, color: Colors.white),
                  );
                }
                
                // 피그마 2번째 슬롯: 아이스 아메리카노 보라색 체크 활성화 예시 처리
                bool isSelectedSample = (index == 1);

                return Stack(
                  children: [
                    // 더미 갤러리 픽셀 공간 (피그마 시안 느낌의 회색 톤앤매너 분포)
                    Container(
                      color: index % 2 == 0 ? const Color(0xFFD9D9D9) : const Color(0xFFC6C6C6),
                    ),
                    // 피그마 우측 상단 라운드 체크 링 매핑
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelectedSample ? const Color(0xFF8055FF) : Colors.black26,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: isSelectedSample
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}