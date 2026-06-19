import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'photo_album_screen.dart';
import 'vote_tabs_screen.dart';
import 'friend_invite_screen.dart';

class ChatRoomSettingsScreen extends StatefulWidget {
  final String title;
  const ChatRoomSettingsScreen({super.key, required this.title});

  @override
  State<ChatRoomSettingsScreen> createState() => _ChatRoomSettingsScreenState();
}

class _ChatRoomSettingsScreenState extends State<ChatRoomSettingsScreen> {
  bool _isNotificationOn = true;

  // 피그마 다이얼로그 디자인 스펙 (width: 319.99, 그림자값 완벽 수용)
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
            const Text(
              '채팅방을 나가시겠습니까?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            const Text(
              '채팅방을 나가면 대화 내용이 삭제되며\n채팅 목록에서도 삭제됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF555555), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w400),
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
                      child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // 팝업 닫기
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatListScreen()),
                        (route) => false, // 스택 전부 날리고 메인 목록으로 완전 이탈
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFFF4D4D), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('나가기', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x3F000000), blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
            title: const Text('채팅방 설정', style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isNotificationOn ? Icons.notifications_none : Icons.notifications_off, color: Colors.black, size: 24),
                onPressed: () => setState(() => _isNotificationOn = !_isNotificationOn),
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 35),
          Center(
            child: Stack(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: Color(0xFF925DFB)),
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Inter')),
                  const Icon(Icons.edit, color: Color(0xFF6C6C6C), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(height: 8, color: const Color(0xFFF5F5F5)), // 피그ما 분리선 구획층 대입
          _buildSettingTile(Icons.image_outlined, '보낸 사진함', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoAlbumScreen()))),
          _buildSettingTile(Icons.check_box_outlined, '투표', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoteTabsScreen()))),
          _buildSettingTile(Icons.person_add_alt, '친구 초대', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendInviteScreen()))),
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