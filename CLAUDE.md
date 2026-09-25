# MilitaryTracker — 작업 메모

Expo SDK 57 · React Native 0.86 · expo-router · TypeScript(strict) · Zustand · Firebase

## 검증

```bash
npx tsc --noEmit                  # 앱
cd functions && npm run build     # Cloud Functions
npx expo export --platform web    # 번들 스모크 테스트
npm run deploy:rules              # firestore + storage 규칙, 인덱스
npm run deploy:functions
npm run deploy:hosting            # 웹 export + hosting
```

## git push (Claude 세션용)

맥의 키체인은 Claude 가 도는 리눅스 VM에서 보이지 않는다.
대신 이 저장소 전용 **배포 키**를 `.git/claude_deploy_key` 에 두었다
(`.git` 내부라 커밋되지 않는다). push 는 이 명령으로 한다:

```bash
GIT_SSH_COMMAND="ssh -i $PWD/.git/claude_deploy_key -o IdentitiesOnly=yes" \
  git push git@github.com:pobredward/militarytracker.git main
git fetch origin        # origin/main 추적 참조 동기화 (위 push 는 갱신하지 않음)
```

원격 URL 은 일부러 HTTPS 그대로 두었다 — 맥에서 쓰던 `git push` 방식을 바꾸지 않기 위해서다.
키 폐기는 GitHub 저장소 Settings → Deploy keys 에서 삭제.

## 운동 영상 (media/README.md)

영상은 앱에 넣지 않는다. 서울 버킷 `gs://military-tracker-96bdd` 에 올리고 앱은
실행 시 `exercise/manifest.json` 을 읽는다 — 영상 추가에 앱 업데이트가 필요 없다.

```bash
npm run media:upload -- <부위> --dry   # 매칭표 먼저
npm run media:upload -- <부위>         # 인코딩(1080, CRF 23) · 업로드 · 매니페스트
```

- 원본은 `media/originals/<부위>/` (gitignored). **`assets/` 에 두면 git 에 들어간다.**
- 업로드 후 바뀐 `src/data/mediaManifest.json` 은 커밋한다 (오프라인 스냅샷).
- 버킷 CORS(`media/cors.json`)가 없으면 웹이 매니페스트를 못 읽는다. 버킷을 새로 만들면 재적용.
- Firebase Storage URL 은 GCS 직통보다 첫 바이트가 약 0.35초 느리다(측정: 0.5초 vs 0.15초).
  기기 캐시 덕에 첫 재생에만 해당한다.

## 주의할 것

- **가로 스크롤러에 `flexGrow: 0` 만 쓰지 말 것.** RN·RN-Web 의 `ScrollView`
  기본 스타일이 `{ flexGrow: 1, flexShrink: 1 }` 이라 `flexShrink: 1` 이 남고,
  같은 컬럼의 세로 리스트에 눌려 잘린다. 반드시 `flexShrink: 0` 을 함께 준다.
- **구독 경계선은 `src/config/entitlements.ts` 의 `PRO_FEATURES` 한 곳**에서 정한다.
  바꿀 때 `functions/src/entitlement.ts` 의 `Feature` 키도 같이 맞춘다.
  판정 로직도 `src/utils/subscription.ts` 와 `functions/src/entitlement.ts` 두 벌이다.
- **`users/{uid}.sub`·`usage`·`role` 은 Cloud Functions 만 쓴다.** 규칙은 이 필드의 추가·수정·**삭제**를
  전부 막는다(`diff().affectedKeys()`). `!('sub' in request.resource.data)` 식 검사는 `deleteField()` 를
  통과시키므로 쓰지 말 것. `users` 문서 삭제도 클라이언트에 없다 — 지우고 다시 만들면 같은 우회가 된다.
  AI 콜러블은 `requirePro` → `consumeQuota` 순서를 지킨다. 화면 잠금은 보조 수단일 뿐이다.
- **`functions/src/index.ts` 에서 `setGlobalOptions` 는 `export … from './subscription'` 보다 위에** 있어야
  sub*/accountDelete 도 리전·maxInstances 를 받는다(CommonJS `require` 는 소스 순서대로 실행된다).
  `subscription.ts` 는 순서에 기대지 않도록 `region`/`maxInstances` 를 따로 명시해 두었다.
- 배포는 **규칙 먼저, 함수 나중**. 순서를 바꾸면 그 사이에 클라이언트가 `sub` 를 쓸 수 있다.
- **Firebase 웹 설정은 `src/config/firebasePublic.ts` 에 커밋돼 있다.** 공개 값이다. `.env` 는 gitignore 라
  EAS 빌드에 실리지 않고, Expo 대시보드 환경변수도 비어 있어 프로덕션 빌드가 죽었었다.
- **`firebase.json` hosting `ignore` 에 `**/node_modules/**` 를 넣지 말 것.** Expo 웹 export 는 벡터 아이콘 폰트를
  `dist/assets/node_modules/...` 에 두는데 그 패턴에 걸려 배포에서 빠지고 탭 아이콘이 전부 깨진다.
- **secret 버전은 배포 시점에 함수에 고정된다.** 최신 버전을 쓸 거라고 가정하지 말 것.
  `functions:secrets:destroy KEY@N` 을 `--force` 없이 먼저 돌려 어떤 함수가 그 버전을
  쓰는지 경고를 읽고, 사용 중이면 함수를 먼저 재배포해 새 버전에 묶은 뒤 지운다.
  `functions:secrets:prune` 는 버전 단위로 정리해 주지 않는다.
  재배포는 소스 해시가 같으면 통째로 건너뛴다("No changes detected") — 바인딩만
  바꾸려면 소스를 한 줄이라도 바꿔야 한다.
