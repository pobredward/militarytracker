/**
 * 구독 콜러블.
 *
 * users/{uid}.sub 를 바꿀 수 있는 경로는 이 파일뿐이다.
 * 보안 규칙이 클라이언트의 sub 쓰기를 막고 있으므로,
 * 앱을 뜯어 고쳐도 스스로 PRO 가 될 수 없다.
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import {
  db, loadAccount, writeSub, logGrant, addDays,
  isProSub, normalizeSub, Subscription,
} from './entitlement';

/** index.ts 의 setGlobalOptions 는 import 순서상 이 파일보다 늦게 돌아서 적용되지 않는다 */
const REGION = 'asia-northeast3';
/** src/config/entitlements.ts 의 TRIAL_DAYS 와 같은 값이어야 한다 */
const TRIAL_DAYS = 7;
/** 프로모션 코드 1개가 줄 수 있는 최대 일수 — 실수로 365000 을 넣는 사고 방지 */
const MAX_PROMO_DAYS = 400;

function uidOf(req: CallableRequest): string {
  if (!req.auth?.uid) throw new HttpsError('unauthenticated', '로그인이 필요합니다.');
  return req.auth.uid;
}

/** 남은 기간이 있으면 그 위에 더한다 */
function extend(sub: Subscription, days: number): string {
  const base = isProSub(sub) && sub.expiresAt ? Date.parse(sub.expiresAt) : Date.now();
  return addDays(days, Number.isFinite(base) ? base : Date.now());
}

// ─── 현재 상태 ─────────────────────────────────────────────────────────────
export const subStatus = onCall(
  { region: REGION, timeoutSeconds: 20, memory: '256MiB' },
  async (req) => {
    const uid = uidOf(req);
    const acc = await loadAccount(uid);

    // 만료됐는데 tier 가 pro 로 남아 있으면 정리한다
    if (acc.sub.tier === 'pro' && !isProSub(acc.sub) && acc.sub.status !== 'expired') {
      const sub = await writeSub(uid, { ...acc.sub, tier: 'free', status: 'expired' });
      return { sub, pro: acc.isAdmin };
    }
    return { sub: acc.sub, pro: acc.pro };
  }
);

// ─── 무료 체험 ─────────────────────────────────────────────────────────────
export const subStartTrial = onCall(
  { region: REGION, timeoutSeconds: 20, memory: '256MiB' },
  async (req) => {
    const uid = uidOf(req);
    if (TRIAL_DAYS <= 0) throw new HttpsError('failed-precondition', '무료 체험을 제공하지 않습니다.');

    const acc = await loadAccount(uid);
    if (acc.sub.trialUsed) {
      throw new HttpsError('failed-precondition', '무료 체험은 계정당 한 번만 이용할 수 있습니다.');
    }
    if (isProSub(acc.sub)) {
      throw new HttpsError('failed-precondition', '이미 구독 중입니다.');
    }

    const sub = await writeSub(uid, {
      tier: 'pro',
      status: 'trial',
      expiresAt: addDays(TRIAL_DAYS),
      source: 'promo',
      productId: 'trial',
      trialUsed: true,
    });
    await logGrant(uid, 'trial', { days: TRIAL_DAYS });
    return { sub, pro: true };
  }
);

// ─── 프로모션 코드 ─────────────────────────────────────────────────────────
/**
 * promoCodes/{CODE} 문서 형태 (콘솔에서 직접 만든다):
 *   { days: 30, maxUses: 100, uses: 0, active: true, note: '런칭 베타',
 *     validUntil: '2026-12-31T23:59:59.000Z' }   // validUntil 은 선택
 */
