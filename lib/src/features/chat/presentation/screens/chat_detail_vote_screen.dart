import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';

class ChatDetailVoteScreen extends ConsumerStatefulWidget {
  final int voteId;

  const ChatDetailVoteScreen({super.key, required this.voteId});

  @override
  ConsumerState<ChatDetailVoteScreen> createState() => _ChatDetailVoteScreenState();
}

class _ChatDetailVoteScreenState extends ConsumerState<ChatDetailVoteScreen> {
  int _expandedIndex = 0; 
  Map<String, dynamic>? _voteDetail;
  bool _isLoading = true;
  bool _isActionLoading = false;

  String get _apiUrl {
    String base = AuthStorage.baseUrl.trim().replaceAll('\n', '').replaceAll('\r', '');
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!base.endsWith('/api/v1')) {
      base = '$base/api/v1';
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    _fetchVoteDetail();
  }

  Future<void> _fetchVoteDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/vote/${widget.voteId}'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _voteDetail = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('투표 상세 조회 에러: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _castVote(int snapshotId) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/vote/${widget.voteId}/cast'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({"snapshot_id": snapshotId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표가 정상적으로 반영되었습니다.')),
          );
        }
        await _fetchVoteDetail();
      } else {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '투표 처리 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('투표 행사 에러: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _finalizeVote() async {
    if (_isActionLoading) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('일정 최종 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        content: const Text(
          '최다 득표된 일정을 최종 여행 계획으로 확정하고 홈 화면 일정 탭에 등록하시겠습니까?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), fontFamily: 'Pretendard', height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF524582),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/vote/${widget.voteId}/finalize'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('여행 일정이 최종 확정되었습니다. 홈 화면의 일정 탭에서 확인하세요.')),
          );
          Navigator.pop(context, true); // 확정 플래그 반환
        }
      } else {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '확정 처리 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('최종 확정 에러: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final raw = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final intVal = int.tryParse(raw);
    if (intVal == null) return value.toString();
    return intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF524582))),
      );
    }

    final bool isActive = (_voteDetail?['status'] == 'active');
    final List<dynamic> snapshots = _voteDetail?['snapshots'] ?? [];
    final List<dynamic> results = _voteDetail?['results'] ?? [];

    final Map<int, int> voteCountMap = {};
    int totalVotesCount = 0;
    for (var r in results) {
      final int sId = int.tryParse(r['snapshot_id']?.toString() ?? '0') ?? 0;
      final int count = int.tryParse(r['vote_count']?.toString() ?? '0') ?? 0;
      if (sId > 0) {
        voteCountMap[sId] = count;
        totalVotesCount += count;
      }
    }

    final int? myVotedSnapshotId = int.tryParse(_voteDetail?['my_vote']?.toString() ?? '');
    final String mainTitle = snapshots.isNotEmpty ? (snapshots[0]['plan_title'] ?? '여행 일정 투표') : '여행 일정 투표';
    final String city = snapshots.isNotEmpty ? (snapshots[0]['city'] ?? '') : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('투표 상세보기', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Pretendard')),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _finalizeVote,
                child: const Text('일정 확정', style: TextStyle(color: Color(0xFF524582), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pretendard')),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (city.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text(city, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? '진행 중' : '투표 마감',
                          style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(mainTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.how_to_vote_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('총 $totalVotesCount명 투표 참여', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'Pretendard')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (snapshots.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('투표 가능한 일정 후보가 없습니다.', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard'))))
            else
              for (int i = 0; i < snapshots.length; i++) ...[
                _buildCandidateCard(
                  index: i,
                  snapshot: snapshots[i],
                  voteCount: voteCountMap[int.tryParse(snapshots[i]['snapshot_id']?.toString() ?? '') ?? 0] ?? 0,
                  totalVotes: totalVotesCount,
                  isMyVoted: myVotedSnapshotId == (int.tryParse(snapshots[i]['snapshot_id']?.toString() ?? '') ?? 0),
                  isActive: isActive,
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard({
    required int index,
    required dynamic snapshot,
    required int voteCount,
    required int totalVotes,
    required bool isMyVoted,
    required bool isActive,
  }) {
    bool isExpanded = _expandedIndex == index;
    final int snapshotId = int.tryParse(snapshot['snapshot_id']?.toString() ?? '0') ?? 0;
    final String title = snapshot['plan_title'] ?? '일정 후보 ${index + 1}';
    final List<dynamic> itineraries = snapshot['itinerary'] ?? [];
    final Map<String, dynamic> cost = snapshot['estimated_cost'] is Map ? snapshot['estimated_cost'] : {};

    final double ratio = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyVoted ? const Color(0xFF524582) : const Color(0xFFE2E8F0),
          width: isMyVoted ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isMyVoted ? const Color(0x14524582) : const Color(0x06000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMyVoted ? const Color(0xFF524582) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '후보 ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMyVoted ? Colors.white : const Color(0xFF475569),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMyVoted)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                    child: const Text('내 선택', style: TextStyle(color: Color(0xFF524582), fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                  ),
              ],
            ),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF64748B)),
            onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 💡 1일차/2일차 핑 연결 없는 정갈한 타임라인
                  if (itineraries.isNotEmpty) ...[
                    for (int dayIdx = 0; dayIdx < itineraries.length; dayIdx++) ...[
                      _buildCleanDaySection(dayIdx + 1, itineraries[dayIdx]),
                      if (dayIdx < itineraries.length - 1) const SizedBox(height: 16),
                    ],
                  ] else
                    const Text('등록된 일정이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontFamily: 'Pretendard')),
                  
                  // 경비 내역 카드
                  if (cost.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEDE9FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('예상 경비 내역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF524582), fontFamily: 'Pretendard')),
                          const SizedBox(height: 6),
                          _buildCostRow('교통비', '${_formatCurrency(cost['transportation'])}원'),
                          _buildCostRow('숙박비', '${_formatCurrency(cost['accommodation'])}원'),
                          _buildCostRow('식비', '${_formatCurrency(cost['meals'])}원'),
                          _buildCostRow('액티비티', '${_formatCurrency(cost['activities'])}원'),
                          const Divider(height: 12, color: Color(0xFFE2E8F0)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('총 합계', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard')),
                              Text('${_formatCurrency(cost['total'])}원', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF524582), fontFamily: 'Pretendard')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 득표수', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontFamily: 'Pretendard')),
                      Text('$voteCount표 (${(ratio * 100).toInt()}%)', style: const TextStyle(color: Color(0xFF524582), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pretendard')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF524582)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (isActive)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: isMyVoted ? null : () => _castVote(snapshotId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF524582),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isMyVoted ? '투표 완료된 일정' : '이 일정에 투표하기',
                          style: TextStyle(
                            color: isMyVoted ? const Color(0xFF94A3B8) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Pretendard')),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155), fontFamily: 'Pretendard')),
        ],
      ),
    );
  }

  // 💡 1일차/2일차 헤더는 독립된 칩으로 표시하고, 내부 실제 일정 줄에만 핑 연결
  Widget _buildCleanDaySection(int dayNum, dynamic dayData) {
    final String dayStr = dayData.toString().trim();
    final List<String> lines = dayStr.split('\n');
    final List<Map<String, dynamic>> validActivities = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // '1일차', '[1일차 - ...]' 같은 헤더 제목 줄은 타임라인 노드에서 제외
      if (trimmed.startsWith('[') && trimmed.contains('일차')) continue;
      if (trimmed.contains('${dayNum}일차') && trimmed.length < 15) continue;

      final timeRegex = RegExp(r'^(\d{2}:\d{2}(?:\s*(?:~|-|→|->)\s*\d{2}:\d{2})?|\d{2}:\d{2})\s*(.*)');
      final match = timeRegex.firstMatch(trimmed);

      String time = '';
      String text = trimmed;
      if (match != null) {
        time = match.group(1) ?? '';
        text = match.group(2) ?? '';
      }

      IconData icon = Icons.place_rounded;
      Color iconColor = const Color(0xFF524582);

      final lower = text.toLowerCase();
      final bool isTransit = text.contains('→') || text.contains('->') || lower.contains('이동') || lower.contains('탑승');
      if (isTransit) {
        icon = Icons.directions_car_rounded;
        iconColor = const Color(0xFF367BC3);
      } else if (lower.contains('식사') || lower.contains('맛집') || lower.contains('점심') || lower.contains('저녁') || lower.contains('식당')) {
        icon = Icons.restaurant_rounded;
        iconColor = const Color(0xFF38BFA7);
      } else if (lower.contains('카페') || lower.contains('커피') || lower.contains('디저트')) {
        icon = Icons.local_cafe_rounded;
        iconColor = const Color(0xFF38BFA7);
      } else if (lower.contains('호텔') || lower.contains('숙소') || lower.contains('체크인') || lower.contains('펜션')) {
        icon = Icons.hotel_rounded;
        iconColor = const Color(0xFF10B981);
      }

      validActivities.add({
        'time': time,
        'text': text,
        'icon': icon,
        'color': iconColor,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 독립된 일차 헤더 칩 (핑 연결 없음)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF524582),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$dayNum일차', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        ),
        const SizedBox(height: 10),
        // 실제 일정 아이템들만 타임라인으로 연결
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            children: [
              for (int idx = 0; idx < validActivities.length; idx++)
                _buildTimelineNode(validActivities[idx], idx == validActivities.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineNode(Map<String, dynamic> item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, size: 12, color: item['color'] as Color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['time'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['time'],
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569), fontFamily: 'Pretendard'),
                      ),
                    ),
                  Text(
                    item['text'],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.35, fontFamily: 'Pretendard'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}