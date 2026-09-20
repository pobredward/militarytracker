import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
  deleteUser,
  onAuthStateChanged,
  sendPasswordResetEmail,
  User as FirebaseUser,
} from 'firebase/auth';
import { doc, setDoc, getDoc, writeBatch } from 'firebase/firestore';
import { auth, db } from './firebase';
import { User, UserProfile, Plan } from '../types';
import { deleteAllUserData } from './workoutService';
import { normalizePlan } from '../utils/planner';
import { normalizeSub } from '../utils/subscription';

const nowIso = () => new Date().toISOString();

function baseUserDoc(partial: Partial<User>): Omit<User, 'uid'> {
  return {
    email: partial.email ?? null,
    displayName: partial.displayName ?? null,
    photoURL: partial.photoURL ?? null,
    authProvider: partial.authProvider ?? 'email',
    role: 'user',
    onboardingDone: false,
    profile: null,
    createdAt: nowIso(),
    lastLoginAt: nowIso(),
  };
}

export async function signUpWithEmail(
  email: string,
  password: string,
  displayName: string
): Promise<User> {
  const credential = await createUserWithEmailAndPassword(auth, email, password);
  await updateProfile(credential.user, { displayName });

  const userData = baseUserDoc({ email, displayName, authProvider: 'email' });
  await setDoc(doc(db, 'users', credential.user.uid), userData);
  return { uid: credential.user.uid, ...userData };
}

export async function signInWithEmail(email: string, password: string): Promise<void> {
  const credential = await signInWithEmailAndPassword(auth, email, password);
  const ref = doc(db, 'users', credential.user.uid);
  const snap = await getDoc(ref);

  if (snap.exists()) {
    // merge: true — 일시적 오류에도 기존 profile/role 이 날아가지 않도록
    await setDoc(ref, { lastLoginAt: nowIso() }, { merge: true });
    return;
  }
  await setDoc(
    ref,
    baseUserDoc({
      email,
      displayName: credential.user.displayName,
      photoURL: credential.user.photoURL,
      authProvider: 'email',
    })
  );
}

/** 비밀번호 재설정 메일 발송. 존재하지 않는 계정도 동일하게 처리(계정 존재 여부 노출 방지) */
export async function resetPassword(email: string): Promise<void> {
  await sendPasswordResetEmail(auth, email);
}

export async function logout(): Promise<void> {
  await signOut(auth);
}

function normalizeUser(uid: string, data: Record<string, unknown> | undefined): User {
  const d = (data ?? {}) as Partial<User>;
  return {
    uid,
    email: d.email ?? null,
    displayName: d.displayName ?? null,
    photoURL: d.photoURL ?? null,
    authProvider: d.authProvider ?? 'email',
    role: d.role === 'admin' ? 'admin' : 'user',
    onboardingDone: d.onboardingDone ?? false,
    profile: d.profile ?? null,
    // 구독은 서버(Cloud Functions)만 쓴다 — 여기서는 읽기만 한다
    sub: normalizeSub(d.sub),
    createdAt: d.createdAt ?? nowIso(),
    lastLoginAt: d.lastLoginAt ?? nowIso(),
  };
}

export async function fetchUserProfile(uid: string): Promise<User | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  if (!snap.exists()) return null;
  return normalizeUser(uid, snap.data());
}

/** 계정 + 하위 데이터 전체 삭제. 재인증이 필요하면 코드를 그대로 throw */
export async function deleteAccount(): Promise<void> {
  const user = auth.currentUser;
  if (!user) return;

  // Firebase 는 최근 로그인(약 5분)을 요구한다.
  // 데이터를 먼저 지우면 deleteUser 가 실패했을 때 계정만 남고 기록은 사라진다.
  // 따라서 조건을 먼저 확인하고, 통과할 때만 삭제를 시작한다.
  const lastSignIn = user.metadata.lastSignInTime
    ? new Date(user.metadata.lastSignInTime).getTime()
    : 0;
  if (Date.now() - lastSignIn > 4 * 60 * 1000) {
    const err = new Error('requires recent login') as Error & { code: string };
    err.code = 'auth/requires-recent-login';
    throw err;
  }

  await deleteAllUserData(user.uid);
  await deleteUser(user);
}

/** 프로필·플랜을 한 번에 기록 — 중간에 끊겨 '온보딩 완료인데 플랜 없음' 상태가 되지 않도록 */
export async function saveOnboarding(
  uid: string,
  profile: UserProfile,
  plan: Plan
): Promise<void> {
  const batch = writeBatch(db);
  batch.set(doc(db, 'users', uid), { profile, onboardingDone: true }, { merge: true });
  batch.set(doc(db, 'plans', uid), { ...plan, updatedAt: nowIso() });
  await batch.commit();
}

export async function savePlan(uid: string, plan: Plan): Promise<void> {
  await setDoc(doc(db, 'plans', uid), { ...plan, updatedAt: nowIso() }, { merge: false });
}

export async function saveProfile(uid: string, profile: UserProfile): Promise<void> {
  await setDoc(doc(db, 'users', uid), { profile }, { merge: true });
}

export async function fetchPlan(uid: string): Promise<Plan | null> {
  const snap = await getDoc(doc(db, 'plans', uid));
  if (!snap.exists()) return null;
  return normalizePlan(snap.data() as Plan);
}

export function onAuthChange(callback: (user: FirebaseUser | null) => void) {
  return onAuthStateChanged(auth, callback);
}
