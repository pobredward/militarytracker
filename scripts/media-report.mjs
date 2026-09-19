#!/usr/bin/env node
/**
 * 운동 미디어(3~5초 클립 / 썸네일) 등록 현황 리포트
 *   node scripts/media-report.mjs
 *   node scripts/media-report.mjs --missing   (누락 id 만 출력)
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

const exSrc = readFileSync(join(root, 'src/data/exercises.ts'), 'utf8');
const mediaSrc = readFileSync(join(root, 'src/data/media.ts'), 'utf8');

const exercises = [...exSrc.matchAll(/\{\s*id:\s*'([^']+)'\s*,\s*n:\s*'([^']+)'\s*,\s*part:\s*'([^']+)'/g)]
  .map(([, id, n, part]) => ({ id, n, part }));

function registered(block) {
  const m = mediaSrc.match(new RegExp(`export const EX_${block}[^{]*\\{([\\s\\S]*?)\\n\\};`));
  if (!m) return new Set();
  return new Set([...m[1].matchAll(/^\s*([A-Za-z0-9_]+)\s*:/gm)].map(([, k]) => k));
}

const videos = registered('VIDEO');
const images = registered('IMAGE');

const missing = exercises.filter((e) => !videos.has(e.id) && !images.has(e.id));
const onlyImage = exercises.filter((e) => !videos.has(e.id) && images.has(e.id));

if (process.argv.includes('--missing')) {
  missing.forEach((e) => console.log(e.id));
  process.exit(0);
}

const byPart = {};
exercises.forEach((e) => {
  byPart[e.part] ??= { total: 0, video: 0, image: 0 };
  byPart[e.part].total++;
  if (videos.has(e.id)) byPart[e.part].video++;
  if (images.has(e.id)) byPart[e.part].image++;
});

console.log('\n  MilitaryTracker 미디어 현황');
console.log('  ─────────────────────────────────────────────');
console.log(`  종목 ${exercises.length}개 · 영상 ${videos.size}개 · 이미지 ${images.size}개\n`);
console.log('  부위        종목   영상   이미지');
Object.entries(byPart).forEach(([part, v]) => {
  console.log(`  ${part.padEnd(11)} ${String(v.total).padStart(3)}  ${String(v.video).padStart(5)}  ${String(v.image).padStart(6)}`);
});

console.log(`\n  영상 없음(이미지만): ${onlyImage.length}개`);
console.log(`  미디어 전무: ${missing.length}개`);
console.log('\n  파일 규칙');
console.log('    영상   assets/exercise/video/{id}.mp4   (3~5초, 무음, 1:1)');
console.log('    썸네일 assets/exercise/image/{id}.png   (1:1, 512px 이하)');
console.log('    등록   src/data/media.ts 의 EX_VIDEO / EX_IMAGE 에 한 줄 추가\n');
