// lib/src/features/schedule/data/kakao_geocoding_api.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class KakaoGeocodingApi {
  // Kakao REST API Key (.env로 관리)
  static const _restApiKey = 'YOUR_KAKAO_REST_API_KEY';

  /// 주소 문자열 → LatLng 변환
  static Future<LatLng?> addressToLatLng(String address) async {
    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json'
          '?query=${Uri.encodeComponent(address)}',
    );

    final response = await http.get(uri, headers: {
      'Authorization': 'KakaoAK $_restApiKey',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final docs = data['documents'] as List;
      if (docs.isNotEmpty) {
        return LatLng(
          double.parse(docs[0]['y'] as String),
          double.parse(docs[0]['x'] as String),
        );
      }
    }
    return null; // 변환 실패 시 null
  }
}

// Provider로 캐싱 (같은 주소 중복 호출 방지)
final geocodingProvider = FutureProvider.family<LatLng?, String>(
      (ref, address) => KakaoGeocodingApi.addressToLatLng(address),
);