import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_list_screen.dart';
import 'photo_album_screen.dart';
import 'vote_tabs_screen.dart';
import 'friend_invite_screen.dart';

class FlatCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFAE34) 
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.1, size.height * 0.75)
      ..lineTo(size.width * 0.9, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.75, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.18) 
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..close();
    canvas.drawPath(bodyPath, paint);

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
  final Map<int, String?>? userProfileImagesMap;
  final int? ownerId; 

  const ChatRoomSettingsScreen({
    super.key, 
    required this.title,
    required this.roomId,
    required this.activeMemberIds,
    required this.userNamesMap,
    this.userProfileImagesMap,
    this.ownerId, 
  });

  @override
  State<ChatRoomSettingsScreen> createState() => _ChatRoomSettingsScreenState();
}

class _ChatRoomSettingsScreenState extends State<ChatRoomSettingsScreen> {
  bool _isNotificationOn = true;
  int _myUserId = 2; 
  late String _roomTitle; 

  @override
  void initState() {
    super.initState();
    _roomTitle = widget.title;
    _fetchMyProfile();
  }

  List<int> get _cleanActiveMemberIds {
    return widget.activeMemberIds.where((id) {
      if (id == -1) return false;

      String rawNick = widget.userNamesMap[id]?.trim() ?? '';
      rawNick = rawNick.replaceAll('<', '').replaceAll('>', '').replaceAll('(', '').replaceAll(')', '').trim();

      bool isInvalid = rawNick.isEmpty || 
                       rawNick.contains('대화상대') || 
                       rawNick.contains('알수없음') || 
                       rawNick.contains('알 수 없음') || 
                       RegExp(r'^유저\d+$').hasMatch(rawNick);

      return !isInvalid;
    }).toList();
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

  Future<void> _updateRoomTitleOnServer(String newName) async {
    try {
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/name?room_name=$newName';
      final response = await http.put(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);
      if (response.statusCode == 200) {
        debugPrint('방 이름 서버 변경 성공');
      }
    } catch (e) {
      debugPrint('방 이름 백엔드 동기화 실패: $e');
    }
  }

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

  /// 🎯 [설정 화면 상단 대형 아바타: S3 프로필 사진 적용]
  Widget _buildCompositeAvatar(List<int> memberIds, Map<int, String> namesMap, Map<int, String?>? imagesMap) {
    final int count = memberIds.length;

    Widget singleMiniAvatar(int id, double size, {Color? bg}) {
      final String name = namesMap[id] ?? '나';
      final String char = name.isNotEmpty ? name.substring(0, 1) : '나';
      final String? imgUrl = imagesMap?[id];

      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(size * 0.35), 
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: (imgUrl != null && imgUrl.isNotEmpty)
            ? Image.network(
                imgUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  char,
                  style: TextStyle(color: Colors.white, fontSize: size * 0.45, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                ),
              )
            : Text(
                char,
                style: TextStyle(color: Colors.white, fontSize: size * 0.45, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
              ),
      );
    }

    return Container(
      width: 100, height: 100,
      alignment: Alignment.center,
      child: Builder(
        builder: (context) {
          if (count <= 1) {
            return singleMiniAvatar(memberIds.isNotEmpty ? memberIds[0] : _myUserId, 100, bg: const Color(0xFF6241D9));
          }
          else if (count == 2) {
            return Stack(
              children: [
                Positioned(left: 4, top: 4, child: singleMiniAvatar(memberIds[0], 52, bg: const Color(0xFF818CF8))),
                Positioned(right: 4, bottom: 4, child: singleMiniAvatar(memberIds[1], 52, bg: const Color(0xFF6366F1))),
              ],
            );
          }
          else if (count == 3) {
            return Stack(
              children: [
                Positioned(left: 26, top: 4, child: singleMiniAvatar(memberIds[0], 48, bg: const Color(0xFF94A3B8))),
                Positioned(left: 2, bottom: 4, child: singleMiniAvatar(memberIds[1], 48, bg: const Color(0xFF64748B))),
                Positioned(right: 2, bottom: 4, child: singleMiniAvatar(memberIds[2], 48, bg: const Color(0xFF475569))),
              ],
            );
          }
          else {
            return Stack(
              children: [
                Positioned(left: 4, top: 4, child: singleMiniAvatar(memberIds[0], 44, bg: const Color(0xFF94A3B8))),
                Positioned(right: 4, top: 4, child: singleMiniAvatar(memberIds[1], 44, bg: const Color(0xFF64748B))),
                Positioned(left: 4, bottom: 4, child: singleMiniAvatar(memberIds[2], 44, bg: const Color(0xFF475569))),
                Positioned(right: 4, bottom: 4, child: singleMiniAvatar(memberIds[3], 44, bg: const Color(0xFF334155))),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanMembers = _cleanActiveMemberIds;

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
            child: _buildCompositeAvatar(cleanMembers, widget.userNamesMap, widget.userProfileImagesMap),
          ),
          const SizedBox(height: 25),
          
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
              children: cleanMembers.map((id) {
                final bool isMe = (id == _myUserId);
                final bool isOwner = (widget.ownerId != null && id == widget.ownerId); 
                
                final String memberName = widget.userNamesMap[id] ?? '유저';
                final String shortName = memberName.isNotEmpty ? memberName.substring(0, 1) : '유';
                final String? profileImgUrl = widget.userProfileImagesMap?[id];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDF2F7), width: 0.8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    onTap: null, 
                    // 🎯 참여자 리스트에서 유저별 S3 프로필 이미지 로드
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMe ? const Color(0xFF6241D9) : const Color(0xFFCBD5E1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: (profileImgUrl != null && profileImgUrl.isNotEmpty)
                          ? Image.network(
                              profileImgUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                isMe ? '나' : shortName,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                              ),
                            )
                          : Text(
                              isMe ? '나' : shortName,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                            ),
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
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          CustomPaint(
                            size: const Size(18, 14), 
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