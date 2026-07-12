# Tripto Flutter 프로젝트

> 여행 플래닝 앱 — Flutter + AWS (Lambda, API Gateway, DynamoDB, Cognito)

---

## 📁 프로젝트 구조

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart          # 색상, 타이포, 간격, ThemeData
│
├── domain/                         # 순수 비즈니스 로직 (Flutter 의존성 없음)
│   ├── entities/
│   │   └── entities.dart           # UserEntity, TripEntity, ChatRoomEntity...
│   └── repositories/
│       └── repository_interfaces.dart  # 추상 인터페이스 (역전)
│
├── data/                           # 데이터 계층
│   ├── models/
│   │   └── data_models.dart        # JSON 직렬화 모델
│   └── repositories/
│       └── repository_implementations.dart  # ApiClient + 구현체
│
└── presentation/                   # UI 계층
    ├── providers/
    │   └── providers.dart          # Riverpod 상태 관리 전체
    ├── widgets/
    │   └── atoms/
    │       └── atomic_widgets.dart # 재사용 위젯 (Atomic Design)
    └── screens/
        └── screens.dart            # 6개 화면 (Login, Signup, Home, Chat, Schedule, Profile)
```

---

## 🚀 시작하기

```bash
# 의존성 설치
flutter pub get

# 개발 빌드 (API 환경변수 주입)
flutter run \
  --dart-define=API_BASE_URL=https://YOUR_API_ID.execute-api.ap-northeast-2.amazonaws.com/v1 \
  --dart-define=API_KEY=YOUR_API_GATEWAY_KEY
```

---

## 🔐 보안 설정

### API Key 관리
```
# .gitignore에 반드시 추가
.env
*.env
```

### 프로덕션 권장 구조
```
앱 → API Gateway (x-api-key 검증) → Lambda (JWT 검증) → DynamoDB
```

---

## ☁️ AWS 아키텍처

```
Flutter App
    │
    ├── HTTPS → API Gateway (REST)
    │               ├── /auth/*    → Lambda (Cognito 연동)
    │               ├── /trips/*   → Lambda → DynamoDB
    │               ├── /chats/*   → Lambda → DynamoDB  
    │               └── /profile/* → Lambda → S3 + DynamoDB
    │
    └── WebSocket → API Gateway (WebSocket)
                        └── Lambda → DynamoDB Streams → 푸시
```

---

## 🎨 디자인 토큰

| 항목 | 값 |
|------|-----|
| Primary | `#7B61FF` |
| Background | `#13111F` |
| Card | `#1E1B30` |
| Input | `#2A2640` |
| 화면 수평 패딩 | `20px` |
| 카드 패딩 | `16px` |
| 모서리 (카드) | `16px` |

---

## 📦 주요 패키지

| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod` | 상태 관리 |
| `http` | API 통신 |
| `flutter_secure_storage` | JWT 암호화 저장 |
| `intl` | 날짜 포맷 |
