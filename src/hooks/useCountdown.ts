import { useEffect, useState } from 'react';
import { AppState } from 'react-native';

const remain = (endsAt: number | null): number =>
  endsAt ? Math.max(0, Math.ceil((endsAt - Date.now()) / 1000)) : 0;

/**
 * 종료 시각(epoch ms) 기준 남은 초.
 * setInterval 누적 오차나 백그라운드 정지의 영향을 받지 않는다.
 */
export function useCountdown(endsAt: number | null): number {
  const [left, setLeft] = useState(() => remain(endsAt));

  useEffect(() => {
    if (!endsAt) {
      setLeft(0);
      return;
    }
    setLeft(remain(endsAt));
    const iv = setInterval(() => setLeft(remain(endsAt)), 500);
    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') setLeft(remain(endsAt));
    });
    return () => {
      clearInterval(iv);
      sub.remove();
    };
  }, [endsAt]);

  return left;
}

/** 경과 시간(초) — 세션 타이머용 */
export function useElapsed(startedAt: number | null): number {
  const [sec, setSec] = useState(0);
  useEffect(() => {
    if (!startedAt) {
      setSec(0);
      return;
    }
    const calc = () => setSec(Math.floor((Date.now() - startedAt) / 1000));
    calc();
    const iv = setInterval(calc, 1000);
    const sub = AppState.addEventListener('change', (s) => {
      if (s === 'active') calc();
    });
    return () => {
      clearInterval(iv);
      sub.remove();
    };
  }, [startedAt]);
  return sec;
}
