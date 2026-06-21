// lib/src/features/profile/presentation/screens/notification_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _push = true;
  bool _newFriend = true;
  bool _chat = true;
  bool _scheduleAlert = true;
  bool _tripAlert = false;

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
                const Text('알림 설정',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _NotifSection(label: '푸시 알림', items: [
                    _NotifItem(
                        title: '푸시 알림 받기',
                        desc: '앱의 모든 알림을 받습니다',
                        value: _push,
                        onChanged: (v) => setState(() => _push = v)),
                  ]),
                  const SizedBox(height: 16),
                  _NotifSection(label: '활동', items: [
                    _NotifItem(
                        title: '친구 신청',
                        desc: '새로운 친구 신청이 오면 알림',
                        value: _newFriend,
                        onChanged: (v) => setState(() => _newFriend = v)),
                    _NotifItem(
                        title: '채팅',
                        desc: '새로운 메시지가 도착하면 알림',
                        value: _chat,
                        onChanged: (v) => setState(() => _chat = v)),
                    _NotifItem(
                        title: '일정 알림',
                        desc: '여행 D-7, D-1 알림',
                        value: _scheduleAlert,
                        onChanged: (v) => setState(() => _scheduleAlert = v)),
                    _NotifItem(
                        title: '여행 시작/종료',
                        desc: '여행 당일 알림',
                        value: _tripAlert,
                        onChanged: (v) => setState(() => _tripAlert = v)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifSection extends StatelessWidget {
  final String label;
  final List<_NotifItem> items;
  const _NotifSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: .5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < items.length - 1)
                          const Divider(
                              height: 1, color: Color(0xFFF3F4F6), indent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NotifItem extends StatelessWidget {
  final String title, desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifItem(
      {required this.title,
      required this.desc,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2939))),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
