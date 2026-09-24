/**
 * 운동 미디어
 * ───────────────────────────────────────────────────────────────────────────
 * 영상은 앱에 넣지 않고 서울 버킷(asia-northeast3)에서 받아 기기에 캐시한다.
 * 무엇이 올라가 있는지는 버킷의 exercise/manifest.json 이 알려 주므로,
 * 영상을 추가·교체해도 앱 업데이트가 필요 없다 (src/stores/mediaStore.ts).
 *
 * 버킷 구조
 *   exercise/video/{id}.mp4    1080x1080 H.264, 무음, 루프용
 *   exercise/poster/{id}.jpg   512x512 첫 프레임
 *   exercise/manifest.json     { items: { [id]: { video, poster } } } — 값은 GCS generation
 *
 * 업로드: node scripts/upload-videos.mjs <원본폴더> <부위>
 *
 * URL 의 v= 에 generation 을 넣는다. 같은 이름으로 다시 올리면 generation 이
 * 바뀌어 URL 이 달라지므로 기기 캐시·브라우저 캐시가 자동으로 새 파일을 받는다.
 * 그래서 객체에는 Cache-Control: immutable 을 걸어 두었다.
 */
import type { ImageSourcePropType } from 'react-native';
import type { VideoSource } from 'expo-video';

export const MEDIA_BUCKET = 'military-tracker-96bdd';
const BASE = `https://firebasestorage.googleapis.com/v0/b/${MEDIA_BUCKET}/o`;

const objectUrl = (path: string, rev?: string): string =>
  `${BASE}/${encodeURIComponent(path)}?alt=media${rev ? `&v=${rev}` : ''}`;

export const MANIFEST_URL = objectUrl('exercise/manifest.json');
export const videoUrl = (id: string, rev: string) => objectUrl(`exercise/video/${id}.mp4`, rev);
export const posterUrl = (id: string, rev: string) => objectUrl(`exercise/poster/${id}.jpg`, rev);

/** 매니페스트 한 항목 — 값은 GCS generation (없으면 해당 미디어 없음) */
export interface MediaEntry {
  video?: string;
  poster?: string;
}

// 같은 소스 객체를 돌려줘야 useVideoPlayer 가 렌더마다 플레이어를 다시 만들지 않는다
const sourceCache = new Map<string, VideoSource>();

export function videoSource(id: string, rev: string): VideoSource {
  const key = `${id}@${rev}`;
  let src = sourceCache.get(key);
  if (!src) {
    // useCaching: iOS·Android 에서 한 번 받은 영상을 기기에 저장해 두고 재사용한다.
    // 웹은 브라우저 캐시가 같은 일을 한다.
    src = { uri: videoUrl(id, rev), useCaching: true };
    sourceCache.set(key, src);
  }
  return src;
}

/** 번들 썸네일이 있으면 그걸(즉시 표시), 없으면 버킷 썸네일 */
export function posterSource(id: string, entry?: MediaEntry): ImageSourcePropType | null {
  const local = EX_IMAGE[id];
  if (local) return local;
  if (entry?.poster) return { uri: posterUrl(id, entry.poster) };
  return null;
}

/**
 * 앱에 함께 들어가는 썸네일 — 자세 탭 그리드가 네트워크 없이 즉시 뜨도록.
 * 새 종목은 여기 추가하지 않아도 버킷 썸네일(exercise/poster)로 표시된다.
 */
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
  deadlift: require('../../assets/form/form_dead.webp'),
  latpull: require('../../assets/form/form_latpull.webp'),
  latraise: require('../../assets/form/form_latraise.webp'),
  ohp: require('../../assets/form/form_ohp.webp'),
  plank: require('../../assets/form/form_plank.webp'),
  pullup: require('../../assets/form/form_pullup.webp'),
  pushdown: require('../../assets/form/form_pushdown.webp'),
  cablerow: require('../../assets/form/form_row.webp'),
  backsquat: require('../../assets/form/form_squat.webp'),
  uprow: require('../../assets/form/form_uprow.webp'),
};
