// lib/src/features/profile/presentation/screens/password_change_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';
import '../../data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../profile_provider.dart';

class PasswordChangeScreen extends ConsumerStatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  ConsumerState<PasswordChangeScreen> createState() =>
      _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends ConsumerState<PasswordChangeScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _verificationCodeCtrl = TextEditingController();

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;

  // 💡 1. 인증번호 발송 상태 관리를 위한 변수 추가
  bool _isCodeSending = false;
  bool _codeSent = false;

  // 💡 2. 발송 버튼을 눌렀을 때 실행될 함수 추가
  Future<void> _sendVerificationCode() async {
    setState(() => _isCodeSending = true);
    try {
      // 💡 1. Provider에서 내 프로필 정보를 읽어와 이메일을 확보합니다.
      final profile = ref.read(profileProvider).value;
      if (profile == null || profile.email.isEmpty) {
        throw Exception('프로필(이메일) 정보를 불러올 수 없습니다.');
      }

      // 💡 2. 레포지토리에 이메일을 넘겨 발송 요청!
      final repo = ref.read(profileRepositoryProvider);
      await repo.requestVerificationCode(profile.email);

      setState(() => _codeSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일로 인증번호가 발송되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('발송 실패: $e')),
        );
      }
    } finally {
      setState(() => _isCodeSending = false);
    }
  }

  // 비밀번호 강도 (0~4)
  int get _strength {
    final pw = _newPwCtrl.text;
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  String get _strengthLabel => switch (_strength) {
        0 => '',
        1 => '약한 비밀번호',
        2 => '보통 비밀번호',
        3 => '강한 비밀번호',
        _ => '매우 강한 비밀번호',
      };

  Color get _strengthColor => switch (_strength) {
        1 => const Color(0xFFD93030),
        2 => const Color(0xFF854F0B),
        3 => const Color(0xFF0F6E56),
        _ => const Color(0xFF185FA5),
      };

  bool get _isValid =>
      _currentPwCtrl.text.isNotEmpty &&
      _newPwCtrl.text.length >= 8 &&
      _newPwCtrl.text == _confirmPwCtrl.text &&
      _verificationCodeCtrl.text.isNotEmpty;

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
                const Text('비밀번호 변경',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 비밀번호
                    _PwField(
                        label: '현재 비밀번호',
                        controller: _currentPwCtrl,
                        obscure: _currentObscure,
                        onToggle: () =>
                            setState(() => _currentObscure = !_currentObscure),
                        onChanged: (_) => setState(() {})),
                    const SizedBox(height: 16),

                    // 인증번호 필드
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _VerificationField(
                              label: '인증번호',
                              controller: _verificationCodeCtrl,
                              hint: '이메일로 발송된 6자리 번호',
                              onChanged: (_) => setState(() {})),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48, // TextField와 높이를 맞춤
                          child: ElevatedButton(
                            // 현재 비밀번호가 입력되어 있어야만 버튼 활성화
                            onPressed:
                                _currentPwCtrl.text.isEmpty || _isCodeSending
                                    ? null
                                    : _sendVerificationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: const Color(0xFFC0BBDE),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isCodeSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(_codeSent ? '재전송' : '발송',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),

                    // 새 비밀번호
                    _PwField(
                        label: '변경할 비밀번호',
                        controller: _newPwCtrl,
                        hint: '새 비밀번호 (8자 이상)',
                        obscure: _newObscure,
                        onToggle: () =>
                            setState(() => _newObscure = !_newObscure),
                        onChanged: (_) => setState(() {})),

                    // 강도 바
                    if (_newPwCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                            4,
                            (i) => Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: i < _strength
                                          ? _strengthColor
                                          : const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                )),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(_strengthLabel,
                            style:
                                TextStyle(fontSize: 11, color: _strengthColor)),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 비밀번호 확인
                    _PwField(
                        label: '변경할 비밀번호 재확인',
                        controller: _confirmPwCtrl,
                        obscure: _confirmObscure,
                        onToggle: () =>
                            setState(() => _confirmObscure = !_confirmObscure),
                        onChanged: (_) => setState(() {}),
                        isError: _confirmPwCtrl.text.isNotEmpty &&
                            _confirmPwCtrl.text != _newPwCtrl.text),

                    if (_confirmPwCtrl.text.isNotEmpty &&
                        _confirmPwCtrl.text != _newPwCtrl.text)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('비밀번호가 일치하지 않습니다',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFD93030))),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isValid
                            ? () async {
                                try {
                                  final repo =
                                      ref.read(profileRepositoryProvider);

                                  // 💡 명세서에 맞춰 oldPassword, verificationCode 전달
                                  await repo.updatePassword(
                                    oldPassword: _currentPwCtrl.text,
                                    newPassword: _newPwCtrl.text,
                                    verificationCode:
                                        _verificationCodeCtrl.text,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('비밀번호가 성공적으로 변경되었습니다.')),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('변경 실패: $e')),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: const Color(0xFFC0BBDE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('완료',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final bool isError;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _PwField(
      {required this.label,
      required this.controller,
      required this.obscure,
      required this.onToggle,
      required this.onChanged,
      this.hint,
      this.isError = false});

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
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(color: Color(0xFFC0BBDE)),
            filled: true,
            fillColor: const Color(0xFFF4F3FF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isError
                        ? const Color(0xFFD93030)
                        : const Color(0xFFF0EEFF),
                    width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isError
                        ? const Color(0xFFD93030)
                        : const Color(0xFFF0EEFF),
                    width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        isError ? const Color(0xFFD93030) : AppColors.primary,
                    width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _VerificationField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

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
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC0BBDE)),
            filled: true,
            fillColor: const Color(0xFFF4F3FF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFF0EEFF), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
