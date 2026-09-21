# 운동 영상

## 폴더

```
media/
  originals/      원본 보관 — .gitignore 로 제외 (부위당 100~200MB)
    chest/        01.pushup.mp4 … 30.guillotine.mp4
    back/  legs/  shoulders/  biceps/  triceps/  abs/
  cors.json       버킷 CORS 설정 (아래)
```

원본은 **절대 `assets/` 에 넣지 않는다.** `assets/` 는 저장소와 앱 번들에 들어간다.

## 올리기

```bash
npm run media:upload -- back --dry   # 파일 → 종목 매칭표만 확인
npm run media:upload -- back         # 인코딩 · 업로드 · 매니페스트 갱신
```

- 파일명 앞 번호 = `src/data/exercises.ts` 에서 그 부위의 순번.
  `7.Lat Pulldown (1).mp4` 처럼 받은 이름 그대로 넣으면 된다.
- 업로드가 끝나면 원본 이름이 `07.latpull.mp4` 형식으로 정리된다.
- 같은 종목을 다시 올리면 교체된다. URL 이 바뀌어 기기 캐시도 새 파일을 받는다.
- 필요: `ffmpeg`, Node 22+, `firebase login` (또는 `GCS_TOKEN` 환경변수).

## 버킷

`gs://military-tracker-96bdd` — **asia-northeast3 (서울)**

| 경로 | 내용 | Cache-Control |
|---|---|---|
| `exercise/video/{id}.mp4` | 1080×1080 H.264 High, CRF 23, 무음, faststart | `immutable` 1년 |
| `exercise/poster/{id}.jpg` | 512×512 첫 프레임 | `immutable` 1년 |
| `exercise/manifest.json` | `{ updatedAt, items: { id: { video, poster } } }` | `no-cache` |

매니페스트의 값은 각 파일의 GCS `generation` 이다. 앱은 URL 에 `v=<generation>` 을
붙이므로 같은 이름으로 다시 올리면 URL 이 달라져 캐시가 자동으로 무효화된다.
그래서 영상·썸네일에 `immutable` 을 걸어도 안전하다.

### 접근

- **읽기: 누구나** (`storage.rules` 의 `exercise/**`). 영상 플레이어, 특히 웹 `<video>` 는
  Firebase 인증 헤더를 붙일 수 없어 로그인 조건을 걸 수 없다. 원래 앱 번들에 그대로
  들어가던 공개 콘텐츠다.
- **쓰기: 규칙상 전면 차단.** 업로드 스크립트는 Google Cloud 권한으로 쓰므로 규칙을 거치지 않는다.
- **CORS (`cors.json`)**: 웹 앱이 `fetch()` 로 매니페스트를 읽으려면 필요하다. 없으면 웹은
  앱에 들어간 스냅샷만 보게 되어 새 영상이 안 뜬다. GET·HEAD 만 허용하며, 이미 공개된
  파일이라 접근 범위는 달라지지 않는다. 버킷을 새로 만들면 다시 적용할 것:

  ```bash
  gcloud storage buckets update gs://military-tracker-96bdd --cors-file=media/cors.json
  ```

## 앱 쪽

- `src/data/media.ts` — URL 생성, 번들 썸네일(`EX_IMAGE`)
- `src/stores/mediaStore.ts` — 매니페스트 (앱 스냅샷 → 실행 시 버킷에서 갱신 → 기기에 저장)
- `src/components/ExerciseMedia.tsx` — 영상을 받는 동안 썸네일로 덮고, 첫 프레임이 그려지면 걷는다.
  오프라인이면 썸네일이 남는다. iOS·Android 는 `useCaching` 으로 한 번 받은 영상을 기기에 저장.

## 참고 수치 (가슴 30개)

원본 165MB → 11.6MB, 클립 평균 394KB (약 15분의 1).
CRF 23 은 원본과 눈으로 구분하기 어려웠고, 26 부터 근육 결이 뭉개지기 시작했다.
