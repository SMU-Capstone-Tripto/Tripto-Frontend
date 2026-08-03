import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_room_screen.dart';

class ChatRoomSetupScreen extends StatefulWidget {
  final List<String> memberNames;
  final List<int> memberIds;
  final String? manualToken;

  const ChatRoomSetupScreen({
    super.key,
    required this.memberNames,
    required this.memberIds,
    this.manualToken,
  });

  @override
  State<ChatRoomSetupScreen> createState() => _ChatRoomSetupScreenState();
}

class _ChatRoomSetupScreenState extends State<ChatRoomSetupScreen> {
  late final TextEditingController _nameController;
  late String _defaultRoomName;
  bool _isCreating = false;

  late List<String> _localNames;
  late List<int> _localIds;

  @override
  void initState() {
    super.initState();
    _localNames = List.from(widget.memberNames);
    _localIds = List.from(widget.memberIds);
    _defaultRoomName =
        _localNames.isEmpty ? "이름 없는 대화방" : _localNames.join(', ');
    _nameController = TextEditingController(text: _defaultRoomName);
  }

  Map<String, String> _buildHeaders() {
    if (widget.manualToken != null && widget.manualToken!.isNotEmpty) {
      return {
        'Authorization': 'Bearer ${widget.manualToken}',
        'Content-Type': 'application/json; charset=utf-8'
      };
    }
    final Map<String, String> headers =
        Map<String, String>.from(AuthStorage.authHeaders);
    headers['Content-Type'] = 'application/json; charset=utf-8';
    return headers;
  }

  Future<void> _createNewChatRoom() async {
    final finalRoomName = _nameController.text.trim().isEmpty
        ? _defaultRoomName
        : _nameController.text.trim();
    setState(() => _isCreating = true);

    try {
      final targetHeaders = _buildHeaders();
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/chat/rooms'),
        headers: targetHeaders,
        body: jsonEncode(
            {'room_name': finalRoomName, 'invited_user_ids': _localIds}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        final Map<String, dynamic> resData =
            jsonDecode(utf8.decode(response.bodyBytes));
        final int generatedRoomId = resData['room_id'] ?? resData['id'] ?? 14;

        final Map<int, String> contextNamesMap = {};
        for (int i = 0; i < _localIds.length; i++) {
          if (i < _localNames.length) {
            contextNamesMap[_localIds[i]] = _localNames[i];
          }
        }

        final bool isAiRoom = _localIds.contains(-1);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              title: finalRoomName,
              isBotRoom: isAiRoom, // 🎯 1:1 AI 채팅방 속성 바인딩
              roomId: generatedRoomId,
              initialMemberNames: contextNamesMap,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        String errorStr = 'E코드 ${response.statusCode}';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          errorStr = err['detail']?.toString() ?? errorStr;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('방 생성 실패: $errorStr')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('통신 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  /// 🎯 [편집 불가 조합 아바타: 참여자 인원수에 맞게 아바타 스택 생성]
  Widget _buildCompositeAvatar() {
    final int count = _localNames.length;

    Widget singleAvatar(int index, double size, {Color? bg}) {
      final String name = index < _localNames.length ? _localNames[index] : '유저';
      final int id = index < _localIds.length ? _localIds[index] : 0;
      final bool isBot = (id == -1) || name.contains('트립토');
      final String initial = name.isNotEmpty ? name.substring(0, 1) : '유';

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isBot ? const Color(0xFFF5F3FF) : (bg ?? const Color(0xFF6241D9)),
          borderRadius: BorderRadius.circular(size * 0.35),
          border: isBot ? Border.all(color: const Color(0xFF524582).withOpacity(0.3)) : null,
        ),
        alignment: Alignment.center,
        child: isBot
            ? Icon(Icons.auto_awesome, size: size * 0.45, color: const Color(0xFF524582))
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
      );
    }

    if (count <= 1) {
      return singleAvatar(0, 88);
    } else if (count == 2) {
      return SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, child: singleAvatar(0, 48, bg: const Color(0xFF818CF8))),
            Positioned(right: 0, bottom: 0, child: singleAvatar(1, 48, bg: const Color(0xFF6366F1))),
          ],
        ),
      );
    } else if (count == 3) {
      return SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          children: [
            Positioned(left: 20, top: 0, child: singleAvatar(0, 42, bg: const Color(0xFF94A3B8))),
            Positioned(left: 0, bottom: 0, child: singleAvatar(1, 42, bg: const Color(0xFF64748B))),
            Positioned(right: 0, bottom: 0, child: singleAvatar(2, 42, bg: const Color(0xFF475569))),
          ],
        ),
      );
    } else {
      return SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, child: singleAvatar(0, 40, bg: const Color(0xFF94A3B8))),
            Positioned(right: 0, top: 0, child: singleAvatar(1, 40, bg: const Color(0xFF64748B))),
            Positioned(left: 0, bottom: 0, child: singleAvatar(2, 40, bg: const Color(0xFF475569))),
            Positioned(right: 0, bottom: 0, child: singleAvatar(3, 40, bg: const Color(0xFF334155))),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('채팅방 이름 설정',
            style: TextStyle(
                color: Color(0xFF1D1D1D),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 🎯 [수정]: 사진 편집 버튼을 완전히 빼고 읽기 전용 프로필 조합 아바타로 교체
            Center(
              child: _buildCompositeAvatar(),
            ),

            const SizedBox(height: 30),
            const Text('채팅방 이름',
                style: TextStyle(
                    color: Color(0xFF6F6F6F),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard')),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                    color: Color(0xFF1E2939),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard'),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('참여자',
                    style: TextStyle(
                        color: Color(0xFF6F6F6F),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard')),
                Text('${_localNames.length}명',
                    style: const TextStyle(
                        color: Color(0xFF6241D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _localNames.length,
                itemBuilder: (context, index) {
                  final name = _localNames[index];
                  final id = index < _localIds.length ? _localIds[index] : 0;
                  final bool isBot = (id == -1) || name.contains('트립토');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9))),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 14,
                            backgroundColor: isBot ? const Color(0xFFF5F3FF) : const Color(0xFFCBD5E1),
                            child: isBot
                                ? const Icon(Icons.auto_awesome, color: Color(0xFF524582), size: 14)
                                : const Icon(Icons.person, color: Colors.white, size: 14)),
                        const SizedBox(width: 12),
                        Text(name,
                            style: TextStyle(
                                color: isBot ? const Color(0xFF524582) : const Color(0xFF1E2939),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard')),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _localNames.removeAt(index);
                              _localIds.removeAt(index);
                              if (_nameController.text == _defaultRoomName ||
                                  _nameController.text.trim().isEmpty) {
                                _defaultRoomName = _localNames.isEmpty
                                    ? "이름 없는 대화방"
                                    : _localNames.join(', ');
                                _nameController.text = _defaultRoomName;
                              }
                            });
                          },
                          child: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCreating || _localIds.isEmpty
                      ? null
                      : _createNewChatRoom,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6241D9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('채팅방 생성',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}