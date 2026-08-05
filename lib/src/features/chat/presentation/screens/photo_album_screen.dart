import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';

class PhotoAlbumScreen extends StatefulWidget {
  final int roomId;

  const PhotoAlbumScreen({super.key, required this.roomId});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoomPhotos();
  }

  Future<void> _fetchRoomPhotos() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/messages'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> historyList = [];
        Map<int, String> userNames = {};

        if (responseData is Map) {
          historyList = responseData['messages'] ?? [];
          final rawUserNames = responseData['user_names'];
          if (rawUserNames is Map) {
            rawUserNames.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              if (uId != null && value != null) {
                userNames[uId] = value.toString();
              }
            });
          }
        } else if (responseData is List) {
          historyList = responseData;
        }

        List<Map<String, dynamic>> extractedPhotos = [];

        for (var item in historyList) {
          if (item == null) continue;
          final Map<String, dynamic> msg = Map<String, dynamic>.from(item);
          final String content = (msg['content'] ?? '').toString().trim();
          final String msgType = (msg['message_type'] ?? 'text').toString();
          final int senderId = int.tryParse(msg['sender_id']?.toString() ?? '0') ?? 0;
          final String createdAt = msg['created_at']?.toString() ?? '';

          final bool isImg = msgType == 'image' ||
              (content.startsWith('http') &&
                  (content.contains('.jpg') ||
                      content.contains('.png') ||
                      content.contains('.jpeg') ||
                      content.contains('s3.amazonaws') ||
                      content.contains('presigned')));

          if (isImg) {
            String dateFormatted = createdAt;
            try {
              final dt = DateTime.parse(createdAt).toLocal();
              dateFormatted = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } catch (_) {}

            final String senderNick = msg['sender_nickname'] ?? userNames[senderId] ?? '유저';

            extractedPhotos.add({
              'url': content,
              'sender_name': senderNick,
              'date': dateFormatted,
            });
          }
        }

        if (mounted) {
          setState(() {
            _photos = extractedPhotos.reversed.toList(); // 최신순 정렬
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('사진함 로드 예외: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🖼️ [이미지 514227, 513f5d 연출]: 상세 보기 모달 (상단 작성자+날짜 Header & 화살표 버튼 & Swiping)
  void _openPhotoDetailModal(int initialIndex) {
    final PageController pageController = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      builder: (context) {
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentPhoto = _photos[currentIndex];

            return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: const Color(0xFFF5F5F5), // 스크린샷 연한 회색 배경
              child: Stack(
                children: [
                  // 1. 좌우 슬라이드 PageView
                  PageView.builder(
                    controller: pageController,
                    itemCount: _photos.length,
                    onPageChanged: (index) {
                      setModalState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.network(
                            _photos[index]['url'],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('이미지를 불러올 수 없습니다.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. 상단 바: 작성자 닉네임 + 날짜 (image_514227.png)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Text(
                            currentPhoto['sender_name'] ?? '유저',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentPhoto['date'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF2563EB), // 파란색 날짜 텍스트
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black87, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. 왼쪽 이전 사진 화살표 버튼 (<)
                  if (currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.chevron_left, color: Colors.black87, size: 24),
                          ),
                        ),
                      ),
                    ),

                  // 4. 오른쪽 다음 사진 화살표 버튼 (>)
                  if (currentIndex < _photos.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.chevron_right, color: Colors.black87, size: 24),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('보낸 사진함', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF524582)))
          : _photos.isEmpty
              ? const Center(child: Text('채팅방에 공유된 사진이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard')))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () => _openPhotoDetailModal(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}