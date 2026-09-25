/**
 * 색 토큰 — 다크 전용.
 *
 * 대비 기준: 본문·라벨 텍스트는 배경(bg~panel3) 위에서 WCAG AA 4.5:1 이상.
 *   ink  18.1:1 · mid 8.2:1 · muted 5.4:1(bg) / 4.4:1(panel3) · good 10.6:1 · wrong 5.5:1
 * muted 는 예전 #6E6E76(3.2~3.9:1, AA 실패)에서 올렸다. 순수 장식(구분점·테두리)은 line2 를 쓴다.
 */
export const colors = {
  bg: '#09090A',
  panel: '#111113',
  panel2: '#18181B',
  panel3: '#212125',
  line: '#26262B',
  line2: '#37373D',
  ink: '#F4F4F5',
  mid: '#A6A6AD',
  /** 보조 텍스트 — 12px 이상에서 AA 통과 */
  muted: '#85858D',
  /** 입력 placeholder — 값과 헷갈리지 않게 muted 보다 한 단계 더 옅게 */
  placeholder: '#5C5C64',
  wrong: '#E45858',
  good: '#A8C5A0',
  ok: '#F4F4F5',
  /** 웹 프레임 바깥 배경·노치 */
  bgDeep: '#050506',
  frame: '#1C1C20',
  /** 긍정/부정 박스 — 즉석 rgba 대신 이 넷을 쓴다 */
  goodBg: 'rgba(168,197,160,0.12)',
  goodLine: 'rgba(168,197,160,0.32)',
  wrongBg: 'rgba(228,88,88,0.12)',
  wrongLine: 'rgba(228,88,88,0.32)',
};

/** 부위별 악센트 — 플레이스홀더/차트에 사용 */
export const partTint: Record<string, string> = {
  chest: '#5B7FA6',
  back: '#6A8F73',
  legs: '#A68A5B',
  shoulders: '#8A6FA6',
  biceps: '#A66F76',
  triceps: '#6F93A6',
  abs: '#8C8C93',
};

export default colors;
