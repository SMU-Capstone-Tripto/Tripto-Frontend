import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tripto/src/constants/app_theme.dart';
import '../../domain/friend_model.dart';
import '../../presentation/home_provider.dart';

// ── 검색 상태 ──
enum SearchState { idle, loading, found, notFound, error }

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  SearchState _state = SearchState.idle;
  FriendModel? _result;
  bool _requestSent = false;

  // 최근 검색 기록 (앱 실행 중에만 유지. 영구 저장을 원하시면 SharedPreferences 연동 필요)
  final List<FriendModel> _recentSearches = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 검색 API 호출 로직 ──
  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _state = SearchState.loading);
    _focusNode.unfocus();

    try {
      // 실제 API 호출 (friendSearchProvider 사용)
      final userModel = await ref.read(friendSearchProvider(query).future);

      setState(() {
        if (userModel != null) {
          // 기존 _UserResult 매핑 로직을 지우고 바로 할당
          _result = userModel;
          _state = SearchState.found;
        } else {
          _result = null;
          _state = SearchState.notFound;
        }
        _requestSent = false;
      });
    } catch (e) {
      setState(() => _state = SearchState.notFound);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _sendRequest() async {
    if (_result == null) return;

    // 로딩 처리 등 필요한 경우 setState 사용 가능
    try {
      // home_provider에 이미 잘 만들어두신 addFriend 호출
      await ref.read(friendListProvider.notifier).addFriend(_result!.uniqueId);

      setState(() => _requestSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청이 전송되었습니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 요청에 실패했습니다: $e')),
        );
      }
    }
  }

  // ── 최근 검색어 삭제 ──
  void _removeRecent(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

  // ── 아바타 색상 매핑 함수 ──
  Color _getAvatarColor(AvatarColor colorEnum) {
    return switch (colorEnum) {
      AvatarColor.purple => AppColors.primary,
      AvatarColor.pink => Colors.pinkAccent,
      AvatarColor.teal => Colors.teal,
      AvatarColor.amber => Colors.amber,
      AvatarColor.blue => Colors.blueAccent,
    };
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
                          avatarColor:
                              _getAvatarColor(_recentSearches[i].avatarColor),
                          onDelete: () => _removeRecent(i),
                        )),
              ],
            ),

      // 로딩 중
      SearchState.loading => const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),

      // 검색 결과 찾음
      SearchState.found => _SearchResultCard(
          user: _result!,
          avatarColor: _getAvatarColor(_result!.avatarColor),
          requestSent: _requestSent,
          onRequest: _sendRequest,
        ),

      // 검색 결과 없음
      SearchState.notFound => const _NotFoundState(),

      // 검색 중 에러 발생
      SearchState.error => Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('데이터를 불러오는 중 문제가 발생했습니다.\n다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _search,
                child: const Text('다시 시도',
                    style: TextStyle(color: AppColors.primary)),
              )
            ],
          ),
        ),
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
  final FriendModel user;
  final Color avatarColor;
  final bool requestSent;
  final VoidCallback onRequest;

  const _SearchResultCard({
    required this.user,
    required this.avatarColor,
    required this.requestSent,
    required this.onRequest,
  });

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
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(user.avatarLabel,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: avatarColor)),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nickname,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2939))),
                    // Tripto ID
                    Text('@${user.uniqueId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    if (user.statusMessage.isNotEmpty)
                      Text(user.statusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  final FriendModel user;
  final Color avatarColor;
  final VoidCallback onDelete;

  const _RecentItem({
    required this.user,
    required this.avatarColor,
    required this.onDelete,
  });

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
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(user.avatarLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: avatarColor)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nickname,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2939))),
                    Text('@${user.uniqueId}',
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
