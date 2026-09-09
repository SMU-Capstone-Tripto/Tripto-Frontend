// lib/src/features/profile/presentation/screens/app_info_screen.dart

import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  void _showInfoSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF1E2939),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF757575)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEEEEEE), height: 20, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: const TextStyle(
                        color: Color(0xFF4A4A4A), fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> menuItems = [
      {'title': '버전 정보', 'content': '1.0.0'},
      {
        'title': '이용약관',
        'content': '제 1조 (목적)\n본 약관은 \'벌꿀오소리\' 팀이 제공하는 AI 대화형 여행 일정 생성 플랫폼 \'Tripto\'(이하 \'서비스\')의 이용과 관련하여, 팀과 회원 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n제 2조 (서비스의 내용 및 AI 면책 조항)\n① 본 서비스는 다자간 채팅 및 AI 에이전트를 활용한 맞춤형 여행 일정 생성 기능을 제공합니다.\n② [중요] 서비스 내 AI 에이전트가 제공하는 여행 일정, 예상 비용, 장소 정보 등은 외부 API 및 데이터를 기반으로 생성된 \'참고용 정보\'입니다.\n③ Tripto는 AI가 제공한 정보의 정확성, 최신성, 완전성을 보증하지 않으며, 현지 사정(영업시간 변경, 가격 변동, 휴무 등)에 따라 실제와 다를 수 있습니다. 이로 인해 발생하는 어떠한 손해에 대해서도 Tripto는 법적 책임을 지지 않습니다.\n\n제 3조 (사용자의 의무)\n① 사용자는 불법적인 목적이나 타인에게 피해를 주는 용도로 본 서비스를 이용할 수 없습니다.\n② 서비스 내 채팅방에서 타인에게 불쾌감을 주거나 욕설, 비방, 음란물 등 부적절한 정보를 전송하는 행위는 엄격히 금지됩니다.\n\n제 4조 (서비스의 변경 및 중단)\n본 서비스는 대학교 캡스톤디자인(졸업프로젝트)의 일환으로 개발 및 운영되므로, 사전 고지 없이 서비스의 일부 또는 전체가 변경, 일시 정지되거나 영구 종료될 수 있습니다.'
      },
      {
        'title': '개인정보처리방침',
        'content': 'Tripto는 원활한 서비스 제공을 위해 아래와 같이 최소한의 개인정보를 수집 및 이용하고 있습니다.\n\n1. 수집하는 개인정보 항목\n- 서비스 이용 과정에서 자동 수집되는 항목: 채팅 내역, AI 에이전트 호출 시 입력한 여행 관련 정보(목적지, 예산, 기간 등), 서비스 이용 기록\n\n2. 개인정보의 수집 및 이용 목적\n- 회원 식별 및 그룹 채팅방 참여 관리\n- 대화 내역을 기반으로 한 AI 맞춤형 여행 일정 생성 및 최적화\n- 서비스 품질 향상 및 신규 기능 개발\n\n3. 개인정보의 보유 및 이용 기간\n- 회원의 개인정보는 회원 탈퇴 시 지체 없이 파기됩니다.\n- 단, 사용자가 채팅방 내에서 메시지를 \'삭제\' 처리할 경우, 해당 메시지 데이터는 데이터베이스에서 즉시 영구 삭제됩니다.\n\n4. 개인정보의 제3자 제공 (AI 모델 활용)\n본 서비스는 맞춤형 여행 일정 생성을 위해 사용자가 챗봇을 호출할 때 입력한 정보를 외부 AI 언어 모델(LLM) API에 전송하여 처리합니다. 해당 정보는 일정 생성을 위한 일회성 목적으로만 전송되며, 외부 AI 모델의 학습용 데이터로는 절대 저장되거나 활용되지 않습니다.'
      },
      {
        'title': '마케팅 활용 동의',
        'content': '제 1조 (목적)\n본 약관은 Tripto(이하 \'서비스\')가 사용자에게 최적화된 마케팅 정보 및 혜택을 제공하기 위해 개인정보를 활용하는 것에 대한 제반 사항을 규정합니다.\n\n제 2조 (수집 항목 및 이용 목적)\n① 수집 항목: 이메일 주소, 서비스 이용 기록, 여행 취향 이력\n② 이용 목적:\n- Tripto 신규 서비스, 업데이트 및 이벤트 소식 안내\n- 사용자 맞춤형 여행지 추천 및 큐레이션 서비스 제공\n- 프로모션, 할인 혜택 등 광고성 정보 전달\n- 서비스 이용 통계 분석 및 마케팅 전략 수립\n\n제 3조 (보유 및 이용 기간)\n이용자의 마케팅 활용 동의 시점부터 동의 철회 또는 회원 탈퇴 시까지 해당 정보를 보유 및 이용합니다.\n\n제 4조 (동의 거부권 및 불이익)\n이용자는 본 마케팅 활용 동의를 거부할 권리가 있습니다. 동의를 거부하시더라도 Tripto의 핵심 서비스(여행 일정 생성 및 채팅 등)는 정상적으로 이용하실 수 있으나, 맞춤형 혜택 및 신규 이벤트 안내 등의 제공이 제한될 수 있습니다.'
      },
      {
        'title': '오픈소스 라이선스',
        'content': 'Tripto는 아래의 오픈소스 소프트웨어들을 활용하여 개발되었습니다.\n\n- FastAPI\nCopyright (c) 2018 Sebastián Ramírez (MIT License)\n\n- Flutter\nCopyright 2014 The Flutter Authors (BSD 3-Clause License)\n\n- SQLAlchemy\nCopyright (c) 2005-2024 Michael Bayer (MIT License)\n\n- websockets\nCopyright (c) 2013-2023 Aymeric Augustin (BSD 3-Clause License)\n\n- uvicorn\nCopyright (c) 2017-present, Tom Christie (BSD 3-Clause License)\n\n- Pydantic\nCopyright (c) 2017 to present Pydantic Services Inc. (MIT License)\n\n[Third-party APIs & Services]\n- Powered by Groq API: 본 서비스의 AI 여행 일정 생성 및 언어 모델 처리는 Groq의 초고속 LPU 추론 엔진 및 API를 기반으로 구동됩니다.\n- Powered by AWS S3: 서비스 내 대용량 미디어 저장 및 클라이언트 다이렉트 업로드를 위해 Amazon Web Services(AWS)의 S3 스토리지 서비스를 사용합니다.'
      },
      {
        'title': '문의하기',
        'content': 'Tripto 서비스를 이용해 주셔서 감사합니다.\n\n본 서비스는 대학교 컴퓨터공학전공 캡스톤디자인 프로젝트로 개발되었습니다. 서비스 이용 중 버그 제보, 기타 문의 사항이 있으시다면 아래의 연락처로 의견을 남겨주시면 감사하겠습니다.\n\n- 팀명: 벌꿀오소리\n- 문의 이메일: dldlfkfk18@gmail.com'
      },
    ];

    return Scaffold(
      // 💡 전체 배경색을 완전한 흰색으로 변경
      backgroundColor: Colors.white,
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
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                // 💡 로고 이미지 적용 (에러 빌더 삭제하여 직관적으로 노출)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/tripto_2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('TRIPTO',
                    style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Bakbak One',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Color(0xFF1E2939))),
                const SizedBox(height: 8),
                // 💡 버전 태그의 연보라색을 연회색으로 변경
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // 연보라색 -> 연회색
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('버전 1.0.0',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF757575))), // 보라색 글씨 -> 회색
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                separatorBuilder: (context, index) =>
                    // 💡 구분선의 연보라색도 회색으로 변경
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isVersion = item['title'] == '버전 정보';
                  
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 2),
                      title: Text(item['title']!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E2939))),
                      trailing: isVersion
                          ? Text(item['content']!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary))
                          : const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textSecondary),
                      onTap: isVersion
                          ? null
                          : () => _showInfoSheet(
                              context, item['title']!, item['content']!),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}