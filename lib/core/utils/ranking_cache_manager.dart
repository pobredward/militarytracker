import 'package:flutter/foundation.dart';
import '../../models/ranking_model.dart';

/// 랭킹 데이터 캐싱 관리자
/// 
/// Firestore 읽기를 최소화하기 위해 5분간 메모리에 캐시 유지
class RankingCacheManager {
  static final Map<String, _CachedRanking> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  /// 캐시 키 생성
  static String _key(RankingPeriod period, RankingCategory category) =>
      '${period.name}_${category.name}';
  
  /// 캐시에서 랭킹 데이터 조회
  /// 
  /// 캐시가 없거나 만료된 경우 null 반환
  static List<RankingModel>? get(
    RankingPeriod period,
    RankingCategory category,
  ) {
    final cached = _cache[_key(period, category)];
    
    if (cached == null) {
      debugPrint('🔍 Cache MISS: ${period.name}_${category.name}');
      return null;
    }
    
    final age = DateTime.now().difference(cached.timestamp);
    
    if (age > _cacheDuration) {
      debugPrint('⏰ Cache EXPIRED: ${period.name}_${category.name} (age: ${age.inMinutes}min)');
      _cache.remove(_key(period, category));
      return null;
    }
    
    debugPrint('✅ Cache HIT: ${period.name}_${category.name} (age: ${age.inSeconds}s)');
    return cached.data;
  }
  
  /// 랭킹 데이터를 캐시에 저장
  static void set(
    RankingPeriod period,
    RankingCategory category,
    List<RankingModel> data,
  ) {
    _cache[_key(period, category)] = _CachedRanking(
      data: data,
      timestamp: DateTime.now(),
    );
    debugPrint('💾 Cache SAVED: ${period.name}_${category.name} (${data.length} items)');
  }
  
  /// 특정 캐시 항목 제거
  static void invalidate(RankingPeriod period, RankingCategory category) {
    _cache.remove(_key(period, category));
    debugPrint('🗑️  Cache INVALIDATED: ${period.name}_${category.name}');
  }
  
  /// 전체 캐시 초기화
  static void clear() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('🧹 Cache CLEARED: $count items removed');
  }
  
  /// 캐시 통계 조회
  static Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final validCache = _cache.entries.where((entry) {
      final age = now.difference(entry.value.timestamp);
      return age <= _cacheDuration;
    }).length;
    
    return {
      'total': _cache.length,
      'valid': validCache,
      'expired': _cache.length - validCache,
      'keys': _cache.keys.toList(),
    };
  }
  
  /// 만료된 캐시 자동 정리
  static void cleanExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cache.forEach((key, cached) {
      final age = now.difference(cached.timestamp);
      if (age > _cacheDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('🧹 Auto-cleaned ${keysToRemove.length} expired cache items');
    }
  }
}

/// 캐시된 랭킹 데이터
class _CachedRanking {
  final List<RankingModel> data;
  final DateTime timestamp;
  
  _CachedRanking({
    required this.data,
    required this.timestamp,
  });
}
