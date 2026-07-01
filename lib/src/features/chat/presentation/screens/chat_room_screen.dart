import 'package:flutter/material.dart';
import 'chat_detail_vote_screen.dart';
import 'chat_room_settings_screen.dart';
import 'image_picker_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String title;
  final bool isBotRoom;
  const ChatRoomScreen({super.key, required this.title, this.isBotRoom = false});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  bool _showAttachmentPopup = false; 

  /*
  @override
  void initState() {
    super.initState();
    _messages.add({'isMe': false, 'text': '우리 첫쨋날 점심 뭐먹을까?', 'time': '10:28'});
    _messages.add({'isMe': true, 'text': '흠..\n나는 흑돼지 먹고싶은데', 'time': '10:28'});
    _messages.add({'isMe': false, 'text': '오 흑돼지 좋지', 'time': '10:28'});
    _messages.add({'isMe': false, 'text': '맛있는 집 있나?', 'time': '10:28'});
    _messages.add({'isMe': false, 'text': '딱히 생각나는 데는 없는데..', 'time': '10:28'});
    _messages.add({'isMe': true, 'text': '내가 트립토한테 함 물어볼게', 'time': '10:28'});
    _messages.add({'isMe': false, 'text': '좋습니다~', 'time': '10:28'});
  }
  */

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final userText = _msgController.text;
    
    setState(() {
      _messages.add({'isMe': true, 'text': userText, 'time': '10:28'});
      _msgController.clear();
      _showAttachmentPopup = false; 
    });

    if (userText.contains('@트립토')) {
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _messages.add({'isMe': false, 'text': '일정 투표가 시작되었어요!', 'time': '10:28', 'isAiBot': true});
          _messages.add({'isMe': false, 'isVoteCard': true, 'time': '10:28', 'isAiBot': true});
        });
      });
    }
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
            boxShadow: [
              BoxShadow(color: Color(0x3F000000), blurRadius: 7, offset: Offset(0, 2))
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                if (!widget.isBotRoom)
                  const Text('4', style: TextStyle(color: Color(0xFF555555), fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w400)),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomSettingsScreen(title: widget.title))),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg['isVoteCard'] == true) return _buildAiVoteCard();
                    return _buildChatBubble(msg);
                  },
                ),
              ),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 19),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFD9D9D9), width: 1)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showAttachmentPopup = !_showAttachmentPopup),
                      child: const Icon(Icons.add, size: 26, color: Color(0xFF6C6C6C)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 33,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '메세지 입력',
                            hintStyle: TextStyle(color: Color(0xFF6C6C6C), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w300),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: const Icon(Icons.arrow_upward_rounded, size: 28, color: Color(0xFF915DFB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showAttachmentPopup)
            Positioned(
              left: 20,
              bottom: 60,
              child: Container(
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0F0F0), width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                    BoxShadow(color: Color(0x26925DFB), blurRadius: 32, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPopupItem(Icons.camera_alt, '카메라', () {}),
                    Container(height: 0.5, color: const Color(0xFFF0F0F0)),
                    _buildPopupItem(Icons.image, '이미지', () {
                      setState(() => _showAttachmentPopup = false);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ImagePickerScreen(),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopupItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4B5563)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isMe = msg['isMe'] ?? false;
    bool isAiBot = msg['isAiBot'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 25,
              backgroundColor: isAiBot ? const Color(0xFFEAEAEA) : const Color(0xFFD9D9D9),
              child: isAiBot ? const Icon(Icons.face_retouching_natural, color: Color(0xFF7B47FF), size: 24) : null,
            ),
            const SizedBox(width: 17),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                Text(msg['time'], style: const TextStyle(color: Color(0xFFABABAB), fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w300)),
                const SizedBox(width: 6),
              ],
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: ShapeDecoration(
                  color: isMe ? const Color(0xFF915DFB) : const Color(0xFF686570),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  msg['text'],
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w400),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 6),
                Text(msg['time'], style: const TextStyle(color: Color(0xFFABABAB), fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w300)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiVoteCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 67, top: 5, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 201,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFF696671),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('제주 여행 일정 투표', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(height: 0.7, color: Colors.white),
                const SizedBox(height: 10),
                const Text('힐링 제주 여행\n액티비티 제주 여행', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w400, height: 1.64)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetailVoteScreen())),
                  child: Container(
                    width: 165,
                    height: 24,
                    decoration: ShapeDecoration(color: const Color(0x33F4F4F4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    alignment: Alignment.center,
                    child: const Text('지금 투표하기 ', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w400)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text('10:28', style: TextStyle(color: Color(0xFFABABAB), fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}