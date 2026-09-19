import { useEffect } from 'react';
import { View, Text, Image, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import { useVideoPlayer, VideoView } from 'expo-video';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, partTint } from '../utils/colors';
import { exById, PART_LABEL } from '../data/exercises';
import { getImage, getVideo } from '../data/media';

interface Props {
  exId: string;
  /** 3~5초 클립 자동 재생 — 상세 화면에서만 사용한다 */
  autoPlay?: boolean;
  rounded?: number;
  style?: StyleProp<ViewStyle>;
  badge?: string;
  badgeColor?: string;
  showLabel?: boolean;
  dim?: number;
}

/**
 * 영상 → 포스터 → 플레이스홀더 순으로 폴백.
 *
 * 중요: 비디오 플레이어를 만드는 것은 별도 컴포넌트로 분리했다.
 * hooks 는 조건부 호출이 불가능하므로, 목록/그리드(autoPlay=false)에서
 * 같은 컴포넌트를 쓰면 종목 수만큼 네이티브 플레이어가 생성된다.
 */
export default function ExerciseMedia(props: Props) {
  const videoSrc = props.autoPlay ? getVideo(props.exId) ?? null : null;
  return videoSrc ? (
    <VideoMedia {...props} src={videoSrc} />
  ) : (
    <StaticMedia {...props} />
  );
}

function VideoMedia({ src, rounded = 16, style, badge, badgeColor, showLabel, dim = 0.35, exId }: Props & { src: number }) {
  const ex = exById(exId);
  const player = useVideoPlayer(src, (p) => {
    p.loop = true;
    p.muted = true;
    p.currentTime = 0;
    p.play();
  });

  useEffect(() => {
    try {
      player.play();
    } catch {
      // 아직 준비되지 않았으면 다음 렌더에서 재시도
    }
  }, [player]);

  return (
    <View style={[s.wrap, { borderRadius: rounded }, style]}>
      <VideoView player={player} style={s.fill} contentFit="cover" nativeControls={false} />
      {dim > 0 && <View style={[s.fill, { backgroundColor: `rgba(0,0,0,${dim})` }]} pointerEvents="none" />}
      <Overlay ex={ex} badge={badge} badgeColor={badgeColor} showLabel={showLabel} />
    </View>
  );
}

function StaticMedia({ exId, rounded = 16, style, badge, badgeColor, showLabel, dim = 0.35 }: Props) {
  const ex = exById(exId);
  const imageSrc = getImage(exId) ?? null;
  const tint = ex ? partTint[ex.part] ?? colors.panel3 : colors.panel3;

  return (
    <View style={[s.wrap, { borderRadius: rounded }, style]}>
      {imageSrc ? (
        <>
          <Image source={imageSrc} style={s.fill} resizeMode="cover" />
          {dim > 0 && <View style={[s.fill, { backgroundColor: `rgba(0,0,0,${dim})` }]} pointerEvents="none" />}
        </>
      ) : (
        <LinearGradient colors={[tint, colors.panel2]} style={s.fill} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
          <View style={s.phCenter}>
            <Text style={s.phTxt}>{ex ? PART_LABEL[ex.part] : '?'}</Text>
            <Text style={s.phSub}>미디어 준비중</Text>
          </View>
        </LinearGradient>
      )}
      <Overlay ex={ex} badge={badge} badgeColor={badgeColor} showLabel={showLabel} />
    </View>
  );
}

function Overlay({
  ex, badge, badgeColor, showLabel,
}: {
  ex: ReturnType<typeof exById>;
  badge?: string;
  badgeColor?: string;
  showLabel?: boolean;
}) {
  return (
    <>
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
    </>
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
