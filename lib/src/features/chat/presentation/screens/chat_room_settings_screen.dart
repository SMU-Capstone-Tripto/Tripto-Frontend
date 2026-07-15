import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_list_screen.dart';
import 'photo_album_screen.dart';
import 'vote_tabs_screen.dart';
import 'friend_invite_screen.dart';

/// 👑 [UI 구현]: 유저님이 첨부해주신 수평 바 분리형 플랫 골드 왕관을 그리는 전용 패스 페인터
class FlatCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFAE34) // 이미지와 일치하는 노란색/오렌지 골드 톤
      ..style = PaintingStyle.fill;

    // 1. 상단 3개 뿔 바디 드로잉
    final bodyPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.1, size.height * 0.75)
      ..lineTo(size.width * 0.9, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.75, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.18) // 가운데 높은 뿔
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // 2. 하단 독립형 수평 바 드로잉 (분리선 공간 연출)
    final barPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16),
        const Radius.circular(1.5),
      ));
    canvas.drawPath(barPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ChatRoomSettingsScreen extends StatefulWidget {
  final String title;
  final int roomId;
  final List<int> activeMemberIds; 
  final Map<int, String> userNamesMap; 
  final int? ownerId; 

  const ChatRoomSettingsScreen({
    super.key, 
    required this.title,
    required this.roomId,
    required this.activeMemberIds,
    required this.userNamesMap,
    this.ownerId, 
  });

  @override
  State<ChatRoomSettingsScreen> createState() => _ChatRoomSettingsScreenState();
}

class _ChatRoomSettingsScreenState extends State<ChatRoomSettingsScreen> {
  bool _isNotificationOn = true;
  int _myUserId = 2; 
  late String _roomTitle; // 동적 방 이름 제어 상태 변수

  @override
  void initState() {
    super.initState();
    _roomTitle = widget.title;
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

  /// 📝 [API 연동 영역]: 채팅방 이름 편집 요청 모듈 (백엔드 설계 표준 예시 반영)
  Future<void> _updateRoomTitleOnServer(String newName) async {
    try {
      // 나중에 백엔드에 PUT/PATCH 엔드포인트 개설 시 주소만 맞춰주시면 즉시 동기화됩니다.
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/name?room_name=$newName';
      final response = await http.put(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);
      
      if (response.statusCode == 200) {
        debugPrint('방 이름 서버 변경 성공');
      }
    } catch (e) {
      debugPrint('방 이름 백엔드 동기화 실패(플레이스홀더): $e');
    }
  }

  /// 📸 [API 연동 영역]: 채팅방 대표 사진 수정 모듈
  Future<void> _uploadRoomPhotoSimulate() async {
    // 💡 이미지 픽커(image_picker) 플러그인 결합용 인터페이스 액션 스택 부위
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 갤러리 연동 및 대표 이미지 업로드를 시작합니다.', style: TextStyle(fontFamily: 'Pretendard'))),
    );
  }

  /// 📝 [UI 렌더]: 방 이름 변경 모달 다이얼로그 상자
  void _showEditRoomNameDialog() {
    final TextEditingController nameEditController = TextEditingController(text: _roomTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📝 채팅방 이름 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        content: TextField(
          controller: nameEditController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
          decoration: const InputDecoration(
            hintText: '변경할 방 이름을 입력하세요',
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6241D9))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6241D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              final typedName = nameEditController.text.trim();
              if (typedName.isNotEmpty) {
                setState(() => _roomTitle = typedName);
                _updateRoomTitleOnServer(typedName);
              }
              Navigator.pop(context);
            },
            child: const Text('변경', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          )
        ],
      ),
    );
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
            const Text(
              '채팅방을 나가시겠습니까?', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
            ),
            const SizedBox(height: 15),
            const Text(
              '채팅방을 나가면 대화 내용이 삭제되며\n채팅 목록에서도 대화방이 영구 제외됩니다.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Color(0xFF555555), fontSize: 14, fontFamily: 'Pretendard'),
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
                      child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
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
                      child: const Text('나가기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
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
            title: const Text(
              '채팅방 설정', 
              style: TextStyle(color: Colors.black, fontSize: 19, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
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
                // 📸 [사진 수정 터치 기믹 구현부]: 카메라 원형 탭 결합
                Positioned(
                  right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: _uploadRoomPhotoSimulate,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))]),
                      child: const Icon(Icons.camera_alt, color: Color(0xFF925DFB), size: 16),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),
          
          // 📝 [방 이름 수정 터치 기믹 구현부]: 박스 전체 또는 연필 버튼 클릭 연동
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: _showEditRoomNameDialog,
              child: Container(
                height: 48, padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_roomTitle, style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
                    const Icon(Icons.edit, color: Color(0xFF6C6C6C), size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: const Text('채팅방 참여자 목록', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: widget.activeMemberIds.map((id) {
                final bool isMe = (id == _myUserId);
                final bool isOwner = (widget.ownerId != null && id == widget.ownerId); 
                
                final String memberName = widget.userNamesMap[id] ?? '대화 상대';
                final String shortName = memberName.isNotEmpty ? memberName.substring(0, 1) : '대';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDF2F7), width: 0.8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    // 💡 [수정]: 방장 직접 위임 수동 액션 기믹 원천 삭제 처리 완료
                    onTap: null, 
                    leading: CircleAvatar(
                      backgroundColor: isMe ? const Color(0xFF6241D9) : const Color(0xFFCBD5E1),
                      child: Text(isMe ? '나' : shortName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      children: [
                        Text(
                          memberName, 
                          style: TextStyle(
                            color: isMe ? const Color(0xFF6241D9) : const Color(0xFF1E2939), 
                            fontWeight: (isMe || isOwner) ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Pretendard',
                            fontSize: 14.5,
                          ),
                        ),
                        // ── 👑 [디자인 완전 변경]: 요청하신 이미지 형상의 플랫 분리형 골드 벡터 왕관 컴포넌트 실체화 ──
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          CustomPaint(
                            size: const Size(14, 14), // 정갈하고 이쁜 비율 크기 락
                            painter: FlatCrownPainter(),
                          ),
                        ],
                      ],
                    ),
                    trailing: isMe 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEEF2F6), borderRadius: BorderRadius.circular(6)),
                            child: const Text('나', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                          ) 
                        : isOwner 
                            ? const Text('방장', style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'))
                            : null,
                  ),
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
        title: Text(label, style: TextStyle(color: isDanger ? const Color(0xFFFF4D4D) : Colors.black, fontSize: 16, fontFamily: 'Pretendard')),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      ),
    );
  }
}