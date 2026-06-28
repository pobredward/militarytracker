import 'package:flutter/material.dart';

/// 프로필 헤더 (프로필 이미지 + 닉네임 + 통계)
class ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final int workoutDays;
  final int followerCount;
  final int followingCount;
  final VoidCallback? onEditPressed;
  final VoidCallback? onFollowersPressed;
  final VoidCallback? onFollowingPressed;

  const ProfileHeader({
    super.key,
    this.photoUrl,
    required this.displayName,
    required this.workoutDays,
    required this.followerCount,
    required this.followingCount,
    this.onEditPressed,
    this.onFollowersPressed,
    this.onFollowingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 프로필 이미지
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00C853),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF1E1E1E),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF9E9E9E),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // 닉네임
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE0E0E0),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // 통계 (운동일, 팔로워, 팔로잉)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              label: '운동일',
              value: workoutDays.toString(),
              icon: Icons.fitness_center,
              onTap: null,
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF2A2A2A),
            ),
            _buildStatItem(
              label: '팔로워',
              value: followerCount.toString(),
              icon: Icons.people_outline,
              onTap: onFollowersPressed,
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF2A2A2A),
            ),
            _buildStatItem(
              label: '팔로잉',
              value: followingCount.toString(),
              icon: Icons.person_add_outlined,
              onTap: onFollowingPressed,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 프로필 수정 버튼
        if (onEditPressed != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text(
                '프로필 수정',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFF00C853),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final child = Column(
      children: [
        Icon(icon, color: const Color(0xFF00C853), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE0E0E0),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

/// 프로필 통계 카드
class ProfileStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<StatItem> items;

  const ProfileStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E).withOpacity(0.8),
            const Color(0xFF1E1E1E).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF00C853), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStatRow(
                  label: item.label,
                  value: item.value,
                  icon: item.icon,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData icon;

  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// 프로필 메뉴 아이템
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showTrailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF00C853)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF00C853),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0E0E0),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              )
            : null,
        trailing: showTrailing
            ? const Icon(
                Icons.chevron_right,
                color: Color(0xFF616161),
              )
            : null,
      ),
    );
  }
}

/// 팔로우 버튼
class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? const Color(0xFF1E1E1E) : const Color(0xFF00C853),
          foregroundColor:
              isFollowing ? const Color(0xFF00C853) : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isFollowing
                ? const BorderSide(
                    color: Color(0xFF00C853),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00C853),
                ),
              )
            : Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

/// 빈 상태 표시 위젯
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2A2A2A),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 64,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
