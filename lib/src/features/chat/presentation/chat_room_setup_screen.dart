import 'package:flutter/material.dart';
import 'chat_room_screen.dart';

class ChatRoomSetupScreen extends StatefulWidget {
  final List<String> members; // 전 단계에서 선택되어 넘어온 친구 이름 목록
  const ChatRoomSetupScreen({super.key, required this.members});

  @override
  State<ChatRoomSetupScreen> createState() => _ChatRoomSetupScreenState();
}

class _ChatRoomSetupScreenState extends State<ChatRoomSetupScreen> {
  late final TextEditingController _nameController;
  late final String _defaultRoomName; // 텍스트를 다 지웠을 때 복구할 기본 이름 조합
  String? _pickedImagePath; // 유저가 선택한 이미지 경로 상태 (null이면 기본 회색)

  @override
  void initState() {
    super.initState();
    // 전 단계에서 넘어온 친구 이름을 콤마(,)로 연결하여 기본 방 이름 자동 추출
    _defaultRoomName = widget.members.isEmpty ? "이름 없는 대화방" : widget.members.join(', ');
    _nameController = TextEditingController(text: _defaultRoomName);
  }

  // 🛠️ 이미지 접근 및 권한 핸들링 인터페이스 (실제 모듈 스텁 배치)
  Future<void> _handleImageSelection() async {
    // [기능 구현] 갤러리 접근 권한 팝업 호출 및 이미지 선택 로직 가상 트리거
    // 가상으로 이미지가 선택되었다고 상태를 변경합니다. (실제 배포 시 image_picker 패키지 한 줄 매핑 공간)
    setState(() {
      _pickedImagePath = "https://placehold.co/200x200"; 
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('갤러리 접근 권한 승인 및 프로필 사진이 변경되었습니다.', style: TextStyle(fontFamily: 'Pretendard')),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // 🛠️ 프로필 사진 삭제 로직
  void _deleteProfileImage() {
    setState(() {
      _pickedImagePath = null; // 상태를 다시 null로 만들어 기본 회색 서클 복구
    });
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
        leadingWidth: 56, // 🛠️ 뒤로가기 터치 영역 가로폭 확보
        // 🛠️ [정렬 교정] 아이콘과 백그라운드 원형의 중심축 수직/수평 중앙 정렬 매칭
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: IconButton(
              icon: const Padding(
                padding: EdgeInsets.only(left: 6.0), // ios 백 화살표 미세 정렬 패딩
                child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          '채팅방 이름 설정', 
          style: TextStyle(color: Color(0xFF1D1D1D), fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            
            // 🛠️ [기능 추가] 중앙 원형 프로필 이미지 추가/삭제 스위칭 시스템
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50, 
                    backgroundColor: const Color(0xFFE5E7EB),
                    backgroundImage: _pickedImagePath != null ? NetworkImage(_pickedImagePath!) : null,
                    child: _pickedImagePath == null 
                        ? const Icon(Icons.groups, color: Colors.white, size: 45)
                        : null,
                  ),
                  Positioned(
                    right: 0, 
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickedImagePath == null ? _handleImageSelection : _deleteProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pickedImagePath == null ? const Color(0xFF874CFF) : const Color(0xFFFF4D4D), // 사진 있으면 빨간색 탈바꿈
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 3))
                          ],
                        ),
                        child: Icon(
                          _pickedImagePath == null ? Icons.camera_alt : Icons.delete_forever, // 사진 있으면 휴지통으로 변경
                          color: Colors.white, 
                          size: 16,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            const Text('채팅방 이름', style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
            const SizedBox(height: 8),
            
            // 채팅방 이름 인풋 텍스트 필드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFF1D1D1D), fontSize: 16, fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  // 🛠️ [기능 구현] 글자를 다 지웠을 때 기본 이름 조합이 가이드 힌트로 살아나게 세팅
                  hintText: _defaultRoomName,
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Pretendard'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cancel, color: Color(0xFFB3B3B3), size: 18),
                    onPressed: () {
                      setState(() {
                        _nameController.clear(); // 원터치 리셋 시 힌트네임 복구 작동
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // 참여자 현황 스펙바
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('참여자', style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
                Text('${widget.members.length}명', style: const TextStyle(color: Color(0xFF874CFF), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
              ],
            ),
            const SizedBox(height: 15),
            
            // 참여자 목록 스크롤 스페이스
            Expanded(
              child: ListView(
                children: [
                  ...widget.members.map((name) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 18, backgroundColor: Color(0xFF5F5F5F), child: Icon(Icons.person, color: Colors.white24, size: 18)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Color(0xFF1D1D1D), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
                            const Text('tpdms13', style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 11, fontFamily: 'Pretendard')),
                          ],
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  
                  // 🛠️ [디테일 수정] 가로폭 폭을 늘리고 터치 시 전 화면으로 즉시 백(Pop)하는 편집 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50, // 높이감 확장
                    child: OutlinedButton(
                      // 🛠️ 누르면 바로 전 화면(친구선택창)으로 돌아가서 재편집 유도 기획 매핑
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF874CFF), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horizontal_circle_outlined, color: Color(0xFF874CFF), size: 18),
                          const SizedBox(width: 8),
                          Text('참여자 추가/편집', style: TextStyle(color: Color(0xFF874CFF), fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 최종 최하단 [채팅방 생성] 마스터 액션 단추
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                width: double.infinity, 
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // 공백이면 힌트로 뜬 기본 이름을 채워서 방 개설
                    final finalRoomName = _nameController.text.trim().isEmpty ? _defaultRoomName : _nameController.text;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => ChatRoomScreen(title: finalRoomName)),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8055FF), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    elevation: 0,
                  ),
                  child: const Text('채팅방 생성', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}