import 'package:flutter/material.dart';

class ChatDetailVoteScreen extends StatefulWidget {
  const ChatDetailVoteScreen({super.key});

  @override
  State<ChatDetailVoteScreen> createState() => _ChatDetailVoteScreenState();
}

class _ChatDetailVoteScreenState extends State<ChatDetailVoteScreen> {
  int _expandedIndex = 1; // 피그마 시안처럼 2번째(액티비티 코스)가 기본으로 열려있도록 세팅

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('상세보기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('제주 여행 일정 투표', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            Text('선호하는 여행 일정을 선택해주세요', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 25),
            _buildVoteCard(0, '힐링 제주 여행', '3표'),
            const SizedBox(height: 15),
            _buildVoteCard(1, '액티비티 제주 여행', '1표', showTimeline: true),
            const SizedBox(height: 15),
            _buildVoteCard(2, '자연 탐방 제주 여행', '2표'),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteCard(int index, String title, String votes, {bool showTimeline = false}) {
    bool isExpanded = _expandedIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black),
            onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildMetaRow(Icons.calendar_today_outlined, '2박 3일'),
                  _buildMetaRow(Icons.location_on_outlined, '제주시 → 서귀포 → 우도'),
                  _buildMetaRow(Icons.access_time, '해양 스포츠, 액티비티, 테마파크'),
                  if (showTimeline) ...[
                    const Divider(height: 30),
                    _buildTimelineSegment('1일차 - 제주 도착 & 해양 스포츠', [
                      {'time': '09:00', 'title': '제주 공항 도착'},
                      {'time': '10:30', 'title': '협재 해수욕장 스노클링'},
                      {'time': '13:00', 'title': '패들보드 체험'},
                      {'time': '15:30', 'title': '애월 해안도로 드라이브'},
                      {'time': '17:00', 'title': '숙소 체크인 (애월)'},
                    ], 1),
                    const SizedBox(height: 15),
                    _buildTimelineSegment('2일차 - 액티비티 & 테마파크', [
                      {'time': '09:00', 'title': '제주 ATV 체험'},
                      {'time': '11:30', 'title': '짚라인 어드벤처'},
                      {'time': '13:00', 'title': '점심 식사'},
                      {'time': '15:00', 'title': '제주 테디베어 박물관'},
                      {'time': '17:30', 'title': '협재 해변 석양 감상'},
                    ], 2),
                    const SizedBox(height: 15),
                    _buildTimelineSegment('3일차 - 서핑 & 출발', [
                      {'time': '10:00', 'title': '제주 카페에서 브런치'},
                      {'time': '14:00', 'title': '공항 면세점 쇼핑'},
                      {'time': '19:00', 'title': '제주 공항 출발'},
                    ], 3),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 득표', style: TextStyle(color: Colors.black)),
                      Text(votes, style: const TextStyle(color: Color(0xFF7145D0), fontWeight: FontWeight.bold))
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F2F6),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('이 일정에 투표하기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTimelineSegment(String dayTitle, List<Map<String, String>> items, int dayNum) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: const Color(0xFF925DFB), child: Text('$dayNum', style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 10),
            Text(dayTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 11.0),
          child: Container(
            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFB387FE), width: 2))),
            child: Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
                child: Row(
                  children: [
                    Text(item['time']!, style: const TextStyle(color: Color(0xFF925DFB), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 15),
                    Text(item['title']!, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                  ],
                ),
              )).toList(),
            ),
          ),
        )
      ],
    );
  }
}