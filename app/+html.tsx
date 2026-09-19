import { ScrollViewStyleReset } from 'expo-router/html';
import type { PropsWithChildren } from 'react';

/**
 * 웹 전용 HTML 셸. 네이티브 빌드에는 포함되지 않는다.
 * 모바일 뷰포트 고정, 다크 배경, 바운스 스크롤 차단.
 */
export default function Root({ children }: PropsWithChildren) {
  return (
    <html lang="ko">
      <head>
        <meta charSet="utf-8" />
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover"
        />
        <meta name="theme-color" content="#09090A" />
        <meta name="color-scheme" content="dark" />

        <title>밀리터리트래커</title>
        <meta name="description" content="검증된 자세 가이드 위에서 기록하는 트레이닝 앱" />
        <meta property="og:title" content="밀리터리트래커" />
        <meta property="og:description" content="검증된 자세 가이드 위에서 기록하는 트레이닝 앱" />
        <meta property="og:type" content="website" />

        {/* RN Web 의 스크롤 컨테이너 기본값 리셋 */}
        <ScrollViewStyleReset />

        <style dangerouslySetInnerHTML={{ __html: css }} />
      </head>
      <body>{children}</body>
    </html>
  );
}

const css = `
html, body, #root {
  height: 100%;
  margin: 0;
  background-color: #050506;
  color-scheme: dark;
}
body {
  overscroll-behavior: none;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-family: -apple-system, BlinkMacSystemFont, 'Apple SD Gothic Neo', 'Pretendard',
    'Noto Sans KR', 'Segoe UI', Roboto, sans-serif;
}
/* 프레임 안에서 스크롤바가 레이아웃을 흔들지 않도록 */
::-webkit-scrollbar { width: 0; height: 0; }
* { scrollbar-width: none; }
input, textarea { font-family: inherit; }
`;
