import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_list_screen.dart';
import 'photo_album_screen.dart';
import 'vote_tabs_screen.dart';
import 'friend_invite_screen.dart';

class ChatRoomSettingsScreen extends StatefulWidget {
  final String title;
  final int roomId;
  final List<int> activeMemberIds; 
  final Map<int, String> userNamesMap; 

  const ChatRoomSettingsScreen({
    super.key, 
    required this.title,
    required this.roomId,
    required this.activeMemberIds,
    required this.userNamesMap,
  });

  @override
  State<ChatRoomSettingsScreen> createState() => _ChatRoomSettingsScreenState();
}

class _ChatRoomSettingsScreenState extends State<ChatRoomSettingsScreen> {
  bool _isNotificationOn = true;
  int _myUserId = 2; 

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  Future<void> _fetchMyProfile() async {
    try {
      final response = await http.get(Uri.parse('${AuthStorage.baseUrl}/auth/me'), headers: AuthStorage.authHeaders);
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _myUserId = int.tryParse(userData['id']?.toString() ?? userData['user_id']?.toString() ?? '2') ?? 2;
        });
      }
    } catch (e) {
      debugPrint('내 프로필 ID 획득 실패: $e');
    }
  }

  Future<void> _requestLeaveRoom() async {
    try {
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/leave?user_id=$_myUserId';
      final response = await http.delete(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChatListScreen()), (route) => false);
      }
    } catch (e) {
      debugPrint('❌ 퇴장 실패: $e');
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🛠️ [완치]: 잘못 지정되어 에러를 품던 const 구문을 제거하고 표준 텍스트 컴포넌트 마킹
            Text(
              '채팅방을 나가시겠습니까?', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              '채팅방을 나가면 대화 내용이 삭제되며\n채팅 목록에서도 대화방이 영구 제외됩니다.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Color(0xFF555555), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context), 
                    child: Container(
                      height: 48, 
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)), 
                      alignment: Alignment.center, 
                      child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); _requestLeaveRoom(); }, 
                    child: Container(
                      height: 48, 
                      decoration: BoxDecoration(color: const Color(0xFFFF4D4D), borderRadius: BorderRadius.circular(12)), 
                      alignment: Alignment.center, 
                      child: const Text('나가기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(63),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 7, offset: Offset(0, 2))]),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
            // 🛠️ [완치]: 상단바 타이틀 충돌 const 블록 완벽 제거 및 정상 인하우스 빌드 완료
            title: Text(
              '채팅방 설정', 
              style: TextStyle(color: Colors.black, fontSize: 19, fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isNotificationOn ? Icons.notifications_none_rounded : Icons.notifications_off_rounded, color: Colors.black, size: 24),
                onPressed: () => setState(() => _isNotificationOn = !_isNotificationOn),
              )
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 35),
          Center(
            child: Stack(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: Color(0xFF925DFB), child: Icon(Icons.groups_rounded, size: 45, color: Colors.white)),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))]),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF925DFB), size: 16),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                  const Icon(Icons.edit, color: Color(0xFF6C6C6C), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('채팅방 참여자 목록', style: TextStyle(color: const Color(0xFF64748B), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Wrap(
              spacing: 10, runSpacing: 8,
              children: widget.activeMemberIds.map((id) {
                final bool isMe = (id == _myUserId);
                final String memberName = widget.userNamesMap[id] ?? '대화 상대';
                final String shortName = memberName.isNotEmpty ? memberName.substring(0, 1) : '대';

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: isMe ? const Color(0xFF6241D9) : const Color(0xFFCBD5E1),
                    child: Text(isMe ? '나' : shortName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  label: Text(
                    memberName, 
                    style: TextStyle(
                      color: isMe ? const Color(0xFF6241D9) : const Color(0xFF334155), 
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),
          Container(height: 8, color: const Color(0xFFF5F5F5)), 

          _buildSettingTile(
              Icons.image_outlined,
              '보낸 사진함',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoAlbumScreen()))),
          _buildSettingTile(
              Icons.check_box_outlined,
              '투표 (준비 중)',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoteTabsScreen()))),
          _buildSettingTile(
              Icons.person_add_alt,
              '친구 초대',
              () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => FriendInviteScreen(roomId: widget.roomId)));
              }),
          _buildSettingTile(Icons.exit_to_app, '채팅방 나가기', _showExitDialog, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.8))),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDanger ? const Color(0xFFFF4D4D) : Colors.black87, size: 22),
        title: Text(label, style: TextStyle(color: isDanger ? const Color(0xFFFF4D4D) : Colors.black, fontSize: 16, fontFamily: 'Inter')),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      ),
    );
  }
}