// lib/src/features/schedule/presentation/widgets/kakao_map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../../domain/schedule_model.dart';
import '../../data/kakao_geocoding_api.dart';

class KakaoMapView extends ConsumerStatefulWidget {
  // ← StatefulWidget → ConsumerStatefulWidget
  final List<ScheduleModel>? items;
  final ScheduleModel? singleItem;
  final double height;

  const KakaoMapView({
    super.key,
    this.items,
    this.singleItem,
    this.height = 200,
  }) : assert(items != null || singleItem != null);

  @override
  ConsumerState<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends ConsumerState<KakaoMapView> {
  KakaoMapController? _mapController; // ← 선언 추가

  Future<Set<Marker>> _resolveMarkers() async {
    final items = widget.items ?? [widget.singleItem!];
    final markers = <Marker>{};

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.place_address == null) continue;

      final latLng =
          await KakaoGeocodingApi.addressToLatLng(item.place_address!);
      if (latLng == null) continue;

      markers.add(Marker(
        markerId: item.schedule_id,
        latLng: latLng,
        infoWindowContent: widget.singleItem != null
            ? (item.place_name ?? item.title)
            : '${i + 1}. ${item.place_name ?? item.title}',
      ));
    }
    return markers;
  }

  List<Polyline> _buildPolylines(List<LatLng> points) {
    if (points.length < 2) return [];
    return [
      Polyline(
        polylineId: 'route',
        points: points,
        strokeColor: const Color(0xFF6144B0),
        strokeWidth: 2,
        strokeOpacity: 0.7,
        strokeStyle: StrokeStyle.dash,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Set<Marker>>(
          future: _resolveMarkers(),
          builder: (context, snap) {
            // 로딩 중
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6144B0)),
              );
            }
            // 에러 또는 빈 결과
            if (!snap.hasData || snap.data!.isEmpty) {
              return const Center(
                child: Text('지도를 불러올 수 없습니다',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9993C4))),
              );
            }

            final markers = snap.data!;
            return KakaoMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (markers.length > 1) {
                  _mapController?.fitBounds(
                    markers.map((m) => m.latLng).toList(),
                  );
                }
              },
              markers: markers.toList(),
              polylines: _buildPolylines(
                markers.map((m) => m.latLng).toList(),
              ),
              center: markers.first.latLng,
              currentLevel: widget.singleItem != null ? 4 : 7,
            );
          },
        ),
      ),
    );
  }
}
