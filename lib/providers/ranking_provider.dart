import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking_model.dart';
import '../repositories/ranking_repository.dart';
import '../core/utils/ranking_cache_manager.dart';
import 'auth_provider.dart';

// RankingRepository Provider
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository();
});

// 현재 선택된 기간 Provider
final selectedRankingPeriodProvider = StateProvider<RankingPeriod>((ref) {
  return RankingPeriod.weekly; // 기본값: 주간
});

// 현재 선택된 카테고리 Provider
final selectedRankingCategoryProvider = StateProvider<RankingCategory>((ref) {
  return RankingCategory.overall; // 기본값: 종합
});

// 랭킹 리스트 Provider (캐싱 적용, autoDispose 제거)
final rankingListProvider = FutureProvider<List<RankingModel>>((ref) async {
  final repository = ref.watch(rankingRepositoryProvider);
  final period = ref.watch(selectedRankingPeriodProvider);
  final category = ref.watch(selectedRankingCategoryProvider);
  
  // Repository에서 캐싱 처리됨
  return repository.getRankings(
    period: period,
    category: category,
    limit: 100,
  );
});

// 현재 사용자의 랭킹 통계 Provider
final userRankingStatsProvider = FutureProvider.autoDispose<UserRankingStats?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.getUserRankingStats(user.uid);
});

// 현재 사용자의 특정 랭킹 Provider
final currentUserRankingProvider = FutureProvider.autoDispose<RankingModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  
  final repository = ref.watch(rankingRepositoryProvider);
  final period = ref.watch(selectedRankingPeriodProvider);
  final category = ref.watch(selectedRankingCategoryProvider);
  
  return repository.getUserRanking(
    userId: user.uid,
    period: period,
    category: category,
  );
});

/// 랭킹 캐시를 수동으로 무효화하는 Provider
final invalidateRankingCacheProvider = Provider<void Function()>((ref) {
  return () {
    RankingCacheManager.clear();
    ref.invalidate(rankingListProvider);
    ref.invalidate(userRankingStatsProvider);
    ref.invalidate(currentUserRankingProvider);
  };
});
