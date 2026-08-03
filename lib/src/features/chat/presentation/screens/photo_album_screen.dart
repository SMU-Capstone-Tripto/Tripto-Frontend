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
  List<String> _imageUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoomImages();
  }

  /// 🎯 [사진 메시지 내역 동기화]: GET /chat/{roomId}/messages에서 message_type == "image" 필터링
  Future<void> _fetchRoomImages() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/messages'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> historyList = [];

        if (responseData is Map) {
          historyList = responseData['messages'] ?? [];
        } else if (responseData is List) {
          historyList = responseData;
        }

        List<String> photos = [];
        for (var item in historyList) {
          if (item == null || item is! Map) continue;
          final String content = item['content']?.toString() ?? '';
          final String msgType = item['message_type']?.toString() ?? 'text';

          bool isImg = msgType == 'image' ||
              (content.startsWith('http') &&
                  (content.contains('.jpg') ||
                      content.contains('.png') ||
                      content.contains('.jpeg') ||
                      content.contains('s3.amazonaws') ||
                      content.contains('presigned')));

          if (isImg && content.isNotEmpty) {
            photos.add(content);
          }
        }

        if (mounted) {
          setState(() {
            _imageUrls = photos.reversed.toList(); // 최신순 배치
          });
        }
      }
    } catch (e) {
      debugPrint('❌ 보낸 사진함 조회 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageDetailModal(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(63),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              '보낸 사진함',
              style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF524582)))
          : _imageUrls.isEmpty
              ? const Center(
                  child: Text(
                    '전송된 사진이 없습니다.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard'),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(3),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                    childAspectRatio: 1,
                  ),
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    final String url = _imageUrls[index];
                    return GestureDetector(
                      onTap: () => _showImageDetailModal(url),
                      child: Container(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF524582)),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}