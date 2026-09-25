/**
 * Firebase 웹 설정 — 공개 값이다.
 *
 * 이 값들은 비밀이 아니다. Firebase 문서가 명시하듯 앱 번들과 웹 페이지에
 * 그대로 실리며(military-tracker-96bdd.web.app 소스에서 누구나 볼 수 있다),
 * 실제 접근 통제는 Firestore/Storage 보안 규칙과 API 키 제한이 한다.
 *
 * 왜 코드에 두는가: `.env` 는 gitignore 라 EAS 빌드 서버에 올라가지 않고,
 * Expo 대시보드 환경변수도 비어 있으면 프로덕션 빌드가 `undefined` 설정으로
 * 시작 즉시 죽는다. 공개 값을 환경변수로만 두는 건 이득 없이 실패 지점만 늘린다.
 * `.env` 의 EXPO_PUBLIC_FIREBASE_* 가 있으면 그쪽이 우선한다(다른 프로젝트로 바꿀 때).
 *
 * 해야 할 것(콘솔): GCP → API 및 서비스 → 사용자 인증 정보 → 이 키를
 * iOS 번들 ID / Android 패키지+SHA / 웹 referrer 로 제한한다.
 */
export const FIREBASE_PUBLIC_CONFIG = {
  apiKey: 'AIzaSyB-7VGiz2o0fcC_2fTDODvpnewTg0MB3WA',
  authDomain: 'military-tracker-96bdd.firebaseapp.com',
  projectId: 'military-tracker-96bdd',
  storageBucket: 'military-tracker-96bdd.firebasestorage.app',
  messagingSenderId: '958822539189',
  appId: '1:958822539189:web:ed01459156a726861803fc',
} as const;
