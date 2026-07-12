// lib/src/features/profile/presentation/screens/saved_places_screen.dart

import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'place_detail_screen.dart';

class _PlaceModel {
  final String name, location, imageUrl;
  const _PlaceModel(
      {required this.name, required this.location, required this.imageUrl});
}

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  // 더미 (추후 API 교체)
  final _places = [
    const _PlaceModel(
        name: '명동 쇼핑 거리',
        location: '서울',
        imageUrl:
            'https://images.unsplash.com/photo-1601042879364-f3947d3f9c16?w=120&q=80'),
    const _PlaceModel(
        name: '전주 한옥마을',
        location: '전주',
        imageUrl:
            'https://images.unsplash.com/photo-1578469645742-46cae010e5d4?w=120&q=80'),
    const _PlaceModel(
        name: '경복궁',
        location: '서울',
        imageUrl:
            'https://images.unsplash.com/photo-1548115184-bc6544d06a58?w=120&q=80'),
    const _PlaceModel(
        name: '북촌 한옥마을',
        location: '서울',
        imageUrl:
            'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=120&q=80'),
    const _PlaceModel(
        name: '해운대 해수욕장',
        location: '부산',
        imageUrl:
            'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=120&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                const Text('저장한 장소',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _places.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF0EEFF)),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(
                            name: _places[i].name,
                            location: _places[i].location))),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(_places[i].imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFDDDDDD))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_places[i].name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E2939))),
                            Text(_places[i].location,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.favorite,
                          color: Color(0xFFD93030), size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
