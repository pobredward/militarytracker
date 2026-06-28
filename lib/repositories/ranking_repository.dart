import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_model.dart';
import '../models/user_model.dart';
import '../core/utils/ranking_cache_manager.dart';
import '../core/utils/firestore_type_converter.dart';

/// 랭킹 Repository - 사전 집계된 rankings 컬렉션 사용
/// 
/// Cloud Functions가 workout 생성/업데이트 시 자동으로 rankings 컬렉션을 업데이트하므로,
/// 여기서는 이미 집계된 데이터만 조회합니다.
class RankingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사전 집계된 랭킹 데이터 조회 (초고속!)
  /// 
  /// Before: 2,000개 workout 문서 + 100개 user 문서 = 2,100 reads
  /// After: 100개 ranking 문서 = 100 reads (95% 감소!)
  Future<List<RankingModel>> getRankings({
    required RankingPeriod period,
    required RankingCategory category,
    int limit = 100,
  }) async {
    try {
      // 1단계: 캐시 확인
      final cached = RankingCacheManager.get(period, category);
      if (cached != null) {
        debugPrint('📊 Ranking from cache: ${period.name}_${category.name}');
        return cached;
      }
      
      // 2단계: 이미 집계된 데이터만 조회
      debugPrint('📊 Fetching ranking from Firestore: ${period.name}_${category.name}');
      
      final periodKey = _getPeriodKey(period);
      final sortField = _getCategoryField(category);
      
      final snapshot = await _firestore
        .collection('rankings')
        .doc(_getPeriodName(period))
        .collection(periodKey)
        .orderBy(sortField, descending: true)
        .limit(limit)
        .get();
      
      debugPrint('✅ Fetched ${snapshot.docs.length} rankings (${snapshot.docs.length} reads)');
      
      // 3단계: RankingModel 생성
      final rankings = <RankingModel>[];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        // 0점인 사용자는 제외
        final score = _getScore(data, category);
        if (score == 0) continue;
        
        rankings.add(RankingModel(
          userId: doc.id,
          displayName: data['displayName'] ?? '사용자',
          photoUrl: data['photoUrl'],
          squatCount: data['squatCount'] ?? 0,
          lungeCount: data['lungeCount'] ?? 0,
          walkSteps: data['walkSteps'] ?? 0,
          runDistance: (data['runDistance'] ?? 0.0).toDouble(),
          overallScore: (data['overallScore'] ?? 0.0).toDouble(),
          rank: i + 1,
          period: period,
          category: category,
          lastUpdated: FirestoreTypeConverter.dateToDateTime(data['lastUpdated'], fieldName: 'lastUpdated') ?? 
                       DateTime.now(),
        ));
      }
      
      // 4단계: 캐시 저장
      RankingCacheManager.set(period, category, rankings);
      
      return rankings;
    } catch (e, stackTrace) {
      debugPrint('❌ 랭킹 조회 실패: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 특정 사용자의 랭킹 통계를 조회합니다.
  Future<UserRankingStats> getUserRankingStats(String userId) async {
    try {
      final stats = UserRankingStats(userId: userId);
      
      // 각 기간 및 카테고리별 랭킹 조회
      final periods = RankingPeriod.values;
      final categories = RankingCategory.values;
      
      Map<String, int> rankMap = {};
      
      for (final period in periods) {
        for (final category in categories) {
          final rankings = await getRankings(
            period: period,
            category: category,
            limit: 1000,
          );
          
          final userRanking = rankings.firstWhere(
            (r) => r.userId == userId,
            orElse: () => const RankingModel(rank: 0),
          );
          
          final key = '${category.name}_${period.name}';
          rankMap[key] = userRanking.rank;
        }
      }
      
      return UserRankingStats(
        userId: userId,
        // 종합 랭킹
        overallRankDaily: rankMap['overall_daily'] ?? 0,
        overallRankWeekly: rankMap['overall_weekly'] ?? 0,
        overallRankMonthly: rankMap['overall_monthly'] ?? 0,
        overallRankAllTime: rankMap['overall_allTime'] ?? 0,
        // 스쿼트 랭킹
        squatRankDaily: rankMap['squats_daily'] ?? 0,
        squatRankWeekly: rankMap['squats_weekly'] ?? 0,
        squatRankMonthly: rankMap['squats_monthly'] ?? 0,
        squatRankAllTime: rankMap['squats_allTime'] ?? 0,
        // 런지 랭킹
        lungeRankDaily: rankMap['lunges_daily'] ?? 0,
        lungeRankWeekly: rankMap['lunges_weekly'] ?? 0,
        lungeRankMonthly: rankMap['lunges_monthly'] ?? 0,
        lungeRankAllTime: rankMap['lunges_allTime'] ?? 0,
        // 걷기 랭킹
        walkRankDaily: rankMap['walking_daily'] ?? 0,
        walkRankWeekly: rankMap['walking_weekly'] ?? 0,
        walkRankMonthly: rankMap['walking_monthly'] ?? 0,
        walkRankAllTime: rankMap['walking_allTime'] ?? 0,
        // 뛰기 랭킹
        runRankDaily: rankMap['running_daily'] ?? 0,
        runRankWeekly: rankMap['running_weekly'] ?? 0,
        runRankMonthly: rankMap['running_monthly'] ?? 0,
        runRankAllTime: rankMap['running_allTime'] ?? 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('사용자 랭킹 통계 조회 실패: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 특정 사용자의 특정 기간 랭킹을 조회합니다.
  Future<RankingModel?> getUserRanking({
    required String userId,
    required RankingPeriod period,
    required RankingCategory category,
  }) async {
    try {
      final rankings = await getRankings(
        period: period,
        category: category,
        limit: 1000,
      );
      
      return rankings.firstWhere(
        (r) => r.userId == userId,
        orElse: () => RankingModel(
          userId: userId,
          rank: 0,
          period: period,
          category: category,
        ),
      );
    } catch (e) {
      debugPrint('사용자 랭킹 조회 실패: $e');
      return null;
    }
  }

  /// 기간별 컬렉션 이름 반환
  String _getPeriodName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return 'daily';
      case RankingPeriod.weekly:
        return 'weekly';
      case RankingPeriod.monthly:
        return 'monthly';
      case RankingPeriod.allTime:
        return 'allTime';
    }
  }
  
  /// 기간별 문서 키 반환
  String _getPeriodKey(RankingPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriod.daily:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      case RankingPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekNum = _getWeekNumber(weekStart);
        return '${weekStart.year}-W${weekNum.toString().padLeft(2, '0')}';
      
      case RankingPeriod.monthly:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      case RankingPeriod.allTime:
        return 'users';
    }
  }
  
  /// ISO 주차 계산
  int _getWeekNumber(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    d.add(Duration(days: 4 - (d.weekday == 7 ? 0 : d.weekday)));
    final yearStart = DateTime(d.year, 1, 1);
    return ((d.difference(yearStart).inDays + 1) / 7).ceil();
  }
  
  /// 카테고리별 정렬 필드 반환
  String _getCategoryField(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return 'overallScore';
      case RankingCategory.squats:
        return 'squatCount';
      case RankingCategory.lunges:
        return 'lungeCount';
      case RankingCategory.walking:
        return 'walkSteps';
      case RankingCategory.running:
        return 'runDistance';
    }
  }
  
  /// 카테고리별 점수 추출
  double _getScore(Map<String, dynamic> data, RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return (data['overallScore'] ?? 0.0).toDouble();
      case RankingCategory.squats:
        return (data['squatCount'] ?? 0).toDouble();
      case RankingCategory.lunges:
        return (data['lungeCount'] ?? 0).toDouble();
      case RankingCategory.walking:
        return (data['walkSteps'] ?? 0).toDouble();
      case RankingCategory.running:
        return (data['runDistance'] ?? 0.0).toDouble();
    }
  }
}
