# Changelog

All notable changes to the Military Tracker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2025-12-28

### Fixed
- 🐛 **iOS 권한 요청 오류 수정** (CRITICAL)
  - iOS에서 `activityRecognition` 권한이 존재하지 않는 문제 해결
  - 걷기: iOS는 CoreMotion 사용 (별도 권한 불필요)
  - 뛰기: Geolocator 직접 사용으로 변경 (iOS/Android 호환)
  - iOS 설정에서 "위치" 항목이 정상적으로 표시됨

### Changed
- 🔧 **권한 처리 로직 개선**
  - PedometerService: Platform.isAndroid 체크 추가
  - RunningTrackerService: Geolocator.requestPermission() 직접 사용
  - iOS/Android 플랫폼별 권한 처리 분리

### Technical
- iOS: CoreMotion은 자동 허용 (NSMotionUsageDescription만 필요)
- Android: activityRecognition 권한 필요
- GPS: Geolocator 패키지가 iOS/Android 모두 처리

## [1.0.3] - 2025-12-28

### Fixed
- 🐛 **커뮤니티 화면 회색 박스 오류 수정**
  - `post.userId` → `post.authorId`로 필드명 수정
  - 사용자 프로필 카드 정상 표시

- 🖼️ **프로필 이미지 업로드 완전 구현**
  - Storage 업로드 후 Firestore 업데이트 누락 수정
  - 프로필 사진 삭제 로직 중복 제거
  - `uploadPostImage` → `uploadProfileImage` 메서드 변경
  - Firebase Auth 프로필과 Firestore 동기화

- 📝 **게시글 수정 시 이미지 관리 기능 추가**
  - 기존 이미지 삭제 기능
  - 새 이미지 추가 기능 (최대 5장)
  - 기존 + 신규 이미지 합산 제한 관리
  - Storage 파일 실제 삭제 처리
  - 'NEW' 배지로 새 이미지 시각적 구분

### Added
- ✨ **AuthRepository 메서드 추가**
  - `updateProfile()`: 프로필 정보 업데이트 (displayName, photoUrl, bio)
  - `deletePhoto` 플래그로 명확한 사진 삭제 의도 전달
  - Firebase Auth와 Firestore 동시 업데이트

### Changed
- 🔧 **에러 핸들링 강화**
  - 이미지 부분 업로드 실패 감지 및 사용자 알림
  - Storage 삭제 실패 시에도 프로세스 계속 진행
  - try-catch로 개별 이미지 삭제 오류 격리
  - 명확한 성공률 피드백 (예: "3/5 성공")

- 📊 **코드 안정성 개선**
  - 프로필 사진 삭제 로직 단일화 및 예외 처리
  - 모든 비동기 작업에 적절한 에러 핸들링
  - `mounted` 체크로 메모리 누수 방지
  - logger import 추가로 디버깅 향상

### Performance
- ⚡ 불필요한 중복 로직 제거
- 🚀 에러 발생 시에도 사용자 경험 유지

## [1.0.1] - 2025-12-27

### Added
- 🎯 **랭킹 시스템**: 일간/주간/월간/전체 랭킹 기능
  - 종합, 스쿼트, 런지, 걷기, 뛰기 카테고리별 랭킹
  - 가중치 기반 점수 계산 (뛰기 > 스쿼트 = 런지 > 걷기)
  - 동점자 처리 (1위, 1위, 3위...)
  - 실시간 내 순위 표시

- 👥 **팔로우/팔로잉 시스템**: 소셜 기능 추가
  - 다른 사용자 팔로우/언팔로우
  - 팔로워/팔로잉 수 실시간 업데이트
  - 사용자 프로필 화면 (운동 통계, 게시글, 연속 운동 일수)
  - 커뮤니티 및 랭킹에서 사용자 클릭 시 프로필 바텀시트

- 📊 **실시간 통계 시스템**: 정확한 데이터 집계
  - 총 운동량 실시간 계산 (WorkoutModel 기반)
  - 연속 운동 일수(Streak) 자동 계산
  - 주간 진행 현황 차트 (실제 데이터 연동)
  - 가중치 기반 진행률 표시

- 🏠 **홈 화면 개선**
  - TODAY'S WORKOUT 섹션 제거 (중복 제거)
  - WEEKLY PROGRESS를 실제 운동 데이터와 연동
  - Quick Actions 버튼을 각 화면과 연결
  - 가중치 기반 주간 차트

- 🔒 **Firebase 보안 규칙**: 포괄적인 데이터 보호
  - 모든 컬렉션에 대한 읽기/쓰기 규칙
  - 인증 필수, 소유권 검증
  - 자기 자신 팔로우 방지
  - 데이터 검증 (필드 타입, 범위)

### Changed
- ⚡ **랭킹 시스템 성능 최적화**: N+1 쿼리 문제 해결
  - Firestore 쿼리 수 90% 감소 (101회 → 11회)
  - Firestore 읽기 비용 ~90% 절감
  - 배치 쿼리 및 메모리 집계 방식 도입
  - 운동 기록이 있는 사용자만 조회

- 📱 **사용자 프로필 모델 확장**
  - `bio` 필드 추가 (자기소개)
  - `followerCount`, `followingCount` 필드 추가
  - Timestamp 변환 로직 통일

### Fixed
- 🐛 **팔로우 시스템 필드명 오류 수정**
  - `workout.squats` → `workout.squatCount`
  - `workout.lunges` → `workout.lungeCount`
  - Timestamp 변환 누락 문제 해결

- 🔧 **데이터 일관성 개선**
  - WorkoutModel Timestamp 변환 통일
  - 필드명 일치 확인
  - 가중치 계산 로직 통일 (랭킹 = 홈 화면)

### Security
- 🔐 Firestore 보안 규칙 전체 적용
  - users, workouts, posts, comments, follows 컬렉션
  - 본인 데이터만 수정/삭제 가능
  - 악의적 행위 차단

### Performance
- ⚡ Firestore 쿼리 최적화 (90% 성능 향상)
- 🚀 배치 쿼리를 통한 네트워크 왕복 최소화
- 💾 autoDispose를 통한 메모리 관리 개선

## [1.0.0] - 2025-12-XX

### Added
- 🏋️ 운동 추적 기능 (스쿼트, 런지, 걷기, 뛰기)
- 📷 카메라 기반 자세 인식
- 📱 수동 입력 지원
- 🎯 일일 목표 설정
- 📊 운동 기록 및 히스토리
- 🏆 업적 시스템
- 💬 커뮤니티 (게시글, 댓글)
- 🔐 Firebase 인증 (이메일, Google)
- 💾 Cloud Firestore 데이터 저장
- 📸 프로필 사진 업로드
- 🔔 푸시 알림 (선택)

---

## Version Format

`major.minor.patch+buildNumber`

- **major**: 주요 기능 변경, API 변경
- **minor**: 새로운 기능 추가 (하위 호환)
- **patch**: 버그 수정, 성능 개선
- **buildNumber**: 빌드 번호 (Play Store/App Store 제출용)
