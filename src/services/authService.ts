import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
  GoogleAuthProvider,
  signInWithCredential,
  deleteUser,
  onAuthStateChanged,
  User as FirebaseUser,
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import { User, UserProfile, Plan } from '../types';
import { deleteAllUserData } from './workoutService';
import { normalizePlan } from '../utils/planner';

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

export async function signInWithGoogle(idToken: string): Promise<User> {
  const googleCredential = GoogleAuthProvider.credential(idToken);
  const { user } = await signInWithCredential(auth, googleCredential);

  const userRef = doc(db, 'users', user.uid);
  const userSnap = await getDoc(userRef);

  if (!userSnap.exists()) {
    const userData = baseUserDoc({
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      authProvider: 'google',
    });
    await setDoc(userRef, userData);
    return { uid: user.uid, ...userData };
  }

  await setDoc(userRef, { lastLoginAt: nowIso() }, { merge: true });
  return normalizeUser(user.uid, userSnap.data());
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
    createdAt: d.createdAt ?? nowIso(),
    lastLoginAt: d.lastLoginAt ?? nowIso(),
  };
}

export async function fetchUserProfile(uid: string): Promise<User | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  if (!snap.exists()) return null;
  return normalizeUser(uid, snap.data());
}

export const isAdmin = (user: User | null): boolean => user?.role === 'admin';

/** 계정 + 하위 데이터 전체 삭제. 재인증이 필요하면 코드를 그대로 throw */
export async function deleteAccount(): Promise<void> {
  const user = auth.currentUser;
  if (!user) return;
  await deleteAllUserData(user.uid);
  await deleteUser(user); // auth/requires-recent-login 가능
}

export async function saveOnboarding(
  uid: string,
  profile: UserProfile,
  plan: Plan
): Promise<void> {
  await setDoc(doc(db, 'users', uid), { profile, onboardingDone: true }, { merge: true });
  await savePlan(uid, plan);
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
