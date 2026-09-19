/**
 * 운동 미디어 레지스트리
 * ───────────────────────────────────────────────────────────────────────────
 * React Native 의 require() 는 정적 경로만 허용하므로, 파일이 준비될 때마다
 * 아래 맵에 한 줄씩 추가하는 방식으로 관리한다. (동적 require 불가)
 *
 * 파일 규칙
 *   영상    assets/exercise/video/{exerciseId}.mp4   — 720x720, CRF 30, 무음, 3~8초 루프
 *   포스터  assets/exercise/image/{exerciseId}.jpg   — 512x512 JPEG (영상 첫 프레임)
 *
 * 인코딩 명령 (원본 -> 배포본)
 *   ffmpeg -i src.mp4 -vf scale=720:720:flags=lanczos -c:v libx264 -profile:v main \
 *          -crf 30 -preset slow -pix_fmt yuv420p -an -movflags +faststart -g 24 {id}.mp4
 *   ffmpeg -ss 0.5 -i src.mp4 -vframes 1 -vf scale=512:512 -q:v 4 {id}.jpg
 *
 * 목록/그리드는 포스터(EX_IMAGE), 상세 화면은 영상(EX_VIDEO)을 사용한다.
 * 누락 목록은 `npm run media:report` 로 확인.
 */

export const EX_VIDEO: Record<string, number> = {
  // 가슴 30종 — 전량 등록 완료
  pushup: require('../../assets/exercise/video/pushup.mp4'),
  widepushup: require('../../assets/exercise/video/widepushup.mp4'),
  diamondpushup: require('../../assets/exercise/video/diamondpushup.mp4'),
  declinepushup: require('../../assets/exercise/video/declinepushup.mp4'),
  inclinepushup: require('../../assets/exercise/video/inclinepushup.mp4'),
  bench: require('../../assets/exercise/video/bench.mp4'),
  inclinebench: require('../../assets/exercise/video/inclinebench.mp4'),
  declinebench: require('../../assets/exercise/video/declinebench.mp4'),
  dbbench: require('../../assets/exercise/video/dbbench.mp4'),
  incdbpress: require('../../assets/exercise/video/incdbpress.mp4'),
  decdbpress: require('../../assets/exercise/video/decdbpress.mp4'),
  dbfly: require('../../assets/exercise/video/dbfly.mp4'),
  incdbfly: require('../../assets/exercise/video/incdbfly.mp4'),
  crossover: require('../../assets/exercise/video/crossover.mp4'),
  lowcablefly: require('../../assets/exercise/video/lowcablefly.mp4'),
  highcablefly: require('../../assets/exercise/video/highcablefly.mp4'),
  pecdeck: require('../../assets/exercise/video/pecdeck.mp4'),
  chestpressmc: require('../../assets/exercise/video/chestpressmc.mp4'),
  dipschest: require('../../assets/exercise/video/dipschest.mp4'),
  smithbench: require('../../assets/exercise/video/smithbench.mp4'),
  svend: require('../../assets/exercise/video/svend.mp4'),
  floorpress: require('../../assets/exercise/video/floorpress.mp4'),
  pikepushup: require('../../assets/exercise/video/pikepushup.mp4'),
  archerpushup: require('../../assets/exercise/video/archerpushup.mp4'),
  plyopushup: require('../../assets/exercise/video/plyopushup.mp4'),
  spiderpushup: require('../../assets/exercise/video/spiderpushup.mp4'),
  hindupushup: require('../../assets/exercise/video/hindupushup.mp4'),
  revbench: require('../../assets/exercise/video/revbench.mp4'),
  squeezepress: require('../../assets/exercise/video/squeezepress.mp4'),
  guillotine: require('../../assets/exercise/video/guillotine.mp4'),
  // 등 · 하체 · 어깨 · 팔 · 복근 — 준비되는 대로 추가
};

export const EX_IMAGE: Record<string, number> = {
  // 가슴 30종 포스터 (영상 첫 프레임)
  pushup: require('../../assets/exercise/image/pushup.jpg'),
  widepushup: require('../../assets/exercise/image/widepushup.jpg'),
  diamondpushup: require('../../assets/exercise/image/diamondpushup.jpg'),
  declinepushup: require('../../assets/exercise/image/declinepushup.jpg'),
  inclinepushup: require('../../assets/exercise/image/inclinepushup.jpg'),
  bench: require('../../assets/exercise/image/bench.jpg'),
  inclinebench: require('../../assets/exercise/image/inclinebench.jpg'),
  declinebench: require('../../assets/exercise/image/declinebench.jpg'),
  dbbench: require('../../assets/exercise/image/dbbench.jpg'),
  incdbpress: require('../../assets/exercise/image/incdbpress.jpg'),
  decdbpress: require('../../assets/exercise/image/decdbpress.jpg'),
  dbfly: require('../../assets/exercise/image/dbfly.jpg'),
  incdbfly: require('../../assets/exercise/image/incdbfly.jpg'),
  crossover: require('../../assets/exercise/image/crossover.jpg'),
  lowcablefly: require('../../assets/exercise/image/lowcablefly.jpg'),
  highcablefly: require('../../assets/exercise/image/highcablefly.jpg'),
  pecdeck: require('../../assets/exercise/image/pecdeck.jpg'),
  chestpressmc: require('../../assets/exercise/image/chestpressmc.jpg'),
  dipschest: require('../../assets/exercise/image/dipschest.jpg'),
  smithbench: require('../../assets/exercise/image/smithbench.jpg'),
  svend: require('../../assets/exercise/image/svend.jpg'),
  floorpress: require('../../assets/exercise/image/floorpress.jpg'),
  pikepushup: require('../../assets/exercise/image/pikepushup.jpg'),
  archerpushup: require('../../assets/exercise/image/archerpushup.jpg'),
  plyopushup: require('../../assets/exercise/image/plyopushup.jpg'),
  spiderpushup: require('../../assets/exercise/image/spiderpushup.jpg'),
  hindupushup: require('../../assets/exercise/image/hindupushup.jpg'),
  revbench: require('../../assets/exercise/image/revbench.jpg'),
  squeezepress: require('../../assets/exercise/image/squeezepress.jpg'),
  guillotine: require('../../assets/exercise/image/guillotine.jpg'),

  // 영상이 아직 없는 종목 — 기존 일러스트 사용
  deadlift: require('../../assets/form/form_dead.png'),
  latpull: require('../../assets/form/form_latpull.png'),
  latraise: require('../../assets/form/form_latraise.png'),
  ohp: require('../../assets/form/form_ohp.png'),
  plank: require('../../assets/form/form_plank.png'),
  pullup: require('../../assets/form/form_pullup.png'),
  pushdown: require('../../assets/form/form_pushdown.png'),
  cablerow: require('../../assets/form/form_row.png'),
  backsquat: require('../../assets/form/form_squat.png'),
  uprow: require('../../assets/form/form_uprow.png'),
};

export const hasVideo = (id: string): boolean => id in EX_VIDEO;
export const getVideo = (id: string): number | undefined => EX_VIDEO[id];
export const getImage = (id: string): number | undefined => EX_IMAGE[id];

export const VIDEO_COUNT = Object.keys(EX_VIDEO).length;

