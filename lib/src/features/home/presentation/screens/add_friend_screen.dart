// lib/src/features/home/presentation/screens/add_friend_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';

// ── 검색 상태 ──
enum SearchState { idle, loading, found, notFound }

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  SearchState _state = SearchState.idle;
  _UserResult? _result;
  bool _requestSent = false;

  // 더미 유저 DB (추후 API로 교체)
  static const _dummyUsers = {
    'traveljang123': _UserResult(
        name: '이재민',
        userId: 'traveljang123',
        statusMessage: '바다로 떠나고 싶어요 🌊',
        avatarLabel: '이재'),
    'jinyoung_trip': _UserResult(
        name: '신진영',
        userId: 'jinyoung_trip',
        statusMessage: '최근 부산 여행',
        avatarLabel: '신진'),
    'sangwon_lee': _UserResult(
        name: '이상원',
        userId: 'sangwon_lee',
        statusMessage: '여행 계획 없음',
        avatarLabel: '이상'),
  };

  // 최근 검색 더미
  final List<_UserResult> _recentSearches = [
    const _UserResult(
        name: '신진영',
        userId: 'jinyoung_trip',
        statusMessage: '최근 부산 여행',
        avatarLabel: '신진'),
    const _UserResult(
        name: '이상원',
        userId: 'sangwon_lee',
        statusMessage: '여행 계획 없음',
        avatarLabel: '이상'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _state = SearchState.loading);
    _focusNode.unfocus();

    // TODO: 실제 API 호출로 교체
    // final result = await ref.read(friendSearchProvider(query).future);
    await Future.delayed(const Duration(milliseconds: 600)); // 로딩 시뮬레이션

    final user = _dummyUsers[query];
    setState(() {
      _result = user;
      _requestSent = false;
      _state = user != null ? SearchState.found : SearchState.notFound;
    });
  }

  void _sendRequest() {
    setState(() => _requestSent = true);
    // TODO: API 친구 요청 호출
  }

  void _removeRecent(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 앱바 ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text('친구 추가',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),

          // ── 검색창 ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 검색 입력창
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _search(),
                          onChanged: (v) => setState(() {
                            if (v.isEmpty) _state = SearchState.idle;
                          }),
                          decoration: const InputDecoration(
                            hintText: '아이디를 입력하세요',
                            hintStyle: TextStyle(
                                fontSize: 14, color: Color(0xFFC0BBDE)),
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 검색 버튼
                    ElevatedButton(
                      onPressed:
                          _controller.text.trim().isNotEmpty ? _search : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFC0BBDE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('검색',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tripto 아이디로 친구를 검색할 수 있어요',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),

          // ── 결과 영역 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      // 초기 상태 — 최근 검색
      SearchState.idle => _recentSearches.isEmpty
          ? const _EmptyGuide()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 검색',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: .5)),
                const SizedBox(height: 10),
                ...List.generate(
                    _recentSearches.length,
                    (i) => _RecentItem(
                          user: _recentSearches[i],
                          onDelete: () => _removeRecent(i),
                        )),
              ],
            ),

      // 로딩
      SearchState.loading => const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),

      // 검색 결과 있음
      SearchState.found => _SearchResultCard(
          user: _result!,
          requestSent: _requestSent,
          onRequest: _sendRequest,
        ),

      // 검색 결과 없음
      SearchState.notFound => const _NotFoundState(),
    };
  }
}

// ── 초기 안내 ──
class _EmptyGuide extends StatelessWidget {
  const _EmptyGuide();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 52, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('아이디를 검색해서\n새로운 친구를 추가해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}

// ── 검색 결과 카드 ──
class _SearchResultCard extends StatelessWidget {
  final _UserResult user;
  final bool requestSent;
  final VoidCallback onRequest;
  const _SearchResultCard(
      {required this.user, required this.requestSent, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('검색 결과',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: .5)),
          const SizedBox(height: 12),
          Row(
            children: [
              // 아바타
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Text(user.avatarLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2939))),
                    Text('@${user.userId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(user.statusMessage,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // 요청 버튼
              GestureDetector(
                onTap: requestSent ? null : onRequest,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: requestSent
                        ? const Color(0xFFE1F5EE)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    requestSent ? '✓ 요청됨' : '요청',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          requestSent ? const Color(0xFF0F6E56) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 결과 없음 ──
class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_outlined,
              size: 40, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('해당 아이디의 사용자를\n찾을 수 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}

// ── 최근 검색 아이템 ──
class _RecentItem extends StatelessWidget {
  final _UserResult user;
  final VoidCallback onDelete;
  const _RecentItem({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(user.avatarLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2939))),
                    Text('@${user.userId}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0EEFF)),
      ],
    );
  }
}

// ── 유저 데이터 모델 ──
class _UserResult {
  final String name, userId, statusMessage, avatarLabel;
  const _UserResult(
      {required this.name,
      required this.userId,
      required this.statusMessage,
      required this.avatarLabel});
}
