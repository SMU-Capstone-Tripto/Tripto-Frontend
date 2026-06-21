import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/routing/app_router.dart';
import 'src/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_JS_KEY'] ?? '');
  runApp(const ProviderScope(child: TriptoApp()));
}

class TriptoApp extends ConsumerWidget {
  const TriptoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tripto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 라우터 연결
      routerConfig: router,
    );
  }
}
