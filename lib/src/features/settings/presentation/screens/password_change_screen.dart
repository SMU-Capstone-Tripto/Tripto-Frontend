// lib/src/features/profile/presentation/screens/password_change_screen.dart

import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;

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
      _newPwCtrl.text == _confirmPwCtrl.text;

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
                        onPressed:
                            _isValid ? () => Navigator.pop(context) : null,
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
