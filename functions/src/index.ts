/**
 * MilitaryTracker — AI 프록시 (Cloud Functions v2, asia-northeast3)
 *
 * 앱은 Anthropic API 를 직접 호출하지 않는다. 키는 Secret Manager 에만 존재한다.
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 *   firebase deploy --only functions
 *
 * secret 버전을 지운 뒤에는 반드시 함수를 재배포해야 한다. 각 함수는 배포
 * 시점의 secret 버전에 고정되며, CLI 는 소스 해시가 같으면 배포를 건너뛴다.
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import * as logger from 'firebase-functions/logger';
import { requirePro, loadAccount } from './entitlement';
import { checkCoachQuota, recordCoachUse } from './quota';

const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');

setGlobalOptions({ region: 'asia-northeast3', maxInstances: 10 });

// 구독 콜러블 — users/{uid}.sub 를 바꿀 수 있는 유일한 경로
export {
  subStatus, subStartTrial, subRedeemPromo, subGrant, subApplyReceipt,
} from './subscription';

// 기능마다 성격이 달라 모델을 나눈다.
//  플랜·식단: 한 번에 유효한 JSON 을 만들어야 해서 정확도가 중요하고 호출이 드물다.
//  코치:      짧은 대화라 호출이 압도적으로 많다 — 여기가 원가의 대부분이다.
//             Haiku 로 내리면 호출당 원가가 절반 이하가 된다.
const MODEL_PLANNING = 'claude-sonnet-4-5';
const MODEL_CHAT = 'claude-haiku-4-5-20251001';
const API_URL = 'https://api.anthropic.com/v1/messages';
const API_VERSION = '2023-06-01';

interface AnthropicMessage {
  role: 'user' | 'assistant';
  content: string;
}

async function callAnthropic(opts: {
  system: string;
  messages: AnthropicMessage[];
  maxTokens: number;
  apiKey: string;
  model: string;
}): Promise<string> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 55_000);

  try {
    const res = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': opts.apiKey,
        'anthropic-version': API_VERSION,
      },
      body: JSON.stringify({
        model: opts.model,
        max_tokens: opts.maxTokens,
        system: opts.system,
        messages: opts.messages,
      }),
      signal: controller.signal,
    });

    if (!res.ok) {
      const body = await res.text();
      logger.error('anthropic error', { status: res.status, body: body.slice(0, 500) });
      throw new HttpsError('unavailable', `AI 응답 실패 (${res.status})`);
    }

    const data = (await res.json()) as { content?: { type: string; text?: string }[] };
    return (data.content ?? [])
      .filter((c) => c.type === 'text')
      .map((c) => c.text ?? '')
      .join('')
      .trim();
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    logger.error('anthropic fetch failed', e);
    throw new HttpsError('unavailable', 'AI 서버에 연결하지 못했습니다.');
  } finally {
    clearTimeout(timeout);
  }
}

/** 코드펜스가 섞여 와도 첫 JSON 객체만 뽑아낸다 */
function parseJson<T>(raw: string): T {
  const clean = raw.replace(/```json|```/g, '').trim();
  const start = clean.indexOf('{');
  const end = clean.lastIndexOf('}');
  if (start < 0 || end < 0) throw new HttpsError('internal', 'AI 응답 형식 오류');
  try {
    return JSON.parse(clean.slice(start, end + 1)) as T;
  } catch {
    throw new HttpsError('internal', 'AI 응답 파싱 실패');
  }
}

function requireAuth(req: CallableRequest): string {
  if (!req.auth?.uid) throw new HttpsError('unauthenticated', '로그인이 필요합니다.');
  return req.auth.uid;
}

const str = (v: unknown, max = 200): string => String(v ?? '').slice(0, max);
const int = (v: unknown, fallback = 0): number => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.round(n) : fallback;
};

// ─── 1. 운동 플랜 ───────────────────────────────────────────────────────────
interface PlanReq {
  profile: {
    sex: string; age: string; height: string; weight: string;
    goal: string; env: string; days: number; level: number;
  };
  catalog: string;
}

