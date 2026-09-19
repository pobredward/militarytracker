/**
 * 자세 체크 — 잘못된 자세(w) vs 올바른 자세(c)
 * 종목명·부위는 exercises.ts 에서 가져오고, 여기서는 교정 포인트만 관리한다.
 * 새 종목을 추가할 때 exId 는 반드시 EX 에 존재하는 id 여야 한다.
 */
import { Exercise, exById, PART_LABEL } from './exercises';

export interface FormItem {
  exId: string;
  w: string[];
  c: string[];
}

export const FORM: FormItem[] = [
  {
    exId: 'bench',
    w: ['팔꿈치를 몸통과 90도로 벌린 채 내린다', '어깨가 으쓱 올라가며 벤치에서 뜬다', '바를 목 쪽으로 내린다'],
    c: ['팔꿈치는 몸통과 45~70도 각도 유지', '견갑골을 모으고 내려(후인·하강) 벤치에 고정', '바는 명치~유두 라인으로 터치'],
  },
  {
    exId: 'backsquat',
    w: ['무릎이 안쪽으로 무너진다', '뒤꿈치가 들리며 무게중심이 앞으로 쏠린다', '허리가 과도하게 꺾이거나 말린다'],
    c: ['무릎은 발끝과 같은 방향으로', '무게중심은 미드풋, 발 전체로 지면을 민다', '척추 중립 유지, 복압으로 코어 고정'],
  },
  {
    exId: 'deadlift',
    w: ['허리가 둥글게 말린 채 들어올린다', '바가 몸에서 멀어진다', '팔로 당겨서 들어올린다'],
    c: ['척추 중립, 가슴을 열고 시작', '바는 정강이~허벅지에 밀착해 수직 이동', '다리로 지면을 밀어내는 힘으로 리프트'],
  },
  {
    exId: 'ohp',
    w: ['허리를 과도하게 젖혀 반동을 쓴다', '바가 얼굴 앞으로 크게 돌아 올라간다'],
    c: ['둔근·복압으로 몸통 고정', '바가 올라가면 머리를 살짝 앞으로, 수직 경로 유지'],
  },
  {
    exId: 'latraise',
    w: ['반동으로 몸을 흔들며 들어올린다', '승모근이 으쓱 올라간다', '어깨 높이보다 과하게 올린다'],
    c: ['몸통 고정, 팔꿈치 살짝 굽힌 상태 유지', '어깨는 내린 채 측면삼각근으로 리드', '어깨 높이까지만, 천천히 내리기'],
  },
  {
    exId: 'cablerow',
    w: ['허리 반동으로 상체를 크게 젖힌다', '어깨가 앞으로 말린 채 팔로만 당긴다'],
    c: ['상체 각도 고정, 가슴을 편 상태 유지', '팔꿈치를 뒤로 보내며 견갑골을 모은다'],
  },
  {
    exId: 'plank',
    w: ['엉덩이가 위로 솟는다', '허리가 아래로 처진다'],
    c: ['머리-등-엉덩이 일직선', '복압을 잡고 골반을 살짝 후방 경사'],
  },
  {
    exId: 'dbfly',
    w: ['팔꿈치를 다 편 채 무리하게 벌린다', '무게에 끌려 어깨가 열린다'],
    c: ['팔꿈치 각도를 고정한 채 호를 그린다', '가슴이 늘어나는 지점까지만, 모을 때 가슴 수축 집중'],
  },
  {
    exId: 'pullup',
    w: ['반동(키핑)으로 튕겨 올라간다', '가동범위 절반만 오르내린다'],
    c: ['견갑 하강으로 시작해 등으로 당긴다', '팔을 완전히 편 지점부터 턱이 바 위까지'],
  },
  {
    exId: 'pushup',
    w: ['허리가 처진 채 진행한다', '팔꿈치가 몸통과 90도로 벌어진다'],
    c: ['몸 일직선, 코어 고정', '팔꿈치는 몸통과 약 45도'],
  },
  {
    exId: 'uprow',
    w: ['바를 턱까지 과도하게 끌어올린다', '손목이 꺾인 채 당긴다'],
    c: ['가슴 높이까지만 — 어깨 충돌 방지', '팔꿈치가 리드, 손목은 중립'],
  },
  {
    exId: 'pushdown',
    w: ['팔꿈치가 벌어지고 어깨가 말린다', '상체 반동으로 눌러 내린다'],
    c: ['팔꿈치를 몸통 옆에 고정', '삼두의 힘으로만 끝까지 펴고 천천히 복귀'],
  },
  {
    exId: 'latpull',
    w: ['상체를 크게 뒤로 젖혀 반동을 쓴다', '바를 목 뒤로 당긴다'],
    c: ['상체는 살짝만 기울이고 고정', '바는 쇄골 방향, 팔꿈치를 아래로 보내는 느낌'],
  },
];

export interface FormView extends FormItem {
  ex: Exercise;
  name: string;
  partLabel: string;
}

/** 존재하지 않는 exId 는 조용히 제외 — 런타임 크래시 방지 */
export const FORM_VIEW: FormView[] = FORM.map((f) => {
  const ex = exById(f.exId);
  return ex ? { ...f, ex, name: ex.n, partLabel: PART_LABEL[ex.part] } : null;
}).filter((v): v is FormView => v !== null);

export const formByExId = (exId: string): FormView | undefined =>
  FORM_VIEW.find((f) => f.exId === exId);

export const FORM_PARTS: string[] = ['전체', ...Array.from(new Set(FORM_VIEW.map((f) => f.partLabel)))];
