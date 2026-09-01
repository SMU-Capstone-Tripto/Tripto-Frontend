import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_detail_vote_screen.dart';

class VoteTabsScreen extends StatefulWidget {
  final int initialTabIndex;
  final int? roomId;

  const VoteTabsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.roomId,
  });

  @override
  State<VoteTabsScreen> createState() => _VoteTabsScreenState();
}

class _VoteTabsScreenState extends State<VoteTabsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _ongoingVotes = [];
  List<dynamic> _completedVotes = [];
  bool _isLoading = true;

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() => setState(() {}));
    _fetchAllVotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? _extractRoomId(dynamic v) {
    if (v is! Map) return null;
    final dynamic raw = v['room_id'] ??
        v['chat_room_id'] ??
        v['roomId'] ??
        v['chatroom_id'] ??
        v['chat_id'] ??
        (v['room'] is Map ? (v['room']['id'] ?? v['room']['room_id']) : null);
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  List<dynamic> _filterByRoom(List<dynamic> list) {
    if (widget.roomId == null || widget.roomId! <= 0) return list;

    final bool hasAnyRoomId = list.any((v) => _extractRoomId(v) != null);
    if (!hasAnyRoomId) return list;

    return list.where((v) {
      final int? rId = _extractRoomId(v);
      if (rId != null) return rId == widget.roomId;
      return true;
    }).toList();
  }

  Future<void> _fetchAllVotes() async {
    setState(() => _isLoading = true);

    List<dynamic> activeList = [];
    List<dynamic> finalizedList = [];

    // 💡 room_id 쿼리 파라미터 구성
    final String roomQuery = (widget.roomId != null && widget.roomId! > 0)
        ? '?room_id=${widget.roomId}'
        : '';

    // 1. 진행 중인 투표 조회 (GET /vote/active?room_id=...)
    try {
      final resActive = await http.get(
        Uri.parse('$_apiUrl/vote/active$roomQuery'),
        headers: AuthStorage.authHeaders,
      );
      if (resActive.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resActive.bodyBytes));
        if (decoded is List) {
          activeList = decoded;
        } else if (decoded is Map) {
          activeList = decoded['votes'] ?? decoded['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('진행 중인 투표 로드 에러: $e');
    }

    // 2. 완료된 투표 조회 (GET /vote/finalized?room_id=...)
    try {
      final resFinalized = await http.get(
        Uri.parse('$_apiUrl/vote/finalized$roomQuery'),
        headers: AuthStorage.authHeaders,
      );
      if (resFinalized.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resFinalized.bodyBytes));
        if (decoded is List) {
          finalizedList = decoded;
        } else if (decoded is Map) {
          finalizedList = decoded['votes'] ?? decoded['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('완료된 투표 로드 에러: $e');
    }

    // 3. 방 필터링 및 최신순 정렬
    activeList = _filterByRoom(activeList);
    finalizedList = _filterByRoom(finalizedList);

    activeList.sort((a, b) {
      final int aId = int.tryParse(a['vote_id']?.toString() ?? '0') ?? 0;
      final int bId = int.tryParse(b['vote_id']?.toString() ?? '0') ?? 0;
      return bId.compareTo(aId);
    });

    finalizedList.sort((a, b) {
      final int aId = int.tryParse(a['vote_id']?.toString() ?? '0') ?? 0;
      final int bId = int.tryParse(b['vote_id']?.toString() ?? '0') ?? 0;
      return bId.compareTo(aId);
    });

    if (mounted) {
      setState(() {
        _ongoingVotes = activeList;
        _completedVotes = finalizedList;
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      return '${dt.month}월 ${dt.day}일 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  int _calculateTotalParticipants(dynamic vote) {
    if (vote['results'] is List) {
      int sum = 0;
      for (var r in vote['results']) {
        sum += int.tryParse(r['vote_count']?.toString() ?? '0') ?? 0;
      }
      return sum;
    }
    return int.tryParse(vote['total_votes']?.toString() ?? vote['participant_count']?.toString() ?? '0') ?? 0;
  }

  String _extractTitle(dynamic vote) {
    if (vote['plan_title'] != null && vote['plan_title'].toString().isNotEmpty) {
      return vote['plan_title'].toString();
    }
    if (vote['title'] != null && vote['title'].toString().isNotEmpty) {
      return vote['title'].toString();
    }
    if (vote['snapshots'] is List && (vote['snapshots'] as List).isNotEmpty) {
      final firstSnapshot = vote['snapshots'][0];
      if (firstSnapshot is Map && firstSnapshot['plan_title'] != null) {
        return firstSnapshot['plan_title'].toString();
      }
    }
    return '여행 일정 투표';
  }

  void _onVoteItemTapped(dynamic vote) {
    final int voteId = int.tryParse(vote['vote_id']?.toString() ?? '0') ?? 0;
    if (voteId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailVoteScreen(voteId: voteId),
      ),
    ).then((result) {
      // 💡 확정되었을 때만 완료 탭으로 이동, 삭제나 일반 뒤로가기 시에는 현재 탭 유지
      if (result == 'finalized') {
        _tabController.animateTo(1);
      }
      _fetchAllVotes(); // 목록 최신화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(105),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  '투표',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF524582),
                indicatorWeight: 2.5,
                labelColor: const Color(0xFF524582),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontSize: 14.5, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                tabs: const [Tab(text: '진행중인 투표'), Tab(text: '완료한 투표')],
              )
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF524582)))
          : RefreshIndicator(
              color: const Color(0xFF524582),
              onRefresh: _fetchAllVotes,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVoteList(_ongoingVotes, isOngoing: true),
                  _buildVoteList(_completedVotes, isOngoing: false),
                ],
              ),
            ),
    );
  }

  Widget _buildVoteList(List<dynamic> votes, {required bool isOngoing}) {
    if (votes.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Text(
              isOngoing ? '진행 중인 투표가 없습니다.' : '완료된 투표가 없습니다.',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: votes.length,
      itemBuilder: (context, index) {
        final vote = votes[index];
        final String title = _extractTitle(vote);
        final String createdAtStr = _formatDate(vote['created_at']);
        final int totalVotes = _calculateTotalParticipants(vote);
        final bool isLatest = index == 0 && isOngoing;

        return GestureDetector(
          onTap: () => _onVoteItemTapped(vote),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLatest ? const Color(0xFF524582).withOpacity(0.35) : const Color(0xFFE2E8F0),
                width: isLatest ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLatest ? const Color(0x0F524582) : const Color(0x06000000),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLatest)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF524582),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '최신',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                        ),
                      ),
                    const Spacer(),
                    if (createdAtStr.isNotEmpty)
                      Text(
                        createdAtStr,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Pretendard'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '총 $totalVotes명 참여${isOngoing ? "" : " · 완료"}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}