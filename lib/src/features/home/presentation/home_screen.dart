import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 복사 기능을 위해 필수 추가
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../src/core/auth_storage.dart'; // 기존 토큰 및 baseUrl 저장소 연동

// ── 🛠️ 상대 경로 임포트 (컴파일 에러 시 이 줄을 지우고 Quick Fix로 임포트하세요) ──
import '../../friends/presentation/friend_request_screen.dart'; 

// ── 백엔드 규격 표준 도메인 모델 정의 ──

class TravelModel {
  final int travelId;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  TravelModel({
    required this.travelId,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  factory TravelModel.fromJson(Map<String, dynamic> json) {
    return TravelModel(
      travelId: json['travel_id'],
      title: json['title'],
      destination: json['destination'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  int get dDay {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return startDate.difference(today).inDays;
  }

  String get dateRangeLabel {
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${fmt(startDate)} – ${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
  }
}

class FriendHomeModel {
  final int friendshipId;
  final int friendId;
  final String nickname;
  final String statusMessage;
  final String avatarColor;

  FriendHomeModel({
    required this.friendshipId,
    required this.friendId,
    required this.nickname,
    required this.statusMessage,
    required this.avatarColor,
  });

  factory FriendHomeModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return FriendHomeModel(
      friendshipId: json['friendship_id'] ?? 0,
      friendId: user['friend_id'] ?? 0,
      nickname: user['nickname'] ?? '이름없음',
      statusMessage: user['status_message'] ?? '',
      avatarColor: user['avatar_color'] ?? '#8777F2',
    );
  }

  String get avatarLabel =>
      nickname.length >= 2 ? nickname.substring(0, 2) : nickname;
}

// ── HomeScreen 실시간 비동기 연동 위젯 ──

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _myNickname = '여행자';
  String _myUniqueId = ''; 
  TravelModel? _nextTrip;
  List<FriendHomeModel> _friends = [];
  double _addBtnScale = 1.0; 

  @override
  void initState() {
    super.initState();
    _fetchHomeMasterData();
  }

  Future<void> _fetchHomeMasterData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final meRes = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/auth/me'), 
        headers: AuthStorage.authHeaders,
      );

      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body);
        _myNickname = meData['nickname'] ?? '여행자';
        _myUniqueId = meData['unique_id'] ?? ''; 
        final int myUserId = meData['user_id'];

        final travelRes = await http.get(
          Uri.parse('${AuthStorage.baseUrl}/travels?owner_id=$myUserId'), 
          headers: AuthStorage.authHeaders,
        );

        if (travelRes.statusCode == 200) {
          final List<dynamic> travelList = jsonDecode(travelRes.body);
          final parsedTrips = travelList.map((json) => TravelModel.fromJson(json)).toList();
          
          final now = DateTime.now();
          final futureTrips = parsedTrips.where((t) => t.startDate.isAfter(now) || t.startDate.day == now.day).toList();
          if (futureTrips.isNotEmpty) {
            futureTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
            _nextTrip = futureTrips.first;
          }
        }
      }

      final friendRes = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/friends/list'), 
        headers: AuthStorage.authHeaders,
      );

      if (friendRes.statusCode == 200) {
        final List<dynamic> friendList = jsonDecode(friendRes.body);
        setState(() {
          _friends = friendList.map((json) => FriendHomeModel.fromJson(json)).toList();
        });
      }

    } catch (e) {
      debugPrint('홈 실시간 데이터 수집 연동 에러: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToNotificationRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FriendRequestScreen()),
    );
    _fetchHomeMasterData(); 
  }

  void _openAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddFriendDialog(
        myUniqueId: _myUniqueId,
        onSuccess: _fetchHomeMasterData, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB), 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4E48AF)))
          : RefreshIndicator(
              onRefresh: _fetchHomeMasterData,
              color: const Color(0xFF4E48AF),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      nickname: _myNickname, 
                      trip: _nextTrip,
                      onNotificationTap: _navigateToNotificationRequests,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people_alt_rounded, color: Color(0xFF4E48AF), size: 20),
                              SizedBox(width: 8),
                              Text('친구 목록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E2939), letterSpacing: -0.3)),
                            ],
                          ),
                          
                          // ── 🎨 럭셔리 리디자인한 친구 추가 액션 버튼 ──
                          GestureDetector(
                            onTapDown: (_) => setState(() => _addBtnScale = 0.92),
                            onTapUp: (_) => setState(() => _addBtnScale = 1.0),
                            onTapCancel: () => setState(() => _addBtnScale = 1.0),
                            onTap: _openAddFriendDialog,
                            child: AnimatedScale(
                              scale: _addBtnScale,
                              duration: const Duration(milliseconds: 100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5A4FE3), Color(0xFF894FFF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20), // 부드러운 둥근 캡슐형태
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A4FE3).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text('친구 추가', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.2)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: _friends.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text('등록된 친구가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                            ),
                          )
                        : SliverList.builder(
                            itemCount: _friends.length,
                            itemBuilder: (context, index) => _FriendListItemWidget(
                              friend: _friends[index],
                              onRefreshRequired: _fetchHomeMasterData,
                            ),
                          ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              ),
            ),
    );
  }
}

// ── 친구 추가 커스텀 다이얼로그 ──

class _AddFriendDialog extends StatefulWidget {
  final String myUniqueId;
  final VoidCallback onSuccess;

  const _AddFriendDialog({required this.myUniqueId, required this.onSuccess});

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isSending = false;
  double _btnScale = 1.0;

  String? _searchedNickname;
  String? _searchedUniqueId;
  String? _errorText;

