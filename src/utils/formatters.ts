export function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일`;
}

export function formatNumber(n: number): string {
  return n.toLocaleString('ko-KR');
}

export function formatDistance(km: number): string {
  return `${km.toFixed(1)}km`;
}

export function formatSteps(steps: number): string {
  return `${formatNumber(steps)}보`;
}

export function todayString(): string {
  return new Date().toISOString().split('T')[0];
}

export function getProgressPercent(current: number, goal: number): number {
  if (goal === 0) return 0;
  return Math.min(Math.round((current / goal) * 100), 100);
}
