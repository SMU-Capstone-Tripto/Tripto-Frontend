// lib/src/features/profile/presentation/screens/profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'password_change_screen.dart';
import '../profile_provider.dart';
import '../../data/profile_repository.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _birthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _uniqueId = '';

  @override
  void initState() {
    super.initState();

    // 이전 화면(ProfileScreen)에서 이미 로드해둔 프로필 데이터 가져오기
    final profile = ref.read(profileProvider).value;

    if (profile != null) {
      // 텍스트 필드와 텍스트 위젯에 서버 데이터 꽂아넣기
      _nicknameController.text = profile.nickname;
      _uniqueId = profile.unique_id;

      // (참고) 현재 ProfileModel(profile_model.dart)에는 생년월일, 전화번호, 이메일 필드가 없습니다.
      // 나중에 백엔드에 해당 항목들이 추가되면, 모델을 업데이트한 뒤 아래처럼 연결해주시면 됩니다.
      // _birthController.text = profile.birth ?? '';
      // _phoneController.text = profile.phone ?? '';
      // _emailController.text = profile.email ?? '';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 앱바
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
                const Text('프로필 편집',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 아바타
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFDDDDDD),
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.white),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 폼
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _FormField(
                            label: '닉네임',
                            controller: _nicknameController,
                            hint: '닉네임을 입력하세요'),
                        const SizedBox(height: 14),
                        _FormField(
                            label: '생년월일',
                            controller: _birthController,
                            hint: 'YYYY-MM-DD',
                            keyboardType: TextInputType.datetime),
                        const SizedBox(height: 14),
                        _FormField(
                            label: '전화번호',
                            controller: _phoneController,
                            hint: '010-0000-0000',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),

                        // 고유 ID (읽기 전용 + 복사)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('고유 ID',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFF0EEFF), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Text(_uniqueId,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary)),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: _uniqueId));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('ID가 복사되었습니다'),
                                        duration: Duration(seconds: 1),
                                      ));
                                    },
                                    icon: const Icon(Icons.copy_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _FormField(
                            label: '이메일 (선택)',
                            controller: _emailController,
                            hint: 'example@email.com',
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 20),

                        // 저장 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                // 1. 레포지토리 가져오기
                                final repo =
                                    ref.read(profileRepositoryProvider);

                                // 2. 서버로 닉네임 수정 요청보내기
                                await repo.updateMe(
                                    nickname: _nicknameController.text);

                                // 3. 프로필 상태를 무효화하여 최신 데이터로 다시 불러오기 (UI 자동 갱신)
                                ref.invalidate(profileProvider);

                                // 4. 완료 후 이전 화면으로 돌아가기 전에 성공 알림 띄우기
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('프로필이 성공적으로 수정되었습니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                // 에러 발생 시 사용자에게 알림
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('프로필 수정 실패: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2939),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('저장 및 완료',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 비밀번호 변경
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PasswordChangeScreen())),
                          child: const Text('비밀번호 변경하기',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _FormField(
      {required this.label,
      required this.controller,
      required this.hint,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC0BBDE)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFF0EEFF), width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFF0EEFF), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
