# MILITARYTRACKER

검증된 자세 가이드 위에서 기록하는 트레이닝 앱.
Expo(React Native) + Firebase.

---

## 스택

| 영역 | 기술 |
|---|---|
| 앱 | Expo SDK 57 · React Native 0.86 · expo-router 57 |
| 언어 | TypeScript 6 (strict) |
| 상태 | Zustand 5 |
| 백엔드 | Firebase Auth · Firestore · Cloud Functions v2 (asia-northeast3) |
| AI | Cloud Functions 프록시 경유 (앱에 키 없음) |

## 실행

```bash
npm install
cp .env.example .env      # Firebase 웹 앱 설정값 입력
npm start
```

## 구조

```
app/                    expo-router 라우트
  _layout.tsx           인증·데이터 하이드레이션 + 라우팅 가드
  onboard.tsx           5단계 온보딩 (마지막 단계에서 루틴 선택)
  tabs/                 홈 · 운동 · 자세 · 식단 · MY
  routine/              루틴 목록 → [routineId] → [dayId]
  exercise/[exerciseId] 종목 상세 (영상 + 자세 가이드)
  library/[feedId]      부위별 가이드 시리즈
src/
  data/exercises.ts     운동 180종 DB
  data/routines.ts      루틴 프리셋 7종
  data/media.ts         영상·이미지 레지스트리
  data/formCheck.ts     자세 교정 포인트
  data/feed.ts          라이브러리 콘텐츠
  services/             firebase · auth · workout · ai
  stores/               authStore · appStore
  utils/                planner · stats · body · colors
functions/              Cloud Functions (AI 프록시)
```

## 탐색 흐름

```
온보딩 → 루틴 선택 → 루틴 상세(푸시풀레그) → 데이(푸시데이) → 운동 종목
```

## 운동 DB

총 **180종**. 가슴 30 · 등 30 · 하체 30 · 어깨 30 · 이두 15 · 삼두 15 · 복근 30.

각 종목은 `id / 한글명 / 부위 / 세부타겟 / 장비 / 장소 / 세트 / 반복 / 휴식 / 난이도 / PPL분류` 를 가진다.

### 미디어 추가 방법

1. 파일을 규칙에 맞게 저장
   - 영상: `assets/exercise/video/{id}.mp4` — **3~5초 루프, 무음, 1:1 비율**
   - 썸네일: `assets/exercise/image/{id}.png` — 1:1, 512px 이하
2. `src/data/media.ts` 의 `EX_VIDEO` / `EX_IMAGE` 에 한 줄 추가
   ```ts
   bench: require('../../assets/exercise/video/bench.mp4'),
   ```
   (React Native 의 `require()` 는 정적 경로만 허용하므로 자동 스캔이 불가능하다)
3. 진행 상황 확인
   ```bash
   npm run media:report            # 부위별 등록 현황
   npm run media:report --missing  # 누락 id 목록
   ```

미등록 종목은 `<ExerciseMedia />` 가 부위 색상 플레이스홀더를 자동으로 렌더한다.

## Firebase

### 보안 규칙

- 본인 데이터만 읽고 쓴다 (`users` / `plans` / `workoutLogs` / `weights`)
- `role == 'admin'` 이거나 커스텀 클레임 `admin: true` 인 계정은 **전체 허용**
- 본인이 자기 `role` 을 바꾸는 것은 차단

```bash
npm run deploy:rules
```

관리자 지정 — 둘 중 하나:

```bash
# (권장) 커스텀 클레임 — 규칙에서 문서 read 비용이 없다
node -e "require('firebase-admin').initializeApp();require('firebase-admin').auth().setCustomUserClaims('<uid>',{admin:true})"

# 또는 Firestore 콘솔에서 users/{uid}.role 을 'admin' 으로 변경
```

### Cloud Functions (AI 프록시)

`aiPlan` · `aiDiet` · `aiCoach` 세 개의 callable 함수. 모두 로그인 필수.

```bash
cd functions && npm install && cd ..
firebase functions:secrets:set ANTHROPIC_API_KEY   # 키 입력
npm run deploy:functions
```

> 함수가 배포되지 않은 상태에서도 앱은 동작한다.
> 플랜은 로컬 알고리즘, 식단은 기본 예시로 자동 폴백한다.

## 면책

일반적인 운동·영양 가이드이며 의학적 조언이 아니다. 통증·질환이 있으면 전문가와 상담할 것.
