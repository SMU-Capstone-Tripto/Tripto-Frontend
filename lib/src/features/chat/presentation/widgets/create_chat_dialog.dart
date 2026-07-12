
import 'package:flutter/material.dart';
import '../../domain/chat_model.dart';

/// 채팅방 생성 다이얼로그
/// [type] : group 또는 ai
/// 반환값 : 입력한 채팅방 이름 (취소 시 null)
Future<String?> showCreateChatDialog(BuildContext context, ChatType type) {
  final controller = TextEditingController();
  final isAi = type == ChatType.ai;

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isAi ? 'AI 채팅방 만들기' : '그룹 채팅방 만들기',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D2A5E)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAi ? 'AI와의 1:1 채팅방을 만들어요' : '채팅방 이름을 입력하세요',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9993C4)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isAi ? '예) 여행 AI 도우미' : '예) 제주도 여행 2026',
              hintStyle: const TextStyle(color: Color(0xFFCBC8E8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEDE9FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6144B0)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Color(0xFF9993C4))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6144B0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('만들기', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}