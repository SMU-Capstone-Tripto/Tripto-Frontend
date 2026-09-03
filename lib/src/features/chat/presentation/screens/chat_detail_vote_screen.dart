import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/schedule/domain/travel_model.dart';
import 'package:tripto/src/features/schedule/domain/schedule_model.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_provider.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_detail_provider.dart';
import 'package:tripto/src/features/schedule/presentation/screens/schedule_detail_screen.dart';

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
  String? _errorMessage;

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

  // 💡 투표 상세 조회 및 방어 로직 (에러/래퍼 처리)
  Future<void> _fetchVoteDetail({bool updateLoadingState = true}) async {
    if (updateLoadingState) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/vote/${widget.voteId}'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        // 응답 래퍼 방어 unwrap
        if (data is Map && data.containsKey('data') && data['data'] is Map) {
          data = data['data'];
        } else if (data is Map && data.containsKey('vote') && data['vote'] is Map) {
          data = data['vote'];
        }

        if (mounted) {
          setState(() {
            _voteDetail = data as Map<String, dynamic>;
            _errorMessage = null;
          });
        }
      } else {
        String detailMsg = '투표 정보를 불러오지 못했습니다. (코드: ${response.statusCode})';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err['detail'] != null) detailMsg = err['detail'].toString();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _errorMessage = detailMsg;
          });
        }
      }
    } catch (e) {
      debugPrint('투표 상세 조회 에러: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '네트워크 연결 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (updateLoadingState && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 1. 투표 참여 (POST)
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
        await _fetchVoteDetail(updateLoadingState: false);
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

  // 2. 투표 변경 (PUT)
  Future<void> _changeVote(int snapshotId) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/vote/${widget.voteId}/cast'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({"snapshot_id": snapshotId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표 선택이 변경되었습니다.')),
          );
        }
        await _fetchVoteDetail(updateLoadingState: false);
      } else {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '투표 변경 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('투표 변경 에러: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // 3. 투표 삭제 (DELETE)
  Future<void> _deleteVote() async {
    if (_isActionLoading) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '투표 삭제',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
        ),
        content: const Text(
          '정말 투표를 삭제하시겠습니까? 삭제 시 모든 투표 기록이 삭제되며 채팅방 멤버들에게 삭제 알림이 전달됩니다.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), fontFamily: 'Pretendard', height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/vote/${widget.voteId}'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표가 삭제되었습니다.')),
          );
          Navigator.pop(context, 'deleted');
        }
      } else {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '투표 삭제 권한이 없거나 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      debugPrint('투표 삭제 에러: $e');
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // 최다 득표 동점 판별 및 분기
  void _finalizeVote() {
    if (_isActionLoading) return;

    final List<dynamic> snapshots = _voteDetail?['snapshots'] ?? [];
    final List<dynamic> results = _voteDetail?['results'] ?? [];

    if (snapshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('확정할 일정 후보가 없습니다.')),
      );
      return;
    }

    final Map<int, int> voteCountMap = {};
    for (var r in results) {
      final int sId = int.tryParse(r['snapshot_id']?.toString() ?? '0') ?? 0;
      final int count = int.tryParse(r['vote_count']?.toString() ?? '0') ?? 0;
      if (sId > 0) voteCountMap[sId] = count;
    }

    int maxVotes = -1;
    for (var s in snapshots) {
      final int sId = int.tryParse(s['snapshot_id']?.toString() ?? '0') ?? 0;
      final int count = voteCountMap[sId] ?? 0;
      if (count > maxVotes) {
        maxVotes = count;
      }
    }

    final List<dynamic> winningCandidates = snapshots.where((s) {
      final int sId = int.tryParse(s['snapshot_id']?.toString() ?? '0') ?? 0;
      final int count = voteCountMap[sId] ?? 0;
      return count == maxVotes;
    }).toList();

    // 동점인 경우 방장 선택 바텀시트, 단독 1위인 경우 바로 확인 다이얼로그
    if (winningCandidates.length > 1) {
      _showTieBreakerBottomSheet(winningCandidates, voteCountMap);
    } else {
      final singleWinner = winningCandidates.first;
      final int winnerSnapId = int.tryParse(singleWinner['snapshot_id']?.toString() ?? '0') ?? 0;
      _showSingleWinnerDialog(singleWinner, winnerSnapId);
    }
  }

  void _showSingleWinnerDialog(dynamic winnerSnapshot, int winnerSnapId) {
    final String title = winnerSnapshot['plan_title'] ?? '일정';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('일정 최종 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        content: Text(
          '최다 득표된 [$title] 일정을 최종 확정하시겠습니까?\n모든 멤버의 여행 탭에 자동 등록됩니다.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), fontFamily: 'Pretendard', height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF524582),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeFinalize(winningSnapshotId: winnerSnapId > 0 ? winnerSnapId : null);
            },
            child: const Text('확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          ),
        ],
      ),
    );
  }

  void _showTieBreakerBottomSheet(List<dynamic> tiedCandidates, Map<int, int> voteCountMap) {
    final List<dynamic> snapshots = _voteDetail?['snapshots'] ?? [];
    int selectedSnapshotId = int.tryParse(tiedCandidates.first['snapshot_id']?.toString() ?? '0') ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.how_to_vote_rounded, color: Color(0xFF524582), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '동점 일정 최종 선택',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '최다 득표 일정이 동점입니다. 최종 일정으로 확정할 후보를 하나 선택해 주세요.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Pretendard'),
                  ),
                  const SizedBox(height: 18),
                  ...tiedCandidates.map((candidate) {
                    final int snapId = int.tryParse(candidate['snapshot_id']?.toString() ?? '0') ?? 0;
                    final int originalIdx = snapshots.indexOf(candidate);
                    final String title = candidate['plan_title'] ?? '후보 ${originalIdx + 1}';
                    final int votes = voteCountMap[snapId] ?? 0;
                    final bool isSelected = (selectedSnapshotId == snapId);

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedSnapshotId = snapId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF524582) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFF524582) : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '후보 ${originalIdx + 1}. $title',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$votes표 득표',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Pretendard'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF524582),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _executeFinalize(winningSnapshotId: selectedSnapshotId);
                      },
                      child: const Text(
                        '이 일정으로 최종 확정하기',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Pretendard'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 💡 백엔드 finalize API 호출 (winner_snapshot_id 키 전송) 및 일정 탭 이동
  Future<void> _executeFinalize({int? winningSnapshotId}) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final Map<String, dynamic> bodyData = {};
      if (winningSnapshotId != null && winningSnapshotId > 0) {
        // 백엔드 Pydantic 필드명 일치
        bodyData["winner_snapshot_id"] = winningSnapshotId;
        bodyData["winning_snapshot_id"] = winningSnapshotId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/vote/${widget.voteId}/finalize'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic responseData;
        try {
          responseData = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}

        final List<dynamic> snapshots = _voteDetail?['snapshots'] ?? [];
        dynamic winningSnapshot;

        final int? targetWinnerId = int.tryParse(
          responseData?['winner_snapshot_id']?.toString() ??
          responseData?['winning_snapshot_id']?.toString() ??
          winningSnapshotId?.toString() ??
          _voteDetail?['winner_snapshot_id']?.toString() ?? '',
        );

        if (targetWinnerId != null && targetWinnerId > 0) {
          winningSnapshot = snapshots.firstWhere(
            (s) => int.tryParse(s['snapshot_id']?.toString() ?? '') == targetWinnerId,
            orElse: () => snapshots.isNotEmpty ? snapshots[0] : null,
          );
        } else if (snapshots.isNotEmpty) {
          winningSnapshot = snapshots[0];
        }

        if (winningSnapshot != null) {
          final int travelId = int.tryParse(
            responseData?['travel_id']?.toString() ??
            winningSnapshot['snapshot_id']?.toString() ??
            widget.voteId.toString(),
          ) ?? widget.voteId;

          final String title = winningSnapshot['plan_title'] ?? '최종 확정된 여행';
          final String city = winningSnapshot['city'] ?? '국내';

          DateTime startDate = DateTime.now().add(const Duration(days: 7));
          DateTime endDate = startDate.add(const Duration(days: 2));

          if (winningSnapshot['traveldates'] != null) {
            try {
              final dates = winningSnapshot['traveldates'].toString().split('~');
              if (dates.length == 2) {
                startDate = DateTime.parse(dates[0].trim());
                endDate = DateTime.parse(dates[1].trim());
              }
            } catch (_) {}
          }

          final createdTravel = TravelModel(
            travel_id: travelId,
            owner_id: int.tryParse(_voteDetail?['creator_id']?.toString() ?? '1') ?? 1,
            title: title,
            destination: city,
            start_date: startDate,
            end_date: endDate,
            status: TripStatus.upcoming,
          );

          final parsedSchedules = _parseSnapshotToSchedules(winningSnapshot);
          ref.read(scheduleProvider.notifier).setSchedules(
            parsedSchedules,
            travelId: travelId.toString(),
          );
          ref.read(selectedDayProvider.notifier).state = 1;

          // 여행 목록 새로고침
          ref.invalidate(travelsProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('여행 일정이 최종 확정되었습니다! 여행 탭에 등록됩니다.')),
            );

            // 확정된 일정의 상세 화면으로 교체 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleDetailScreen(schedule: createdTravel),
              ),
              result: 'finalized',
            );
          }
        } else {
          if (mounted) {
            Navigator.pop(context, 'finalized');
          }
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

  ScheduleType _detectCategory(String text) {
    final lower = text.toLowerCase();
    if (text.contains('→') || text.contains('->') || lower.contains('이동') || lower.contains('탑승') || lower.contains('도착') || lower.contains('출발') || lower.contains('공항') || lower.contains('역')) {
      return ScheduleType.move;
    } else if (lower.contains('식사') || lower.contains('맛집') || lower.contains('점심') || lower.contains('저녁') || lower.contains('아침') || lower.contains('식당') || lower.contains('카페') || lower.contains('커피') || lower.contains('디저트') || lower.contains('브런치') || lower.contains('베이커리')) {
      return ScheduleType.eat;
    } else if (lower.contains('호텔') || lower.contains('숙소') || lower.contains('체크인') || lower.contains('체크아웃') || lower.contains('펜션') || lower.contains('리조트') || lower.contains('게스트하우스') || lower.contains('민박')) {
      return ScheduleType.stay;
    }
    return ScheduleType.activity;
  }

  List<ScheduleModel> _parseSnapshotToSchedules(dynamic snapshot) {
    final List<ScheduleModel> schedules = [];
    final List<dynamic> itineraries = snapshot['itinerary'] ?? snapshot['schedules'] ?? snapshot['activities'] ?? [];

    int globalCounter = 1;
    final List<String> defaultTimes = ['10:00:00', '12:30:00', '15:00:00', '17:30:00', '19:30:00', '21:00:00'];

    for (int dayIdx = 0; dayIdx < itineraries.length; dayIdx++) {
      final int dayNum = dayIdx + 1;
      final dynamic rawDay = itineraries[dayIdx];

      if (rawDay is Map) {
        final String title = rawDay['title'] ?? rawDay['place_name'] ?? rawDay['content'] ?? '상세 일정';
        final String time = rawDay['start_time'] ?? rawDay['time'] ?? '10:00:00';
        final int day = int.tryParse(rawDay['day_number']?.toString() ?? rawDay['day']?.toString() ?? '') ?? dayNum;

        schedules.add(
          ScheduleModel(
            schedule_id: '${snapshot['snapshot_id'] ?? widget.voteId}_${globalCounter++}',
            title: title,
            start_time: time.length == 5 ? '$time:00' : time,
            category: _detectCategory(title),
            day_number: day,
            place_name: rawDay['place_name'] ?? title,
            place_address: rawDay['place_address'] ?? snapshot['city'] ?? '',
          ),
        );
        continue;
      }

      String dayStr = rawDay.toString().trim();
      dayStr = dayStr.replaceAll(RegExp(r'^\[?\s*\d+일차[^\n:\-\]]*[:\-\]]*\s*'), '');

      List<String> rawChunks = [];
      if (dayStr.contains('\n')) {
        rawChunks = dayStr.split('\n');
      } else if (dayStr.contains('→') || dayStr.contains('->')) {
        rawChunks = dayStr.split(RegExp(r'→|->'));
      } else if (dayStr.contains(',')) {
        rawChunks = dayStr.split(',');
      } else {
        rawChunks = [dayStr];
      }

      int timeIndex = 0;

      for (var chunk in rawChunks) {
        String trimmed = chunk.trim();
        if (trimmed.isEmpty) continue;
        trimmed = trimmed.replaceAll(RegExp(r'^[-•*]\s*'), '').trim();
        if (trimmed.isEmpty) continue;

        final timeRegex = RegExp(r'^(\d{2}:\d{2}(?:\s*(?:~|-|→|->)\s*\d{2}:\d{2})?|\d{2}:\d{2})\s*(.*)');
        final match = timeRegex.firstMatch(trimmed);

        String time = defaultTimes[timeIndex % defaultTimes.length];
        String text = trimmed;

        if (match != null) {
          final rawTime = match.group(1) ?? '';
          time = rawTime.length == 5 ? '$rawTime:00' : rawTime;
          text = (match.group(2) ?? '').trim();
        }

        if (text.isEmpty) text = trimmed;

        String placeName = text;
        if (text.contains('(')) {
          placeName = text.split('(')[0].trim();
        } else if (text.contains(' ')) {
          placeName = text.split(' ')[0].trim();
        }

        schedules.add(
          ScheduleModel(
            schedule_id: '${snapshot['snapshot_id'] ?? widget.voteId}_${globalCounter++}',
            title: text,
            start_time: time,
            category: _detectCategory(text),
            day_number: dayNum,
            place_name: placeName.isNotEmpty ? placeName : text,
            place_address: snapshot['city'] ?? '',
          ),
        );

        timeIndex++;
      }
    }

    return schedules;
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

    // 에러 발생 시 UI (투표 마감으로 오인 표시되지 않도록 분기)
    if (_errorMessage != null && _voteDetail == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontFamily: 'Pretendard'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF524582),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _fetchVoteDetail(),
                  child: const Text('다시 시도', style: TextStyle(color: Colors.white, fontFamily: 'Pretendard')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 대소문자 무관 status 체크
    final String statusStr = _voteDetail?['status']?.toString().toLowerCase() ?? '';
    final bool isActive = (statusStr == 'active');
    final String voteType = _voteDetail?['vote_type']?.toString().toLowerCase() ?? 'group';

    final List<dynamic> snapshots = _voteDetail?['snapshots'] ?? _voteDetail?['itineraries'] ?? [];
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
          if (isActive) ...[
            TextButton(
              onPressed: _deleteVote,
              child: const Text(
                '투표 삭제',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13.5, fontFamily: 'Pretendard'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _finalizeVote,
                child: const Text(
                  '일정 확정',
                  style: TextStyle(color: Color(0xFF524582), fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Pretendard'),
                ),
              ),
            ),
          ],
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
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('투표 가능한 일정 후보가 없습니다.', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
                ),
              )
            else
              for (int i = 0; i < snapshots.length; i++) ...[
                _buildCandidateCard(
                  index: i,
                  snapshot: snapshots[i],
                  voteCount: voteCountMap[int.tryParse(snapshots[i]['snapshot_id']?.toString() ?? '') ?? 0] ?? 0,
                  totalVotes: totalVotesCount,
                  myVotedSnapshotId: myVotedSnapshotId,
                  isActive: isActive,
                  voteType: voteType,
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
    required int? myVotedSnapshotId,
    required bool isActive,
    required String voteType,
  }) {
    bool isExpanded = _expandedIndex == index;
    final int snapshotId = int.tryParse(snapshot['snapshot_id']?.toString() ?? '0') ?? 0;
    final bool isMyVoted = (myVotedSnapshotId != null && myVotedSnapshotId == snapshotId);
    final bool hasVotedAny = (myVotedSnapshotId != null && myVotedSnapshotId > 0);

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
                  if (itineraries.isNotEmpty) ...[
                    for (int dayIdx = 0; dayIdx < itineraries.length; dayIdx++) ...[
                      _buildCleanDaySection(dayIdx + 1, itineraries[dayIdx]),
                      if (dayIdx < itineraries.length - 1) const SizedBox(height: 16),
                    ],
                  ] else
                    const Text('등록된 일정이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontFamily: 'Pretendard')),

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
                        onPressed: isMyVoted
                            ? null
                            : () {
                                if (hasVotedAny && voteType == 'group') {
                                  _changeVote(snapshotId);
                                } else {
                                  _castVote(snapshotId);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF524582),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isMyVoted
                              ? '내 선택 (투표 완료)'
                              : (hasVotedAny && voteType == 'group' ? '이 일정으로 투표 변경' : '이 일정에 투표하기'),
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

  Widget _buildCleanDaySection(int dayNum, dynamic dayData) {
    final String dayStr = dayData.toString().trim();
    final List<String> lines = dayStr.split('\n');
    final List<Map<String, dynamic>> validActivities = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF524582),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$dayNum일차', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        ),
        const SizedBox(height: 10),
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