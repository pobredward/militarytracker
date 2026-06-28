import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../models/post_model.dart';
import '../../../core/config/logger.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  int _uploadedImageCount = 0;
  final List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5장까지 선택 가능합니다')),
      );
      return;
    }

    final storageService = ref.read(storageServiceProvider);
    final images = await storageService.pickMultipleImages(
      maxImages: 5 - _selectedImages.length,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    logger.i('Starting post submission process');
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      await authState.when(
        data: (firebaseUser) async {
          if (firebaseUser == null) {
            logger.e('User not authenticated');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('로그인이 필요합니다'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          logger.i('Authenticated user: ${firebaseUser.uid}');

          await currentUser.when(
            data: (user) async {
              if (user == null) {
                logger.e('User profile not found');
                return;
              }

              logger.i('User profile loaded: ${user.displayName}');

              // 이미지 업로드
              final imageUrls = <String>[];
              if (_selectedImages.isNotEmpty) {
                setState(() {
                  _isUploadingImages = true;
                  _uploadedImageCount = 0;
                });

                logger.i('═══ Starting image uploads ═══');
                logger.i('Total images to upload: ${_selectedImages.length}');
                
                final storageService = ref.read(storageServiceProvider);
                
                // 각 이미지 업로드 시 카운터 업데이트
                // Web과 Mobile 모두 지원하기 위해 XFile 직접 전달
                for (int i = 0; i < _selectedImages.length; i++) {
                  logger.d('Uploading image ${i + 1}/${_selectedImages.length}');
                  
                  final url = await storageService.uploadPostImage(_selectedImages[i], firebaseUser.uid);
                  
                  if (url != null) {
                    imageUrls.add(url);
                    logger.i('✅ Image ${i + 1} uploaded successfully');
                    
                    if (mounted) {
                      setState(() {
                        _uploadedImageCount = i + 1;
                      });
                    }
                  } else {
                    logger.e('❌ Image ${i + 1} upload failed');
                  }
                }
                
                setState(() => _isUploadingImages = false);
                
                logger.i('═══ Image upload completed ═══');
                logger.i('Successful uploads: ${imageUrls.length}/${_selectedImages.length}');

                // 업로드 결과 처리
                if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
                  // 모든 이미지 업로드 실패
                  logger.e('All images failed to upload');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이미지 업로드에 실패했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                  return;
                } else if (imageUrls.length < _selectedImages.length) {
                  // 일부 이미지만 업로드 성공
                  logger.w('Some images failed to upload');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('일부 이미지 업로드 실패 (${imageUrls.length}/${_selectedImages.length} 성공)\n계속 진행하시겠습니까?'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: '계속',
                          textColor: Colors.white,
                          onPressed: () {
                            // 사용자가 계속 진행하기로 선택
                          },
                        ),
                      ),
                    );
                    
                    // 잠시 대기 (사용자가 메시지를 볼 수 있도록)
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
                }
              }

              logger.i('Creating post model...');
              final newPost = PostModel(
                id: '',
                authorId: firebaseUser.uid,
                authorName: user.displayName,
                authorPhotoUrl: user.photoUrl,
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                imageUrls: imageUrls,
                likes: 0,
                comments: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              logger.i('Saving post to Firestore...');
              logger.d('Post details:');
              logger.d('  - Title: ${newPost.title}');
              logger.d('  - Content length: ${newPost.content.length} chars');
              logger.d('  - Images: ${newPost.imageUrls.length}');
              logger.d('  - Author: ${newPost.authorName} (${newPost.authorId})');
              
              final postId = await ref.read(postRepositoryProvider).createPost(newPost);

              if (!mounted) return;

              if (postId != null) {
                logger.i('✅ Post created successfully with ID: $postId');
                ref.invalidate(postsProvider);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('게시글이 작성되었습니다'),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
                Navigator.of(context).pop();
              } else {
                logger.e('❌ Failed to create post: postId is null');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('게시글 작성에 실패했습니다. 네트워크를 확인해주세요.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            loading: () {
              logger.w('User profile is loading');
            },
            error: (error, stack) {
              logger.e('Error loading user profile: $error');
            },
          );
        },
        loading: () {
          logger.w('Auth state is loading');
        },
        error: (error, stack) {
          logger.e('Auth state error: $error');
        },
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error during post submission: $e');
      logger.e('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              '게시글 작성',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE0E0E0),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submitPost,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                      ),
                    )
                  : const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00C853),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // 제목 입력
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    if (value.trim().length < 2) {
                      return '제목은 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 16),
              
              // 내용 입력
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요',
                    hintStyle: TextStyle(
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요';
                    }
                    if (value.trim().length < 10) {
                      return '내용은 10자 이상이어야 합니다';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 24),
              
              // 이미지 선택 버튼
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.image, color: Color(0xFF00C853)),
                  title: Text(
                    '이미지 추가 (${_selectedImages.length}/5)',
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    '최대 5장까지 선택 가능',
                    style: TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.add_photo_alternate, color: Color(0xFF9E9E9E)),
                  onTap: _isSubmitting ? null : _pickImages,
                ),
              ),
              
              // 선택된 이미지 미리보기
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: _selectedImages[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: const Color(0xFF2A2A2A),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(_selectedImages[index].path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // 안내 텍스트
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Color(0xFF00C853),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '운동 경험, 팁, 목표 등을 공유해주세요!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
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
    ),
        
        // 로딩 오버레이
        if (_isUploadingImages)
          Container(
            color: Colors.black87,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '이미지 업로드 중...',
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_uploadedImageCount / ${_selectedImages.length}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

