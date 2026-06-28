import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;
  final IconData icon;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
    this.isExpanded = false,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: '어떻게 운동을 기록하나요?',
      answer: '하단 네비게이션의 "운동" 탭을 선택하면 스쿼트, 런지, 걷기, 달리기 등 다양한 운동을 기록할 수 있습니다. 각 운동 카드를 탭하여 시작하세요.',
      icon: Icons.fitness_center_rounded,
    ),
    FAQItem(
      question: '운동 목표는 어떻게 설정하나요?',
      answer: '현재 앱에서 제공하는 기본 목표는 스쿼트 30회, 런지 30회, 걷기 5,000보, 달리기 2km입니다. 향후 업데이트를 통해 사용자 지정 목표를 설정할 수 있습니다.',
      icon: Icons.flag_rounded,
    ),
    FAQItem(
      question: '운동 기록이 저장되지 않아요',
      answer: '인터넷 연결을 확인해주세요. 운동 기록은 Firebase에 저장되므로 안정적인 인터넷 연결이 필요합니다. 문제가 지속되면 앱을 재시작해보세요.',
      icon: Icons.cloud_off_rounded,
    ),
    FAQItem(
      question: '업적은 어떻게 획득하나요?',
      answer: '운동을 꾸준히 하면 자동으로 업적이 잠금 해제됩니다. 프로필 > 업적 메뉴에서 모든 업적과 진행 상황을 확인할 수 있습니다.',
      icon: Icons.emoji_events_rounded,
    ),
    FAQItem(
      question: '커뮤니티에서 사진을 업로드할 수 없어요',
      answer: '앱에 카메라와 갤러리 접근 권한이 있는지 확인하세요. 설정 > 권한에서 권한을 허용해주세요. 사진 크기는 10MB를 초과할 수 없습니다.',
      icon: Icons.photo_camera_rounded,
    ),
    FAQItem(
      question: '프로필 사진을 변경하려면?',
      answer: '프로필 > 프로필 수정으로 이동하여 프로필 사진을 탭하면 카메라 촬영 또는 갤러리에서 선택할 수 있습니다.',
      icon: Icons.person_rounded,
    ),
    FAQItem(
      question: '데이터가 안전하게 보관되나요?',
      answer: '네, 모든 데이터는 Google Firebase를 통해 암호화되어 안전하게 저장됩니다. 개인정보는 철저히 보호되며, 제3자와 공유되지 않습니다.',
      icon: Icons.security_rounded,
    ),
    FAQItem(
      question: '계정을 삭제하면 어떻게 되나요?',
      answer: '계정을 삭제하면 모든 운동 기록, 커뮤니티 게시글, 댓글 등이 영구적으로 삭제됩니다. 이 작업은 취소할 수 없으니 신중히 결정해주세요.',
      icon: Icons.delete_forever_rounded,
    ),
    FAQItem(
      question: '알림이 오지 않아요',
      answer: '프로필 > 알림 설정에서 원하는 알림을 활성화했는지 확인하세요. 또한 기기의 시스템 설정에서 앱 알림이 허용되어 있는지 확인해주세요.',
      icon: Icons.notifications_off_rounded,
    ),
    FAQItem(
      question: '여러 기기에서 사용할 수 있나요?',
      answer: '네, 같은 계정으로 로그인하면 여러 기기에서 동일한 데이터를 확인하고 동기화할 수 있습니다.',
      icon: Icons.devices_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'HELP & FAQ',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 카드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0).withOpacity(0.15),
                      const Color(0xFF9C27B0).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF9C27B0),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '도움이 필요하신가요?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '자주 묻는 질문을 확인해보세요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 빠른 링크
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF00C853), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '빠른 링크',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickLinkCard(
                      icon: Icons.email_rounded,
                      label: '문의하기',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        // TODO: 이메일 앱 열기
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('support@militarytracker.com'),
                            backgroundColor: Color(0xFF2196F3),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickLinkCard(
                      icon: Icons.description_rounded,
                      label: '이용약관',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이용약관 페이지로 이동합니다'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickLinkCard(
                      icon: Icons.privacy_tip_rounded,
                      label: '개인정보처리',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('개인정보처리방침 페이지로 이동합니다'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickLinkCard(
                      icon: Icons.forum_rounded,
                      label: '커뮤니티',
                      color: const Color(0xFF00C853),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // FAQ 섹션
              const Row(
                children: [
                  Icon(Icons.quiz_rounded, color: Color(0xFF00C853), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '자주 묻는 질문',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FAQ 리스트
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqItems.length,
                itemBuilder: (context, index) {
                  final item = _faqItems[index];
                  return _buildFAQCard(item, index);
                },
              ),

              const SizedBox(height: 32),

              // 추가 도움말
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF00C853),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '더 많은 도움이 필요하신가요?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E0E0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '언제든지 문의해주세요.\n24시간 이내에 답변드리겠습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('support@militarytracker.com'),
                            backgroundColor: Color(0xFF00C853),
                          ),
                        );
                      },
                      icon: const Icon(Icons.email_rounded),
                      label: const Text('이메일 보내기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE0E0E0),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isExpanded 
              ? const Color(0xFF00C853).withOpacity(0.5)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.isExpanded
                  ? const Color(0xFF00C853).withOpacity(0.1)
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: item.isExpanded 
                  ? const Color(0xFF00C853)
                  : const Color(0xFF616161),
              size: 24,
            ),
          ),
          title: Text(
            item.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: item.isExpanded 
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF9E9E9E),
            ),
          ),
          trailing: Icon(
            item.isExpanded 
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: item.isExpanded 
                ? const Color(0xFF00C853)
                : const Color(0xFF616161),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              item.isExpanded = expanded;
            });
          },
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFFE0E0E0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




