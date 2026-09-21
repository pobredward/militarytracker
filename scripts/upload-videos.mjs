#!/usr/bin/env node
/**
 * 운동 영상 인코딩 + 서울 버킷 업로드 + 매니페스트 갱신
 *
 *   npm run media:upload -- <부위> [--dry] [--crf 23]
 *   예) npm run media:upload -- back --dry     ← 매칭표만 확인
 *       npm run media:upload -- back           ← 인코딩·업로드
 *
 * 원본은 media/originals/<부위>/ 에 넣는다 (git 에 안 들어감, media/README.md).
 * 다른 폴더를 쓰려면: node scripts/upload-videos.mjs <폴더> <부위>
 *
 * 부위: chest back legs shoulders biceps triceps abs
 *
 * 파일 → 종목 매칭 (위에서부터)
 *   1) 파일명이 종목 id 그대로          "svend.mp4"
 *   2) 번호 뒤에 종목 id               "21.svend.mp4"
 *   3) 파일명 앞 번호 = 그 부위의 N번째  "21.Svend Press (1).mp4" → 가슴 21번째 = svend
 *   번호는 exercises.ts 에 적힌 순서다. 먼저 --dry 로 매칭표를 확인할 것.
 *   업로드한 원본은 "21.svend.mp4" 형식으로 이름이 정리된다.
 *
 * 하는 일
 *   원본 → 1080x1080 H.264(무음, faststart) → exercise/video/{id}.mp4
 *        → 512x512 첫 프레임 JPEG          → exercise/poster/{id}.jpg
 *   업로드 후 exercise/manifest.json 과 src/data/mediaManifest.json 을 같은 내용으로 갱신.
 *   앱은 실행할 때 버킷의 매니페스트를 읽으므로 앱 업데이트 없이 바로 반영된다.
 *   src/data/mediaManifest.json 은 커밋해 둘 것 (첫 실행·오프라인용 스냅샷).
 *
 * 인증: 환경변수 GCS_TOKEN, 없으면 firebase CLI 로그인 토큰(~/.config/configstore).
 * 필요: ffmpeg, node 22+
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync, renameSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join, extname, basename, resolve } from 'node:path';
import { homedir } from 'node:os';
import { randomUUID } from 'node:crypto';

const BUCKET = 'military-tracker-96bdd'; // 서울(asia-northeast3)
const PARTS = ['chest', 'back', 'legs', 'shoulders', 'biceps', 'triceps', 'abs'];
const DEFAULT_CRF = 23;
const IMMUTABLE = 'public, max-age=31536000, immutable'; // URL 에 generation 이 들어가므로 안전
const NO_CACHE = 'no-cache, max-age=0';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const work = join(root, '.cache', 'media');

// ─── 인자 ──────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const flag = (k) => args.includes(k);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const pos = args.filter((a, i) => !a.startsWith('--') && args[i - 1] !== '--crf');
// 인자가 하나면 부위 — media/originals/<부위> 를 쓴다
const [srcDirArg, part] = pos.length === 1 ? [join(root, 'media', 'originals', pos[0]), pos[0]] : pos;
const DRY = flag('--dry');
const CRF = Number(opt('--crf', DEFAULT_CRF));

if (!srcDirArg || !PARTS.includes(part) || !Number.isFinite(CRF)) {
  console.error(`사용법: npm run media:upload -- <${PARTS.join('|')}> [--dry] [--crf ${DEFAULT_CRF}]`);
  process.exit(1);
}
const srcDir = resolve(srcDirArg.replace(/^~(?=$|\/)/, homedir()));
if (!existsSync(srcDir)) {
  console.error(`폴더가 없습니다: ${srcDir}`);
  process.exit(1);
}

// ─── 종목 목록 (exercises.ts 순서) ─────────────────────────────────────────
const exSrc = readFileSync(join(root, 'src/data/exercises.ts'), 'utf8');
const all = [...exSrc.matchAll(/\{\s*id:\s*'([^']+)'\s*,\s*n:\s*'([^']+)'\s*,\s*part:\s*'([^']+)'/g)]
  .map(([, id, n, p]) => ({ id, n, part: p }));
const ordered = all.filter((e) => e.part === part);
const byId = new Map(ordered.map((e) => [e.id, e]));

// ─── 파일 매칭 ─────────────────────────────────────────────────────────────
const files = readdirSync(srcDir)
  .filter((f) => /\.(mp4|mov|m4v)$/i.test(f) && !f.startsWith('.'))
  .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }));

const plan = [];
const unmatched = [];
for (const f of files) {
  const stem = basename(f, extname(f));
  let ex = byId.get(stem);
  if (!ex) {
    const named = stem.match(/^\d+[.\-_ ]+([A-Za-z0-9_]+)$/);
    if (named) ex = byId.get(named[1]);
  }
  if (!ex) {
    const m = stem.match(/^(\d+)/);
    if (m) ex = ordered[Number(m[1]) - 1];
  }
  if (ex) plan.push({ file: f, ex, n: ordered.indexOf(ex) + 1 });
  else unmatched.push(f);
}

const dupes = plan.filter((p, i) => plan.findIndex((q) => q.ex.id === p.ex.id) !== i);
console.log(`\n${part} — 종목 ${ordered.length}개, 파일 ${files.length}개, 매칭 ${plan.length}개\n`);
for (const p of plan) console.log(`  ${p.file.padEnd(40)} → ${p.ex.id.padEnd(16)} ${p.ex.n}`);
if (unmatched.length) console.log(`\n  매칭 안 됨: ${unmatched.join(', ')}`);
if (dupes.length) {
  console.error(`\n같은 종목에 파일이 둘 이상: ${dupes.map((d) => d.ex.id).join(', ')}`);
  process.exit(1);
}
if (DRY || !plan.length) process.exit(0);

// 원본 이름 정리: "21.Svend Press (1).mp4" → "21.svend.mp4"
// 180개가 쌓였을 때 어느 파일이 어느 종목인지 이름만 보고 알 수 있게.
for (const p of plan) {
  const want = `${String(p.n).padStart(2, '0')}.${p.ex.id}${extname(p.file).toLowerCase()}`;
  if (want !== p.file && !existsSync(join(srcDir, want))) {
    renameSync(join(srcDir, p.file), join(srcDir, want));
    p.file = want;
  }
}

// ─── 인증 ──────────────────────────────────────────────────────────────────
function token() {
  if (process.env.GCS_TOKEN) return process.env.GCS_TOKEN;
  const p = join(homedir(), '.config/configstore/firebase-tools.json');
  const read = () => JSON.parse(readFileSync(p, 'utf8')).tokens ?? {};
  let t = read();
  // 만료 5분 전이면 firebase CLI 로 갱신시킨다 (아무 인증 명령이나 토큰을 새로 받는다)
  if (!t.access_token || (t.expires_at ?? 0) < Date.now() + 5 * 60_000) {
    spawnSync('npx', ['--yes', 'firebase-tools@latest', 'projects:list'], { stdio: 'ignore' });
    t = read();
  }
  if (!t.access_token) throw new Error('토큰 없음 — firebase login 또는 GCS_TOKEN 설정');
  return t.access_token;
}
const TOKEN = token();
const auth = { Authorization: `Bearer ${TOKEN}` };

async function upload(name, buf, contentType, cacheControl) {
  const boundary = `mt${randomUUID()}`;
  const meta = JSON.stringify({ name, contentType, cacheControl });
  const body = Buffer.concat([
    Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${meta}\r\n--${boundary}\r\nContent-Type: ${contentType}\r\n\r\n`),
    buf,
    Buffer.from(`\r\n--${boundary}--\r\n`),
  ]);
  const res = await fetch(`https://storage.googleapis.com/upload/storage/v1/b/${BUCKET}/o?uploadType=multipart`, {
    method: 'POST',
    headers: { ...auth, 'Content-Type': `multipart/related; boundary=${boundary}` },
    body,
  });
  if (!res.ok) throw new Error(`${name} 업로드 실패 ${res.status}: ${(await res.text()).slice(0, 300)}`);
  return String((await res.json()).generation);
}

// ─── 인코딩 ────────────────────────────────────────────────────────────────
function ffmpeg(argv) {
  const r = spawnSync('ffmpeg', ['-v', 'error', '-y', ...argv], { encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`ffmpeg 실패: ${r.stderr}`);
}

// 가운데를 정사각형으로 자르고 1080 이하로 줄인다 (작은 원본은 키우지 않는다)
const VF = "crop='min(iw,ih)':'min(iw,ih)',scale='trunc(min(1080,iw)/2)*2':-2:flags=lanczos";

function encode(src, id) {
  mkdirSync(work, { recursive: true });
  const mp4 = join(work, `${id}.mp4`);
  const jpg = join(work, `${id}.jpg`);
  const fresh = (f) => existsSync(f) && statSync(f).mtimeMs > statSync(src).mtimeMs;
  if (!fresh(mp4)) {
    ffmpeg(['-i', src, '-vf', VF, '-c:v', 'libx264', '-profile:v', 'high', '-crf', String(CRF),
      '-preset', 'slow', '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart', '-g', '60', mp4]);
  }
  if (!fresh(jpg)) {
    ffmpeg(['-ss', '0.5', '-i', mp4, '-frames:v', '1', '-vf', 'scale=512:512:flags=lanczos', '-q:v', '4', jpg]);
  }
  return { mp4, jpg };
}

// ─── 실행 ──────────────────────────────────────────────────────────────────
const kb = (n) => `${(n / 1024).toFixed(0)}KB`;
const results = {};
let before = 0, after = 0;

console.log(`\n인코딩·업로드 (CRF ${CRF}) → gs://${BUCKET}\n`);
for (const { file, ex } of plan) {
  const src = join(srcDir, file);
  const { mp4, jpg } = encode(src, ex.id);
  const mBuf = readFileSync(mp4);
  const video = await upload(`exercise/video/${ex.id}.mp4`, mBuf, 'video/mp4', IMMUTABLE);
  const poster = await upload(`exercise/poster/${ex.id}.jpg`, readFileSync(jpg), 'image/jpeg', IMMUTABLE);
  results[ex.id] = { video, poster };
  before += statSync(src).size;
  after += mBuf.length;
  console.log(`  ✓ ${ex.id.padEnd(16)} ${kb(statSync(src).size).padStart(7)} → ${kb(mBuf.length).padStart(6)}`);
}

// ─── 매니페스트 병합 ───────────────────────────────────────────────────────
const MANIFEST = 'exercise/manifest.json';
let manifest = { updatedAt: '', items: {} };
const cur = await fetch(`https://storage.googleapis.com/storage/v1/b/${BUCKET}/o/${encodeURIComponent(MANIFEST)}?alt=media`, { headers: auth });
if (cur.ok) manifest = await cur.json();
else if (cur.status !== 404) throw new Error(`매니페스트 읽기 실패 ${cur.status}`);

manifest.items = { ...manifest.items, ...results };
manifest.updatedAt = new Date().toISOString();
// id 순서를 exercises.ts 순서로 정렬해 diff 를 읽기 쉽게
const rank = new Map(all.map((e, i) => [e.id, i]));
manifest.items = Object.fromEntries(
  Object.entries(manifest.items).sort(([a], [b]) => (rank.get(a) ?? 1e9) - (rank.get(b) ?? 1e9))
);
const json = JSON.stringify(manifest, null, 2) + '\n';
await upload(MANIFEST, Buffer.from(json), 'application/json', NO_CACHE);
writeFileSync(join(root, 'src/data/mediaManifest.json'), json);

const total = Object.values(manifest.items).filter((e) => e.video).length;
console.log(`\n완료: ${plan.length}개 업로드 · 원본 ${kb(before)} → ${kb(after)} (클립 평균 ${kb(after / plan.length)})`);
console.log(`매니페스트 영상 ${total}개 · src/data/mediaManifest.json 갱신됨 — 커밋할 것\n`);
