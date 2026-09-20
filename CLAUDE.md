# MilitaryTracker — 작업 메모

Expo SDK 57 · React Native 0.86 · expo-router · TypeScript(strict) · Zustand · Firebase

## 검증

```bash
npx tsc --noEmit                  # 앱
cd functions && npm run build     # Cloud Functions
npx expo export --platform web    # 번들 스모크 테스트
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

## 주의할 것

- **가로 스크롤러에 `flexGrow: 0` 만 쓰지 말 것.** RN·RN-Web 의 `ScrollView`
  기본 스타일이 `{ flexGrow: 1, flexShrink: 1 }` 이라 `flexShrink: 1` 이 남고,
  같은 컬럼의 세로 리스트에 눌려 잘린다. 반드시 `flexShrink: 0` 을 함께 준다.
- **구독 경계선은 `src/config/entitlements.ts` 의 `PRO_FEATURES` 한 곳**에서 정한다.
  바꿀 때 `functions/src/entitlement.ts` 의 `Feature` 키도 같이 맞춘다.
  판정 로직도 `src/utils/subscription.ts` 와 `functions/src/entitlement.ts` 두 벌이다.
- **`users/{uid}.sub` 는 Cloud Functions 만 쓴다.** 보안 규칙이 클라이언트 쓰기를 막고,
  AI 콜러블은 `requirePro` 를 먼저 통과해야 한다. 화면 잠금은 보조 수단일 뿐이다.
- **`functions/src/subscription.ts` 의 `onCall` 은 `region` 을 명시**해야 한다.
  `index.ts` 의 `setGlobalOptions` 는 import 된 모듈 본문보다 늦게 실행된다.
- 배포는 **규칙 먼저, 함수 나중**. 순서를 바꾸면 그 사이에 클라이언트가 `sub` 를 쓸 수 있다.
- **secret 버전은 배포 시점에 함수에 고정된다.** 최신 버전을 쓸 거라고 가정하지 말 것.
  `functions:secrets:destroy KEY@N` 을 `--force` 없이 먼저 돌려 어떤 함수가 그 버전을
  쓰는지 경고를 읽고, 사용 중이면 함수를 먼저 재배포해 새 버전에 묶은 뒤 지운다.
  `functions:secrets:prune` 는 버전 단위로 정리해 주지 않는다.
  재배포는 소스 해시가 같으면 통째로 건너뛴다("No changes detected") — 바인딩만
  바꾸려면 소스를 한 줄이라도 바꿔야 한다.
