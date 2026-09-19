import { useEffect } from 'react';
import { View, Text, Image, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import { useVideoPlayer, VideoView } from 'expo-video';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, partTint } from '../utils/colors';
import { exById, PART_LABEL } from '../data/exercises';
import { getImage, getVideo } from '../data/media';

interface Props {
  exId: string;
  /** 3~5초 클립 자동 재생 */
  autoPlay?: boolean;
  rounded?: number;
  style?: StyleProp<ViewStyle>;
  /** 우상단 배지 텍스트 */
  badge?: string;
  badgeColor?: string;
  /** 하단에 종목명 오버레이 */
  showLabel?: boolean;
  dim?: number;
}

/**
 * 영상 → 이미지 → 플레이스홀더 순으로 폴백.
 * 미디어가 준비되면 src/data/media.ts 에 한 줄 추가하는 것만으로 반영된다.
 */
export default function ExerciseMedia({
  exId,
  autoPlay = false,
  rounded = 16,
  style,
  badge,
  badgeColor,
  showLabel = false,
  dim = 0.35,
}: Props) {
  const ex = exById(exId);
  // autoPlay 인 화면(상세)만 영상을 쓰고, 목록/그리드는 포스터만 사용한다.
  // 180개 카드마다 VideoPlayer 를 만들면 메모리·디코더가 감당되지 않는다.
  const videoSrc = autoPlay ? getVideo(exId) ?? null : null;
  const imageSrc = getImage(exId) ?? null;

  // hooks 규칙상 항상 호출 — source 가 null 이면 아무것도 재생하지 않는다
  const player = useVideoPlayer(videoSrc, (p) => {
    p.loop = true;
    p.muted = true;
    // 첫 프레임까지 미리 버퍼링해 탭하자마자 재생되도록 한다
    if (videoSrc) {
      p.currentTime = 0;
      if (autoPlay) p.play();
    }
  });

  // 소스/화면이 바뀔 때도 재생이 끊기지 않도록 보강
  useEffect(() => {
    if (!videoSrc || !autoPlay) return;
    try {
      player.play();
    } catch {
      // 플레이어가 아직 준비되지 않은 경우 — 다음 렌더에서 재시도
    }
  }, [videoSrc, autoPlay, player]);

  const tint = ex ? partTint[ex.part] ?? colors.panel3 : colors.panel3;

  return (
    <View style={[s.wrap, { borderRadius: rounded }, style]}>
      {videoSrc ? (
        <VideoView player={player} style={s.fill} contentFit="cover" nativeControls={false} />
      ) : imageSrc ? (
        <Image source={imageSrc} style={s.fill} resizeMode="cover" />
      ) : (
        <LinearGradient colors={[tint, colors.panel2]} style={s.fill} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
          <View style={s.phCenter}>
            <Text style={s.phTxt}>{ex ? PART_LABEL[ex.part] : '?'}</Text>
            <Text style={s.phSub}>미디어 준비중</Text>
          </View>
        </LinearGradient>
      )}

      {(videoSrc || imageSrc) && dim > 0 && (
        <View style={[s.fill, { backgroundColor: `rgba(0,0,0,${dim})` }]} pointerEvents="none" />
      )}

      {badge ? (
        <View style={s.badge}>
          <Text style={[s.badgeTxt, badgeColor ? { color: badgeColor } : null]}>{badge}</Text>
        </View>
      ) : null}

      {showLabel && ex ? (
        <View style={s.label} pointerEvents="none">
          <Text style={s.labelName} numberOfLines={1}>{ex.n}</Text>
          <Text style={s.labelPart}>{PART_LABEL[ex.part]} · {ex.g}</Text>
        </View>
      ) : null}
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { overflow: 'hidden', backgroundColor: colors.panel2, position: 'relative' },
  fill: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, width: '100%', height: '100%' },
  phCenter: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  phTxt: { fontSize: 15, fontWeight: '800', color: 'rgba(255,255,255,0.75)', letterSpacing: 1 },
  phSub: { fontSize: 9.5, color: 'rgba(255,255,255,0.4)', marginTop: 4, letterSpacing: 0.5 },
  badge: {
    position: 'absolute', top: 10, right: 10,
    backgroundColor: 'rgba(0,0,0,0.6)', borderRadius: 7,
    paddingHorizontal: 8, paddingVertical: 4,
    borderWidth: 0.5, borderColor: 'rgba(255,255,255,0.15)',
  },
  badgeTxt: { fontSize: 9.5, fontWeight: '800', color: colors.ink, letterSpacing: 0.5 },
  label: { position: 'absolute', left: 12, right: 12, bottom: 12 },
  labelName: { fontSize: 15, fontWeight: '800', color: colors.ink },
  labelPart: { fontSize: 10.5, color: 'rgba(255,255,255,0.6)', marginTop: 2 },
});
