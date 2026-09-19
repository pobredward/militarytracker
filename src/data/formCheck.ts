/**
 * 자세 체크 — 잘못된 자세(w) vs 올바른 자세(c)
 *
 * 종목명·부위는 exercises.ts 에서 가져오고, 여기서는 교정 포인트만 관리한다.
 * 부위별 파일(src/data/form/*.ts)로 나뉘어 있으며 이 파일이 합친다.
 */
import { Exercise, exById, PART_LABEL } from './exercises';
import { FormItem } from './form/types';
import { CHEST_FORM } from './form/chest';
import { BACK_FORM } from './form/back';
import { LEGS_FORM } from './form/legs';
import { SHOULDERS_FORM } from './form/shoulders';
import { ARMS_FORM } from './form/arms';
import { ABS_FORM } from './form/abs';

export type { FormItem };

export const FORM: FormItem[] = [
  ...CHEST_FORM,
  ...BACK_FORM,
  ...LEGS_FORM,
  ...SHOULDERS_FORM,
  ...ARMS_FORM,
  ...ABS_FORM,
];

export interface FormView extends FormItem {
  ex: Exercise;
  name: string;
  partLabel: string;
}

/** 존재하지 않는 exId 는 조용히 제외 — 런타임 크래시 방지 */
const FORM_VIEW: FormView[] = FORM.map((f) => {
  const ex = exById(f.exId);
  return ex ? { ...f, ex, name: ex.n, partLabel: PART_LABEL[ex.part] } : null;
}).filter((v): v is FormView => v !== null);

const FORM_MAP = new Map(FORM_VIEW.map((f) => [f.exId, f]));

export const formByExId = (exId: string): FormView | undefined => FORM_MAP.get(exId);

export const FORM_COUNT = FORM_VIEW.length;
