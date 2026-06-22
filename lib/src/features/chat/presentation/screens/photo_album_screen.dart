import 'package:flutter/material.dart';

class PhotoAlbumScreen extends StatelessWidget {
  const PhotoAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(63),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x3F000000), blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
            title: const Text('보낸 사진함', style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            centerTitle: true,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          // 피그마 지정 헥사 더미 컬러 배열 바인딩
          List<Color> dummyColors = [
            const Color(0xFFB5B0B0), const Color(0xFF0B0B0B), const Color(0xFF696969),
            const Color(0xFF8C8C8C), const Color(0xFFC6C6C6), const Color(0xFF363636),
            const Color(0xFF6A6A6A), const Color(0xFF9E9E9E), const Color(0xFF909090),
          ];
          Color tileColor = dummyColors[index % dummyColors.length];
          return Container(color: tileColor);
        },
      ),
    );
  }
}