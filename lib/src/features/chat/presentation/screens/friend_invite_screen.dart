import 'package:flutter/material.dart';

class FriendInviteScreen extends StatefulWidget {
  const FriendInviteScreen({super.key});

  @override
  State<FriendInviteScreen> createState() => _FriendInviteScreenState();
}

class _FriendInviteScreenState extends State<FriendInviteScreen> {
  // 피그마 시안 데이터셋 구성 (초대 상태 플래그 분리)
  final List<Map<String, dynamic>> _friends = [
    {'name': '김민수', 'isInvited': false},
    {'name': '이지은', 'isInvited': false},
    {'name': '박서준', 'isInvited': true}, // 피그마 규격: 초대됨
    {'name': '최유진', 'isInvited': false},
    {'name': '정다은', 'isInvited': false},
    {'name': '강민호', 'isInvited': false},
    {'name': '윤서아', 'isInvited': true}, // 피그마 규격: 초대됨
    {'name': '한지훈', 'isInvited': false},
  ];

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
            title: const Text('친구 초대', style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            centerTitle: true,
          ),
        ),
      ),
      body: Column(
        children: [
          // 피그마 알약 검색 인풋 박스 유닛
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.8))),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF999999), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(hintText: '친구 검색', hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 16, fontFamily: 'Inter'), border: InputBorder.none),
                    ),
                  )
                ],
              ),
            ),
          ),
          // 친구 리스트 스태킹
          Expanded(
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final item = _friends[index];
                bool isInvited = item['isInvited'];

                return Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.8))),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 24, backgroundColor: Color(0xFF925DFB)),
                          const SizedBox(width: 12),
                          Text(item['name'], style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Inter')),
                        ],
                      ),
                      // 피그마 상태 분기 버튼 매핑 (초대 / 초대됨)
                      GestureDetector(
                        onTap: isInvited ? null : () => setState(() => item['isInvited'] = true),
                        child: Container(
                          width: isInvited ? 78 : 65,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isInvited ? const Color(0xFFF5F5F5) : const Color(0xFF925DFB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isInvited ? '초대됨' : '초대',
                            style: TextStyle(color: isInvited ? const Color(0xFF999999) : Colors.white, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}