export const subRedeemPromo = onCall(
  { region: REGION, timeoutSeconds: 30, memory: '256MiB' },
  async (req: CallableRequest<{ code?: string }>) => {
    const uid = uidOf(req);
    const code = String(req.data?.code ?? '').trim().toUpperCase().slice(0, 40);
    if (!code) throw new HttpsError('invalid-argument', '코드를 입력해주세요.');

    const codeRef = db.collection('promoCodes').doc(code);
    const useRef = db.collection('promoRedemptions').doc(`${uid}__${code}`);
    const userRef = db.collection('users').doc(uid);

    const sub = await db.runTransaction(async (tx) => {
      const [codeSnap, useSnap, userSnap] = await Promise.all([
        tx.get(codeRef), tx.get(useRef), tx.get(userRef),
      ]);

      if (!codeSnap.exists) throw new HttpsError('not-found', '존재하지 않는 코드입니다.');
      const c = codeSnap.data() as {
        days?: number; maxUses?: number; uses?: number; active?: boolean; validUntil?: string;
      };

      if (c.active === false) throw new HttpsError('failed-precondition', '사용할 수 없는 코드입니다.');
      if (useSnap.exists) throw new HttpsError('already-exists', '이미 사용한 코드입니다.');
      if (c.validUntil && Date.parse(c.validUntil) < Date.now()) {
        throw new HttpsError('failed-precondition', '기간이 지난 코드입니다.');
      }
      const uses = Number(c.uses ?? 0);
      const maxUses = Number(c.maxUses ?? 0);
      if (maxUses > 0 && uses >= maxUses) {
        throw new HttpsError('resource-exhausted', '사용 한도가 끝난 코드입니다.');
      }

      const days = Math.min(MAX_PROMO_DAYS, Math.max(1, Math.round(Number(c.days ?? 0))));
      if (!days) throw new HttpsError('failed-precondition', '설정이 잘못된 코드입니다.');

      const current = normalizeSub(userSnap.data()?.sub);
      const next: Subscription = {
        tier: 'pro',
        status: 'active',
        expiresAt: extend(current, days),
        source: 'promo',
        productId: code,
        trialUsed: current.trialUsed,
        updatedAt: new Date().toISOString(),
      };

      tx.set(userRef, { sub: next }, { merge: true });
      tx.set(useRef, { uid, code, days, at: new Date().toISOString() });
      tx.update(codeRef, { uses: uses + 1 });
      return next;
    });

    await logGrant(uid, 'promo', { code });
    return { sub, pro: true };
  }
);

// ─── 관리자 지급 ───────────────────────────────────────────────────────────
export const subGrant = onCall(
  { region: REGION, timeoutSeconds: 30, memory: '256MiB' },
  async (req: CallableRequest<{ uid?: string; days?: number | null; note?: string }>) => {
    const caller = uidOf(req);
    const me = await loadAccount(caller);
    if (!me.isAdmin && req.auth?.token?.admin !== true) {
      throw new HttpsError('permission-denied', '관리자만 사용할 수 있습니다.');
    }

    const target = String(req.data?.uid ?? '').trim();
    if (!target) throw new HttpsError('invalid-argument', '대상 uid 가 필요합니다.');

    const raw = req.data?.days;
    // days 가 null 이면 무기한
    const days = raw === null || raw === undefined ? null
      : Math.min(MAX_PROMO_DAYS * 10, Math.max(1, Math.round(Number(raw))));

    const current = (await loadAccount(target)).sub;
    const sub = await writeSub(target, {
      tier: 'pro',
      status: 'active',
      expiresAt: days === null ? null : extend(current, days),
      source: 'admin',
      productId: null,
      trialUsed: current.trialUsed,
    });

    await logGrant(target, 'admin_grant', { by: caller, days, note: String(req.data?.note ?? '') });
    logger.info('subGrant', { by: caller, target, days });
    return { sub, pro: true };
  }
);

// ─── 스토어 영수증 ─────────────────────────────────────────────────────────
/**
 * ⚠️ 아직 구현하지 않았다. 검증 없이 영수증만 받고 PRO 를 주면
 * 아무 문자열이나 보내서 무료로 구독하는 구멍이 된다.
 *
 * 붙일 때 할 일:
 *   iOS     App Store Server API 로 signedTransaction 검증 (JWS 서명 확인)
 *   Android Play Developer API purchases.subscriptionsv2.get 로 검증
 *   또는 RevenueCat webhook 으로 대체하고 이 함수는 삭제
 * 검증에 성공한 뒤에만 writeSub 으로 기록할 것.
 */
export const subApplyReceipt = onCall(
  { region: REGION, timeoutSeconds: 30, memory: '256MiB' },
  async (req) => {
    uidOf(req);
    throw new HttpsError('unimplemented', '스토어 결제가 아직 연결되지 않았습니다.');
  }
);
