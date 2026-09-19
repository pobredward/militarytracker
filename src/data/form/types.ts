/**
 * 자세 교정 포인트
 *  w — 자주 하는 실수 (무엇이 잘못되는가)
 *  c — 올바른 수행 (어떻게 고치는가)
 *
 * exId 는 exercises.ts 의 id 와 1:1 대응해야 한다.
 * 존재하지 않는 id 는 formCheck.ts 에서 조용히 제외된다.
 */
export interface FormItem {
  exId: string;
  w: string[];
  c: string[];
}
