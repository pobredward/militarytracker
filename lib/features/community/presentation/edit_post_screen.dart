import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../core/config/logger.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  int _uploadedImageCount = 0;
  
  // 기존 이미지 URL 목록
  late List<String> _existingImageUrls;
  
  // 새로 선택한 이미지 파일 목록
  final List<XFile> _newImages = [];
  
  // 삭제할 이미지 URL 목록
  final List<String> _imagesToDelete = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _existingImageUrls = List.from(widget.post.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 이미지 추가
  Future<void> _pickImages() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 5장까지 선택 가능합니다'),
          backgroundColor: Color(0xFFCF6679),
        ),
      );
      return;
    }

    final storageService = ref.read(storageServiceProvider);
    final images = await storageService.pickMultipleImages(
      maxImages: 5 - totalImages,
    );

    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  // 기존 이미지 삭제
  void _removeExistingImage(int index) {
    setState(() {
      final url = _existingImageUrls[index];
      _imagesToDelete.add(url);
      _existingImageUrls.removeAt(index);
    });
  }

  // 새 이미지 삭제
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    logger.i('Starting post update process');
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final firebaseUser = authState.value;
      
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 1. 삭제할 이미지들을 Storage에서 삭제
      if (_imagesToDelete.isNotEmpty) {
        logger.i('Deleting ${_imagesToDelete.length} images from storage');
        final storageService = ref.read(storageServiceProvider);
        for (final url in _imagesToDelete) {
          try {
            await storageService.deleteFile(url);
            logger.d('Deleted image: $url');
          } catch (e) {
            logger.e('Failed to delete image: $url, error: $e');
            // 삭제 실패는 치명적이지 않으므로 계속 진행
          }
        }
      }

      // 2. 새 이미지들을 Storage에 업로드 (Web/Mobile 지원)
      final newImageUrls = <String>[];
      if (_newImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
          _uploadedImageCount = 0;
        });

        logger.i('═══ Starting image uploads ═══');
        logger.i('Total images to upload: ${_newImages.length}');
        
        final storageService = ref.read(storageServiceProvider);
        
        // 각 이미지 업로드 (Web과 Mobile 모두 지원)
        for (int i = 0; i < _newImages.length; i++) {
          logger.d('Uploading image ${i + 1}/${_newImages.length}');
          
          // XFile을 직접 전달 (StorageService가 Web/Mobile 자동 처리)
          final url = await storageService.uploadPostImage(_newImages[i], firebaseUser.uid);
          
          if (url != null) {
            newImageUrls.add(url);
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
        logger.i('Successful uploads: ${newImageUrls.length}/${_newImages.length}');
        
        // 업로드 실패한 이미지가 있는지 확인
        if (newImageUrls.isEmpty && _newImages.isNotEmpty) {
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
        } else if (newImageUrls.length < _newImages.length) {
          // 일부 이미지만 업로드 성공
          logger.w('Some images failed to upload');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('일부 이미지 업로드 실패 (${newImageUrls.length}/${_newImages.length} 성공)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // 3. 최종 이미지 URL 목록 생성 (기존 + 새로운)
      final finalImageUrls = [..._existingImageUrls, ...newImageUrls];

      // 4. 게시글 업데이트
      logger.i('Updating post in Firestore...');
      final updatedPost = widget.post.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrls: finalImageUrls,
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(postRepositoryProvider).updatePost(updatedPost);

      if (!mounted) return;

      if (success) {
        logger.i('✅ Post updated successfully');
        ref.invalidate(postsProvider);
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // 상세 화면도 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 수정되었습니다'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      } else {
        throw Exception('게시글 수정에 실패했습니다');
      }
    } catch (e, stackTrace) {
      logger.e('Error updating post: $e');
      logger.e('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 수정 실패: $e'),
            backgroundColor: const Color(0xFFCF6679),
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
              '게시글 수정',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE0E0E0),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
              onPressed: () => Navigator.of(context).pop(),
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
                height: 300,
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
              
              // 이미지 추가 버튼
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.image, color: Color(0xFF00C853)),
                  title: Text(
                    '이미지 추가 (${_existingImageUrls.length + _newImages.length}/5)',
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
              
              // 기존 이미지 미리보기
              if (_existingImageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '기존 이미지',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrls[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: const Color(0xFF2A2A2A),
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Color(0xFF616161),
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _isSubmitting ? null : () => _removeExistingImage(index),
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
              
              // 새로 추가한 이미지 미리보기
              if (_newImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '새로 추가한 이미지',
                  style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: _newImages[index].readAsBytes(),
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
                                      File(_newImages[index].path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _isSubmitting ? null : () => _removeNewImage(index),
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
                            // 새 이미지 표시
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
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
                        '이미지를 삭제하거나 추가할 수 있습니다.',
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
                    const Text(
                      '이미지 업로드 중...',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_uploadedImageCount / ${_newImages.length}',
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




