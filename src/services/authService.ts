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
import { doc, setDoc, getDoc, serverTimestamp, deleteDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import { User } from '../types';

export async function signUpWithEmail(
  email: string,
  password: string,
  displayName: string
): Promise<User> {
  const credential = await createUserWithEmailAndPassword(auth, email, password);
  await updateProfile(credential.user, { displayName });

  const userData: Omit<User, 'uid'> = {
    email,
    displayName,
    photoURL: null,
    authProvider: 'email',
    totalSquats: 0,
    totalLunges: 0,
    totalWalkSteps: 0,
    totalRunDistance: 0,
    workoutDays: 0,
    createdAt: new Date().toISOString(),
    lastLoginAt: new Date().toISOString(),
  };

  await setDoc(doc(db, 'users', credential.user.uid), userData);
  return { uid: credential.user.uid, ...userData };
}

export async function signInWithEmail(email: string, password: string): Promise<void> {
  const credential = await signInWithEmailAndPassword(auth, email, password);
  await setDoc(
    doc(db, 'users', credential.user.uid),
    { lastLoginAt: new Date().toISOString() },
    { merge: true }
  );
}

export async function signInWithGoogle(idToken: string): Promise<User> {
  const googleCredential = GoogleAuthProvider.credential(idToken);
  const result = await signInWithCredential(auth, googleCredential);
  const { user } = result;

  const userRef = doc(db, 'users', user.uid);
  const userSnap = await getDoc(userRef);

  if (!userSnap.exists()) {
    const userData: Omit<User, 'uid'> = {
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      authProvider: 'google',
      totalSquats: 0,
      totalLunges: 0,
      totalWalkSteps: 0,
      totalRunDistance: 0,
      workoutDays: 0,
      createdAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
    };
    await setDoc(userRef, userData);
    return { uid: user.uid, ...userData };
  }

  await setDoc(userRef, { lastLoginAt: new Date().toISOString() }, { merge: true });
  return { uid: user.uid, ...(userSnap.data() as Omit<User, 'uid'>) };
}

export async function logout(): Promise<void> {
  await signOut(auth);
}

export async function fetchUserProfile(uid: string): Promise<User | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  if (!snap.exists()) return null;
  return { uid, ...(snap.data() as Omit<User, 'uid'>) };
}

export async function deleteAccount(): Promise<void> {
  const user = auth.currentUser;
  if (!user) return;
  await deleteDoc(doc(db, 'users', user.uid));
  await deleteUser(user);
}

export function onAuthChange(callback: (user: FirebaseUser | null) => void) {
  return onAuthStateChanged(auth, callback);
}
