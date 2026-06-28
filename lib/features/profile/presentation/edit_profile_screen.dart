import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../services/profile_image_service.dart';
import '../../../core/config/logger.dart';
import '../../../widgets/app_snackbar.dart';

// ProfileImageService Provider
final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService();
});

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _currentPhotoUrl = user.photoUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(profileImageServiceProvider);
    
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF00C853)),
              ),
              title: const Text(
                '카메라로 촬영',
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF2196F3)),
              ),
              title: const Text(
                '갤러리에서 선택',
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            if (_currentPhotoUrl != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCF6679).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Color(0xFFCF6679)),
                ),
                title: const Text(
                  '프로필 사진 삭제',
                  style: TextStyle(
                    color: Color(0xFFCF6679),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentPhotoUrl = null;
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );

    if (result != null) {
      final pickResult = await imageService.pickImage(source: result);
      pickResult.when(
        success: (file) {
          setState(() {
            _selectedImage = file;
          });
        },
        failure: (message, _) {
          if (mounted) {
            AppSnackBar.showError(context, message);
          }
        },
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      final imageService = ref.read(profileImageServiceProvider);
      final authRepository = ref.read(authRepositoryProvider);
      
      String? photoUrl = _currentPhotoUrl;
      bool deletePhoto = false;
      
      // 1. 기존 프로필 사진 삭제 (새 이미지 선택 또는 삭제한 경우)
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        if (_selectedImage != null || _currentPhotoUrl == null) {
          await imageService.deleteProfileImage(user.photoUrl!);
        }
      }
      
      // 2. 새 이미지 업로드
      if (_selectedImage != null) {
        final uploadResult = await imageService.uploadProfileImage(
          userId: user.id,
          imageFile: _selectedImage!,
          compress: true,
        );
        
        uploadResult.when(
          success: (url) {
            photoUrl = url;
            deletePhoto = false;
          },
          failure: (message, _) {
            throw Exception(message);
          },
        );
      } else if (_currentPhotoUrl == null) {
        // 프로필 사진을 삭제만 한 경우
        photoUrl = null;
        deletePhoto = true;
      }

      // 3. 프로필 업데이트
      final success = await authRepository.updateProfile(
        userId: user.id,
        displayName: _displayNameController.text.trim(),
        photoUrl: photoUrl,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        deletePhoto: deletePhoto,
      );

      if (!success) {
        throw Exception('프로필 업데이트에 실패했습니다');
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, '프로필이 업데이트되었습니다');
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('프로필 업데이트 실패: $e');
      if (mounted) {
        AppSnackBar.showError(context, '프로필 업데이트 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'EDIT PROFILE',
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
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00C853),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: currentUser.when(
          data: (user) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // 프로필 이미지
                  Stack(
                    children: [
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
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_currentPhotoUrl != null
                                  ? NetworkImage(_currentPhotoUrl!)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null && _currentPhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF9E9E9E),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C853), Color(0xFF00E676)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF121212),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '사진 변경',
                    style: TextStyle(
                      color: const Color(0xFF00C853).withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 닉네임 입력
                  _buildInputField(
                    controller: _displayNameController,
                    label: '닉네임',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      if (value.length < 2) {
                        return '닉네임은 2자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 이메일 (읽기 전용)
                  _buildInputField(
                    initialValue: user?.email ?? '',
                    label: '이메일',
                    icon: Icons.email_outlined,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 20),

                  // 로그인 방법 (읽기 전용)
                  _buildInputField(
                    initialValue: user?.authProvider == 'google' ? 'Google 로그인' : '이메일 로그인',
                    label: '로그인 방법',
                    icon: Icons.security_outlined,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 20),

                  // 소개
                  _buildInputField(
                    controller: _bioController,
                    label: '소개 (선택사항)',
                    icon: Icons.edit_note_rounded,
                    maxLines: 4,
                    maxLength: 150,
                    hintText: '자신을 소개해보세요...',
                  ),
                  const SizedBox(height: 40),

                  // 통계 정보 (읽기 전용)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00C853).withOpacity(0.1),
                          const Color(0xFF00C853).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00C853).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFF00C853),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '나의 운동 기록',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatBadge(
                              label: '운동일',
                              value: '${user?.workoutDays ?? 0}일',
                              icon: Icons.calendar_today,
                            ),
                            _buildStatBadge(
                              label: '총 스쿼트',
                              value: '${user?.totalSquats ?? 0}회',
                              icon: Icons.accessibility_new,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatBadge(
                              label: '총 런지',
                              value: '${user?.totalLunges ?? 0}회',
                              icon: Icons.directions_run,
                            ),
                            _buildStatBadge(
                              label: '총 걷기',
                              value: '${user?.totalWalkSteps ?? 0}보',
                              icon: Icons.directions_walk,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00C853)),
          ),
          error: (_, __) => const Center(
            child: Text(
              '사용자 정보를 불러올 수 없습니다',
              style: TextStyle(color: Color(0xFFCF6679)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00C853)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(
            color: enabled ? const Color(0xFFE0E0E0) : const Color(0xFF616161),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF616161)),
            filled: true,
            fillColor: enabled ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: enabled ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C853), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCF6679)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00C853), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE0E0E0),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF616161),
          ),
        ),
      ],
    );
  }
}

