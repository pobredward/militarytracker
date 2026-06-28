import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ranking_model.dart';
import '../../../providers/ranking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/user_card.dart';
import '../../profile/presentation/user_profile_screen.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserRanking = ref.watch(currentUserRankingProvider);
    final rankings = ref.watch(rankingListProvider);
    final selectedPeriod = ref.watch(selectedRankingPeriodProvider);
    final selectedCategory = ref.watch(selectedRankingCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildCustomAppBar(context),
            
            // 기간 선택 탭
            _buildPeriodSelector(selectedPeriod),
            
            // 카테고리 탭
            _buildCategoryTabs(),
            
            // 내 랭킹 카드
            currentUserRanking.when(
              data: (myRanking) => myRanking != null
                  ? _buildMyRankingCard(myRanking)
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            
            // 랭킹 리스트
            Expanded(
              child: rankings.when(
                data: (rankingList) => _buildRankingList(rankingList, currentUser?.uid),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00C853),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFCF6679),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '랭킹을 불러올 수 없습니다',
                        style: TextStyle(
                          color: const Color(0xFFCF6679).withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(rankingListProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF121212).withOpacity(0),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF9800).withOpacity(0.2),
                  const Color(0xFFFF9800).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFF9800),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEADERBOARD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF9800),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '순위표',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ref.refresh(rankingListProvider),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(RankingPeriod selectedPeriod) {
    final periods = [
      (RankingPeriod.daily, '일간', Icons.today_rounded),
      (RankingPeriod.weekly, '주간', Icons.view_week_rounded),
      (RankingPeriod.monthly, '월간', Icons.calendar_month_rounded),
      (RankingPeriod.allTime, '전체', Icons.all_inclusive_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedRankingPeriodProvider.notifier).state = period.$1;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      period.$3,
                      size: 16,
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      period.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.black
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFFFF9800),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFF9800),
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onTap: (index) {
          final categories = RankingCategory.values;
          ref.read(selectedRankingCategoryProvider.notifier).state = categories[index];
        },
        tabs: const [
          Tab(text: '종합'),
          Tab(text: '스쿼트'),
          Tab(text: '런지'),
          Tab(text: '걷기'),
          Tab(text: '뛰기'),
        ],
      ),
    );
  }

  Widget _buildMyRankingCard(RankingModel myRanking) {
    if (myRanking.rank == 0) return const SizedBox();

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF9800).withOpacity(0.15),
              const Color(0xFFFF9800).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _buildRankBadge(myRanking.rank, isMyRank: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 순위',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    myRanking.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ],
              ),
            ),
            _buildScoreDisplay(myRanking),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingList(List<RankingModel> rankings, String? currentUserId) {
    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: const Color(0xFF9E9E9E).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 랭킹 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9E9E9E).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '운동을 시작하고 랭킹에 도전해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final isCurrentUser = ranking.userId == currentUserId;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.05).clamp(0.0, 1.0),
            ((index * 0.05) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: _buildRankingItem(ranking, isCurrentUser),
          ),
        );
      },
    );
  }

  Widget _buildRankingItem(RankingModel ranking, bool isCurrentUser) {
    return GestureDetector(
      onTap: () {
        // 사용자 프로필 바텀시트 표시
        UserDetailCard.show(context, ranking.userId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color(0xFFFF9800).withOpacity(0.1)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? const Color(0xFFFF9800).withOpacity(0.3)
                : const Color(0xFF2A2A2A),
            width: isCurrentUser ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildRankBadge(ranking.rank, isMyRank: isCurrentUser),
            const SizedBox(width: 16),
            Hero(
              tag: 'user_avatar_${ranking.userId}',
              child: ranking.photoUrl != null
                  ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(ranking.photoUrl!),
                      backgroundColor: const Color(0xFF2A2A2A),
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2A2A2A),
                      child: Text(
                        ranking.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFE0E0E0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _buildSubStats(ranking),
                ],
              ),
            ),
            _buildScoreDisplay(ranking),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, {bool isMyRank = false}) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // 금색
      icon = Icons.workspace_premium_rounded;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // 은색
      icon = Icons.workspace_premium_rounded;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // 동색
      icon = Icons.workspace_premium_rounded;
    } else {
      badgeColor = isMyRank
          ? const Color(0xFFFF9800)
          : const Color(0xFF424242);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: rank <= 3
            ? LinearGradient(
                colors: [badgeColor, badgeColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: rank > 3 ? badgeColor : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: rank <= 3
              ? badgeColor.withOpacity(0.3)
              : const Color(0xFF2A2A2A),
          width: 2,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                color: rank <= 3 ? Colors.black : const Color(0xFFE0E0E0),
                size: 28,
              )
            : Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isMyRank
                      ? Colors.black
                      : const Color(0xFFE0E0E0),
                ),
              ),
      ),
    );
  }

  Widget _buildSubStats(RankingModel ranking) {
    final category = ref.watch(selectedRankingCategoryProvider);
    
    String statsText = '';
    
    switch (category) {
      case RankingCategory.overall:
        statsText = 'S:${ranking.squatCount} L:${ranking.lungeCount} '
            'W:${ranking.walkSteps} R:${ranking.runDistance.toStringAsFixed(1)}km';
        break;
      case RankingCategory.squats:
        statsText = '${ranking.squatCount}회';
        break;
      case RankingCategory.lunges:
        statsText = '${ranking.lungeCount}회';
        break;
      case RankingCategory.walking:
        statsText = '${ranking.walkSteps}보';
        break;
      case RankingCategory.running:
        statsText = '${ranking.runDistance.toStringAsFixed(1)}km';
        break;
    }

    return Text(
      statsText,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9E9E),
      ),
    );
  }

  Widget _buildScoreDisplay(RankingModel ranking) {
    final category = ref.watch(selectedRankingCategoryProvider);
    final score = ranking.getScoreForCategory(category);
    
    String scoreText;
    String unit;
    
    switch (category) {
      case RankingCategory.overall:
        scoreText = score.toStringAsFixed(0);
        unit = 'pts';
        break;
      case RankingCategory.squats:
      case RankingCategory.lunges:
        scoreText = score.toStringAsFixed(0);
        unit = '회';
        break;
      case RankingCategory.walking:
        scoreText = score.toStringAsFixed(0);
        unit = '보';
        break;
      case RankingCategory.running:
        scoreText = score.toStringAsFixed(1);
        unit = 'km';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          scoreText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF9800),
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