  Future<void> _searchUser() async {
    final targetId = _searchController.text.trim();
    if (targetId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorText = null;
      _searchedNickname = null;
      _searchedUniqueId = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/friends/search/$targetId'), 
        headers: AuthStorage.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchedNickname = data['nickname'];
          _searchedUniqueId = data['friend_unique_id'];
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _errorText = err['detail'] ?? '사용자를 찾을 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() => _errorText = '서버 통신 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_searchedUniqueId == null) return;

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/friends/request'), 
        headers: AuthStorage.authHeaders,
        body: jsonEncode({'friend_unique_id': _searchedUniqueId}), 
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_searchedNickname님에게 친구 요청을 보냈습니다.')),
        );
        widget.onSuccess(); 
        Navigator.pop(context); 
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['detail'] ?? '요청 발송에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('통신 실패 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white, 
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('친구 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2939))),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey, size: 20)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('나의 고유 ID : ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text(widget.myUniqueId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4E48AF), letterSpacing: 0.5)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.myUniqueId));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('고유 ID가 클립보드에 복사되었습니다.')));
                    },
                    child: const Icon(Icons.copy, size: 16, color: Color(0xFF4E48AF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(hintText: '친구 고유 ID 6자리 입력', hintStyle: TextStyle(color: Colors.black26, fontSize: 13), border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchUser,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4E48AF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('검색', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_searchedNickname != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDDD6FE))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: const Color(0xFF4E48AF), child: Text(_searchedNickname!.substring(0, _searchedNickname!.length >= 2 ? 2 : 1), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_searchedNickname!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E2939))),
                        const SizedBox(height: 2),
                        Text('ID: $_searchedUniqueId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) => setState(() => _btnScale = 0.96),
                onTapUp: (_) => setState(() => _btnScale = 1.0),
                onTapCancel: () => setState(() => _btnScale = 1.0),
                onTap: _isSending ? null : _sendFriendRequest,
                child: AnimatedScale(
                  scale: _btnScale,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4E48AF), Color(0xFFB387FE)]), 
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: const Color(0xFF4E48AF).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Center(
                      child: _isSending 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('친구 요청 보내기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ],
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 상단 헤더 컴포넌트 위젯 ──

class _HomeHeader extends StatelessWidget {
  final String nickname;
  final TravelModel? trip;
  final VoidCallback onNotificationTap; 

  const _HomeHeader({
    required this.nickname, 
    this.trip, 
    required this.onNotificationTap, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4E48AF),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tripto', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5, fontFamily: 'Pretendard')),
                  const SizedBox(height: 4),
                  Text('안녕하세요, $nickname님!', style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Pretendard')),
                ],
              ),
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.14), shape: const CircleBorder()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('다가오는 여행', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 0.8, fontFamily: 'Pretendard')),
          const SizedBox(height: 10),
          trip != null ? _TripCardWidget(trip: trip!) : const _EmptyTripCard(),
        ],
      ),
    );
  }
}

// ── 소형 서브 컴포넌트 위젯 분리 구현 ──

class _TripCardWidget extends StatelessWidget {
  final TravelModel trip;
  const _TripCardWidget({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Next Trip', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                child: Text(trip.dDay == 0 ? 'D-Day' : 'D-${trip.dDay}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(trip.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Pretendard')),
          const SizedBox(height: 8),
          Row(
            children: [
              _metaItem(Icons.calendar_today_outlined, trip.dateRangeLabel),
              const SizedBox(width: 12),
              _metaItem(Icons.location_on_outlined, trip.destination),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () { /* TODO: 일정 상세 라우팅 연동 */ },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                backgroundColor: Colors.white.withOpacity(0.22),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('일정 보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.75)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
      ],
    );
  }
}

class _EmptyTripCard extends StatelessWidget {
  const _EmptyTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.flight_takeoff_outlined, color: Colors.white54, size: 32),
          SizedBox(height: 8),
          Text('예정된 여행이 없어요', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FriendListItemWidget extends StatelessWidget {
  final FriendHomeModel friend;
  final VoidCallback onRefreshRequired; 

  const _FriendListItemWidget({
    required this.friend,
    required this.onRefreshRequired,
  });

  Color _parseColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF8777F2);
    }
  }

  void _showFriendManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('${friend.nickname}님 관리', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E2939))),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.redAccent),
              title: const Text('친구 삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx); 
                await _deleteFriendAction(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('취소', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  /// 🛠️ 친구 삭제 실패 원인을 1초 만에 알 수 있도록 실시간 디버그 로그 출력 탑재
  Future<void> _deleteFriendAction(BuildContext context) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthStorage.baseUrl}/friends/${friend.friendshipId}'), 
        headers: AuthStorage.authHeaders,
      );

      // ★ 내일 에러 분석용 로그 콘솔 출력
      debugPrint("★ 친구삭제 응답코드: ${response.statusCode}");
      debugPrint("★ 친구삭제 응답본문: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friend.nickname}님이 친구 목록에서 삭제되었습니다.')),
        );
        onRefreshRequired(); 
      } else {
        // 실패 메시지에 서버 상태 코드를 노출시켜 직관성을 높입니다.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 삭제 처리에 실패했습니다. (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 통신 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBg = _parseColor(friend.avatarColor);
    final avatarText = avatarBg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: avatarBg,
          child: Text(friend.avatarLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: avatarText)),
        ),
        title: Text(friend.nickname, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E2939))),
        trailing: IconButton(
          onPressed: () => _showFriendManagementSheet(context), 
          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 18),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC), shape: const CircleBorder()),
        ),
      ),
    );
  }
}