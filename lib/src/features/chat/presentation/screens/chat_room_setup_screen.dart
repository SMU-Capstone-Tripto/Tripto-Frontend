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
  String? _pickedImagePath; 
  bool _isCreating = false; 

  late List<String> _localNames;
  late List<int> _localIds;

  @override
  void initState() {
    super.initState(); 
    _localNames = List.from(widget.memberNames);
    _localIds = List.from(widget.memberIds);
    _defaultRoomName = _localNames.isEmpty ? "이름 없는 대화방" : _localNames.join(', '); 
    _nameController = TextEditingController(text: _defaultRoomName); 
  }

  Future<void> _handleImageSelection() async { 
    setState(() { _pickedImagePath = "https://placehold.co/200x200"; });
  }

  Map<String, String> _buildHeaders() { 
    if (widget.manualToken != null && widget.manualToken!.isNotEmpty) { 
      return { 'Authorization': 'Bearer ${widget.manualToken}', 'Content-Type': 'application/json; charset=utf-8' };
    }
    final Map<String, String> headers = Map<String, String>.from(AuthStorage.authHeaders); 
    headers['Content-Type'] = 'application/json; charset=utf-8'; 
    return headers; 
  }

  Future<void> _createNewChatRoom() async { 
    final finalRoomName = _nameController.text.trim().isEmpty ? _defaultRoomName : _nameController.text.trim(); 
    setState(() => _isCreating = true); 

    try {
      final targetHeaders = _buildHeaders(); 
      final response = await http.post( 
        Uri.parse('${AuthStorage.baseUrl}/chat/rooms'), 
        headers: targetHeaders, 
        body: jsonEncode({ 'room_name': finalRoomName, 'invited_user_ids': _localIds }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) { 
        if (!mounted) return; 

        final Map<String, dynamic> resData = jsonDecode(utf8.decode(response.bodyBytes));
        final int generatedRoomId = resData['room_id'] ?? resData['id'] ?? 14;
        
        // 🎯 [생성 주입 결합]: 초대 창에서 추가했던 친구들의 진짜 ID와 닉네임을 맵 객체로 완벽 바인딩합니다.
        final Map<int, String> contextNamesMap = {};
        for (int i = 0; i < _localIds.length; i++) {
          if (i < _localNames.length) {
            contextNamesMap[_localIds[i]] = _localNames[i];
          }
        }

        Navigator.pushAndRemoveUntil( 
          context, 
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              title: finalRoomName,
              roomId: generatedRoomId,
              // 💥 이제 ChatRoomScreen 생성자가 이 장부를 정확하게 받으므로 컴파일 에러 없이 연동됩니다!
              initialMemberNames: contextNamesMap, 
            ),
          ), 
          (route) => route.isFirst, 
        );
      } else { 
        String errorStr = 'E코드 ${response.statusCode}'; 
        try { final err = jsonDecode(utf8.decode(response.bodyBytes)); errorStr = err['detail']?.toString() ?? errorStr; } catch (_) {} 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('방 생성 실패: $errorStr'))); 
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('통신 실패: $e'))); 
    } finally { 
      if (mounted) setState(() => _isCreating = false); 
    }
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: Colors.white, 
      appBar: AppBar( 
        backgroundColor: Colors.white, elevation: 0, centerTitle: true, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)), 
        title: const Text('채팅방 이름 설정', style: TextStyle(color: Color(0xFF1D1D1D), fontSize: 18, fontWeight: FontWeight.w700)), 
      ),
      body: Padding( 
        padding: const EdgeInsets.symmetric(horizontal: 30.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const SizedBox(height: 20), 
            Center( 
              child: Stack( 
                children: [
                  CircleAvatar( 
                    radius: 44, backgroundColor: const Color(0xFFE5E7EB), 
                    backgroundImage: _pickedImagePath != null ? NetworkImage(_pickedImagePath!) : null, 
                    child: _pickedImagePath == null ? const Icon(Icons.groups, color: Colors.white, size: 40) : null, 
                  ),
                  Positioned( 
                    right: 0, bottom: 0, 
                    child: GestureDetector( 
                      onTap: _handleImageSelection, 
                      child: Container( 
                        padding: const EdgeInsets.all(6), 
                        decoration: const BoxDecoration(color: Color(0xFF6241D9), shape: BoxShape.circle), 
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14), 
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30), 
            const Text('채팅방 이름', style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 13, fontWeight: FontWeight.w500)), 
            const SizedBox(height: 8), 
            Container( 
              padding: const EdgeInsets.symmetric(horizontal: 16), 
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), 
              child: TextField( 
                controller: _nameController, 
                style: const TextStyle(color: Color(0xFF1E2939), fontSize: 15, fontWeight: FontWeight.w600), 
                decoration: const InputDecoration(border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFF94A3B8))), 
              ),
            ),
            const SizedBox(height: 24), 
            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text('참여자', style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 13, fontWeight: FontWeight.w500)), 
                Text('${_localNames.length}명', style: const TextStyle(color: Color(0xFF6241D9), fontSize: 13, fontWeight: FontWeight.w600)), 
              ],
            ),
            const SizedBox(height: 12), 
            Expanded( 
              child: ListView.builder(
                itemCount: _localNames.length,
                itemBuilder: (context, index) {
                  final name = _localNames[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))), 
                    child: Row( 
                      children: [
                        const CircleAvatar(radius: 14, backgroundColor: Color(0xFFCBD5E1), child: Icon(Icons.person, color: Colors.white, size: 14)), 
                        const SizedBox(width: 12), 
                        Text(name, style: const TextStyle(color: Color(0xFF1E2939), fontSize: 14, fontWeight: FontWeight.w600)), 
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _localNames.removeAt(index);
                              _localIds.removeAt(index);
                              if (_nameController.text == _defaultRoomName || _nameController.text.trim().isEmpty) {
                                _defaultRoomName = _localNames.isEmpty ? "이름 없는 대화방" : _localNames.join(', ');
                                _nameController.text = _defaultRoomName;
                              }
                            });
                          },
                          child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
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
                width: double.infinity, height: 52, 
                child: ElevatedButton( 
                  onPressed: _isCreating || _localIds.isEmpty ? null : _createNewChatRoom, 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6241D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), 
                  child: _isCreating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('채팅방 생성', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)), 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}