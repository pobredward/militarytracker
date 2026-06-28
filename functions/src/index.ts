import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * workout 생성 시 자동으로 rankings 업데이트
 */
export const onWorkoutCreated = functions
  .region('asia-northeast3') // 서울 리전
  .firestore
  .document('workouts/{workoutId}')
  .onCreate(async (snap, context) => {
    const workout = snap.data();
    const userId = workout.userId;
    const date = workout.date.toDate();
    
    console.log(`✅ Workout created: ${context.params.workoutId}`);
    console.log(`   User: ${userId}, Date: ${date.toISOString()}`);
    
    try {
      await updateRankings(userId, workout, date, 'create');
      console.log(`✅ Rankings updated successfully`);
    } catch (error) {
      console.error(`❌ Error updating rankings:`, error);
      throw error;
    }
  });

/**
 * workout 업데이트 시 rankings도 업데이트
 */
export const onWorkoutUpdated = functions
  .region('asia-northeast3')
  .firestore
  .document('workouts/{workoutId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = after.userId;
    const date = after.date.toDate();
    
    console.log(`🔄 Workout updated: ${context.params.workoutId}`);
    
    // 변경된 값 계산
    const diff = {
      squatCount: (after.squatCount || 0) - (before.squatCount || 0),
      lungeCount: (after.lungeCount || 0) - (before.lungeCount || 0),
      walkSteps: (after.walkSteps || 0) - (before.walkSteps || 0),
      runDistance: (after.runDistance || 0) - (before.runDistance || 0),
    };
    
    try {
      await updateRankings(userId, diff, date, 'update');
      console.log(`✅ Rankings updated for diff:`, diff);
    } catch (error) {
      console.error(`❌ Error updating rankings:`, error);
      throw error;
    }
  });

/**
 * 모든 기간별 랭킹 업데이트
 */
async function updateRankings(
  userId: string,
  workout: any,
  date: Date,
  operation: 'create' | 'update'
) {
  const batch = db.batch();
  
  // 사용자 정보 조회 (생성 시에만)
  let displayName = '사용자';
  let photoUrl: string | null = null;
  
  if (operation === 'create') {
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      displayName = userData?.displayName || '사용자';
      photoUrl = userData?.photoUrl || null;
    } catch (error) {
      console.warn('Failed to fetch user data:', error);
    }
  }
  
  // 종합 점수 계산
  const overallScore = calculateOverallScore(workout);
  
  // 1. 일간 랭킹 업데이트
  const dailyKey = formatDate(date, 'YYYY-MM-DD');
  const dailyRef = db
    .collection('rankings')
    .doc('daily')
    .collection(dailyKey)
    .doc(userId);
  
  batch.set(dailyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    ...(operation === 'create' && { displayName, photoUrl }),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 2. 주간 랭킹 업데이트
  const weekKey = getWeekKey(date);
  const weeklyRef = db
    .collection('rankings')
    .doc('weekly')
    .collection(weekKey)
    .doc(userId);
  
  batch.set(weeklyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    ...(operation === 'create' && { displayName, photoUrl }),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 3. 월간 랭킹 업데이트
  const monthKey = formatDate(date, 'YYYY-MM');
  const monthlyRef = db
    .collection('rankings')
    .doc('monthly')
    .collection(monthKey)
    .doc(userId);
  
  batch.set(monthlyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    ...(operation === 'create' && { displayName, photoUrl }),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 4. 전체 랭킹 업데이트
  const allTimeRef = db
    .collection('rankings')
    .doc('allTime')
    .collection('users')
    .doc(userId);
  
  batch.set(allTimeRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    ...(operation === 'create' && { displayName, photoUrl }),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 배치 커밋
  await batch.commit();
}

/**
 * 종합 점수 계산
 */
function calculateOverallScore(workout: any): number {
  const squatScore = (workout.squatCount || 0) * 1.2;
  const lungeScore = (workout.lungeCount || 0) * 1.2;
  const walkScore = (workout.walkSteps || 0) * 0.01;
  const runScore = (workout.runDistance || 0) * 150;
  
  return squatScore + lungeScore + walkScore + runScore;
}

/**
 * 날짜 포맷팅
 */
function formatDate(date: Date, format: string): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  if (format === 'YYYY-MM-DD') {
    return `${year}-${month}-${day}`;
  } else if (format === 'YYYY-MM') {
    return `${year}-${month}`;
  }
  
  return '';
}

/**
 * 주차 키 생성 (ISO Week)
 */
function getWeekKey(date: Date): string {
  // 월요일을 주의 시작으로
  const d = new Date(date);
  const dayOfWeek = d.getDay();
  const diff = d.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
  const monday = new Date(d.setDate(diff));
  
  const year = monday.getFullYear();
  const weekNum = getWeekNumber(monday);
  
  return `${year}-W${String(weekNum).padStart(2, '0')}`;
}

/**
 * ISO 주차 계산
 */
function getWeekNumber(date: Date): number {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 4 - (d.getDay() || 7));
  const yearStart = new Date(d.getFullYear(), 0, 1);
  const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  return weekNo;
}