export const aiPlan = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60, memory: '256MiB' },
  async (req: CallableRequest<PlanReq>) => {
    // 유료 기능 — 앱의 잠금 UI 를 우회해도 여기서 끊긴다
    await requirePro(requireAuth(req), 'ai_plan');
    const p = req.data?.profile;
    const catalog = str(req.data?.catalog, 12000);
    if (!p || !catalog) throw new HttpsError('invalid-argument', '요청 정보가 부족합니다.');

    const goalMap: Record<string, string> = {
      muscle: '근성장', cut: '체지방 감량', habit: '운동 습관 만들기',
    };
    const levelMap: Record<number, string> = { 1: '입문', 2: '중급', 3: '상급' };
    const days = Math.min(6, Math.max(2, int(p.days, 3)));
    const perDay = p.goal === 'habit' ? 3 : 5;

    const prompt = [
      `사용자: ${p.sex === 'male' ? '남' : '여'} ${str(p.age, 4)}세 / ${str(p.height, 6)}cm ${str(p.weight, 6)}kg`,
      `목표: ${goalMap[p.goal] ?? '근성장'} / 환경: ${p.env === 'gym' ? '헬스장' : '홈트'} / 주 ${days}일 / 수준: ${levelMap[int(p.level, 1)] ?? '입문'}`,
      '',
      `아래 목록의 id 만 사용해 주 ${days}일 분할 루틴을 만들어라. 하루 ${perDay}종목.`,
      '큰 근육 → 작은 근육 순서로 배치하고, 같은 부위가 연속된 데이에 겹치지 않게 하라.',
      '',
      `운동 목록(id|이름|부위|난이도):`,
      catalog,
      '',
      '출력 형식(JSON만):',
      '{"days":[{"id":"push","name":"푸시데이","focus":"가슴·어깨·삼두","ids":["bench","..."]}],"reason":"이 분할을 추천한 이유 한 문장"}',
    ].join('\n');

    const raw = await callAnthropic({
      system: '너는 근거 기반 운동 프로그램 설계 AI다. 반드시 유효한 JSON 객체만 출력한다. 마크다운, 백틱, 설명 텍스트 금지.',
      messages: [{ role: 'user', content: prompt }],
      maxTokens: 1500,
      model: MODEL_PLANNING,
      apiKey: ANTHROPIC_API_KEY.value(),
    });

    return parseJson(raw);
  }
);

// ─── 2. 식단 ────────────────────────────────────────────────────────────────
interface DietReq {
  bodyType: string; goal: string;
  kcal: number; protein: number; carb: number; fat: number;
  foodEnv: string; allergy: string;
}

export const aiDiet = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60, memory: '256MiB' },
  async (req: CallableRequest<DietReq>) => {
    await requirePro(requireAuth(req), 'ai_diet');
    const d = req.data;
    if (!d) throw new HttpsError('invalid-argument', '요청 정보가 부족합니다.');

    const prompt = [
      `사용자: ${str(d.bodyType, 30)}, 목표 ${str(d.goal, 30)}`,
      `하루 ${int(d.kcal, 2000)}kcal / 단백질 ${int(d.protein, 120)}g / 탄수 ${int(d.carb, 200)}g / 지방 ${int(d.fat, 60)}g`,
      `식사 환경: ${str(d.foodEnv, 30)} / 알레르기·제외: ${str(d.allergy, 120)}`,
      '한국에서 구하기 쉬운 음식으로 하루 식단(아침/점심/저녁/간식)을 구성하라.',
      '출력: {"meals":[{"t":"아침","m":"음식 구성","k":"약 500kcal · 단백질 30g"}],"tip":"한 줄 팁"}',
    ].join('\n');

    const raw = await callAnthropic({
      system: '너는 스포츠 영양 가이드 AI다. 반드시 유효한 JSON만 출력한다. 마크다운 금지. 의학적 진단이나 치료 조언은 하지 않는다.',
      messages: [{ role: 'user', content: prompt }],
      maxTokens: 1000,
      model: MODEL_PLANNING,
      apiKey: ANTHROPIC_API_KEY.value(),
    });

    return parseJson(raw);
  }
);

// ─── 3. 코치 ────────────────────────────────────────────────────────────────
interface CoachReq {
  messages: AnthropicMessage[];
  context: string;
}

export const aiCoach = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60, memory: '256MiB' },
  async (req: CallableRequest<CoachReq>) => {
    const uid = requireAuth(req);
    await requirePro(uid, 'ai_coach');
    // 한도 확인을 먼저 — AI 를 부르고 나서 막으면 원가만 나간다
    const quota = await checkCoachQuota(uid, (await loadAccount(uid)).isAdmin);
    const incoming = Array.isArray(req.data?.messages) ? req.data.messages : [];
    if (!incoming.length) throw new HttpsError('invalid-argument', '메시지가 비어 있습니다.');

    // 최근 20턴만, 각 4000자 제한
    const messages: AnthropicMessage[] = incoming.slice(-20).map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: str(m.content, 4000),
    }));
    if (messages[0].role !== 'user') messages.shift();
    if (!messages.length) throw new HttpsError('invalid-argument', '메시지가 비어 있습니다.');

    const system = [
      "너는 피트니스 앱 'MILITARYTRACKER'의 AI 코치다. 짧고, 데이터 기반, 단정적이되 과장 없음. AI 필러 문구 금지.",
      str(req.data?.context, 4000),
      // Haiku 는 Sonnet 보다 지시를 덜 촘촘하게 따르므로 규칙을 더 명시적으로 쓴다
      '규칙:',
      '1) 3~5문장 이내. 길어지면 잘라서 핵심만.',
      '2) 목록·머리말·인사말 금지. 바로 답부터.',
      '3) 의학 진단 금지. 통증을 말하면 전문가 상담을 안내한다.',
      '4) 한국어. 위 데이터에 있는 수치만 인용하고 없는 기록을 지어내지 않는다.',
    ].join('\n');

    const reply = await callAnthropic({
      system,
      messages,
      maxTokens: 800,
      apiKey: ANTHROPIC_API_KEY.value(),
      model: MODEL_CHAT,
    });

    // 응답이 온 뒤에만 차감한다
    return { reply, quota: await recordCoachUse(uid, quota) };
  }
);
