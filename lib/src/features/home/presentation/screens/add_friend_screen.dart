import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tripto/src/constants/app_theme.dart';
import '../../domain/friend_model.dart';
import '../../presentation/home_provider.dart';

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
  final List<FriendModel> _recentSearches = [];

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

    try {
      final userModel = await ref.read(friendSearchProvider(query).future);
      setState(() {
        if (userModel != null) {
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
    }
  }

  Future<void> _sendRequest() async {
    if (_result == null) return;
    try {
      await ref.read(friendListProvider.notifier).addFriend(_result!.uniqueId);
      setState(() => _requestSent = true);
    } catch (e) {
      // 에러 처리
    }
  }

  void _removeRecent(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

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
      backgroundColor: const Color(0xFFF6F5FA), // 💡 연한 배경색
      body: Column(
        children: [
          // ── 💡 그라데이션 헤더 + 반투명 검색창 ──
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text('친구 추가',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                // 💡 반투명 검색창 디자인 적용
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), // 반투명 흰색
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _search(),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Tripto 아이디를 검색해 보세요',
                            hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: _search,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 결과 영역 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      SearchState.idle => _recentSearches.isEmpty
          ? const _EmptyGuide()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최근 검색',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9993C4))),
                  const SizedBox(height: 12),
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
            ),
      SearchState.loading => const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primary))),
      SearchState.found => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SearchResultCard(
            user: _result!,
            avatarColor: _getAvatarColor(_result!.avatarColor),
            requestSent: _requestSent,
            onRequest: _sendRequest,
          ),
        ),
      SearchState.notFound => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _NotFoundState()),
      SearchState.error => const Center(child: Text('에러 발생')),
    };
  }
}

// ── 초기 안내 ──
class _EmptyGuide extends StatelessWidget {
  const _EmptyGuide();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded,
              size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('아이디를 검색해서\n새로운 친구를 추가해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF9993C4), height: 1.5)),
        ],
      ),
    );
  }
}

// ── 검색 결과 카드 (새로운 카드 디자인) ──
class _SearchResultCard extends StatelessWidget {
  final FriendModel user;
  final Color avatarColor;
  final bool requestSent;
  final VoidCallback onRequest;

  const _SearchResultCard(
      {required this.user,
      required this.avatarColor,
      required this.requestSent,
      required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6144B0).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('검색 결과',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9993C4))),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(user.avatarLabel,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: avatarColor)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nickname,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2939))),
                    const SizedBox(height: 2),
                    Text('@${user.uniqueId}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9993C4))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: requestSent ? null : onRequest,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: requestSent
                        ? const Color(0xFFF6F5FA)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    requestSent ? '✓ 요청됨' : '요청',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: requestSent
                            ? const Color(0xFF9993C4)
                            : Colors.white),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6144B0).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFC0BBDE)),
          SizedBox(height: 16),
          Text('사용자를 찾을 수 없습니다',
              style: TextStyle(fontSize: 14, color: Color(0xFF9993C4))),
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

  const _RecentItem(
      {required this.user, required this.avatarColor, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6144B0).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(user.avatarLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: avatarColor))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nickname,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2939))),
                  Text('@${user.uniqueId}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9993C4))),
                ],
              ),
            ),
            IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close,
                    size: 18, color: Color(0xFFC0BBDE))),
          ],
        ),
      ),
    );
  }
}
