import {
  collection,
  doc,
  addDoc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  query,
  orderBy,
  limit,
  startAfter,
  arrayUnion,
  arrayRemove,
  DocumentSnapshot,
  increment,
} from 'firebase/firestore';
import { db } from './firebase';
import { Post, Comment } from '../types';

export async function createPost(
  data: Pick<Post, 'userId' | 'authorName' | 'title' | 'content'> & { authorPhotoURL?: string; imageURL?: string }
): Promise<Post> {
  const now = new Date().toISOString();
  const postData: Omit<Post, 'id'> = {
    ...data,
    likes: [],
    commentCount: 0,
    createdAt: now,
    updatedAt: now,
  };
  const ref = await addDoc(collection(db, 'posts'), postData);
  return { id: ref.id, ...postData };
}

export async function getPosts(limitCount = 20, lastDoc?: DocumentSnapshot): Promise<Post[]> {
  let q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(limitCount));
  if (lastDoc) q = query(q, startAfter(lastDoc));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Post, 'id'>) }));
}

export async function toggleLike(postId: string, userId: string, liked: boolean): Promise<void> {
  const ref = doc(db, 'posts', postId);
  await updateDoc(ref, {
    likes: liked ? arrayRemove(userId) : arrayUnion(userId),
  });
}

export async function deletePost(postId: string): Promise<void> {
  await deleteDoc(doc(db, 'posts', postId));
}

export async function addComment(
  postId: string,
  data: Pick<Comment, 'userId' | 'authorName' | 'content'> & { authorPhotoURL?: string }
): Promise<Comment> {
  const now = new Date().toISOString();
  const commentData: Omit<Comment, 'id'> = {
    postId,
    ...data,
    createdAt: now,
  };
  const ref = await addDoc(collection(db, 'posts', postId, 'comments'), commentData);
  await updateDoc(doc(db, 'posts', postId), { commentCount: increment(1) });
  return { id: ref.id, ...commentData };
}

export async function getComments(postId: string): Promise<Comment[]> {
  const q = query(
    collection(db, 'posts', postId, 'comments'),
    orderBy('createdAt', 'asc')
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Comment, 'id'>) }));
}
