import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/config/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  /// 이미지 선택 (갤러리)
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      logger.e('Error picking image from gallery: $e');
      return null;
    }
  }

  /// 다중 이미지 선택
  Future<List<XFile>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      // 최대 개수 제한
      if (images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      
      return images;
    } catch (e) {
      logger.e('Error picking multiple images: $e');
      return [];
    }
  }

  /// 이미지 선택 (카메라)
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      logger.e('Error picking image from camera: $e');
      return null;
    }
  }

  /// 동영상 선택
  Future<XFile?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      logger.e('Error picking video: $e');
      return null;
    }
  }

  /// 이미지 압축 (Web에서는 bytes 압축)
  Future<dynamic> compressImage(dynamic input) async {
    try {
      // Web 플랫폼인 경우
      if (kIsWeb) {
        logger.d('Web platform detected - compressing XFile');
        
        if (input is! XFile) {
          logger.e('Web requires XFile input');
          return input;
        }
        
        final XFile xFile = input;
        final bytes = await xFile.readAsBytes();
        final originalSize = bytes.length;
        logger.d('Original file size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        
        // Web용 압축
        final result = await FlutterImageCompress.compressWithList(
          bytes,
          quality: 85,
          minWidth: 1080,
          minHeight: 1080,
          format: CompressFormat.jpeg,
        );
        
        if (result.isNotEmpty) {
          final compressedSize = result.length;
          final compressionRatio = (1 - compressedSize / originalSize) * 100;
          
          logger.i('Image compressed successfully (Web)');
          logger.i('Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
          logger.i('Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
          logger.i('Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
          
          return result; // Uint8List 반환
        }
        
        logger.w('Web compression failed, using original bytes');
        return bytes;
      }
      
      // 모바일 플랫폼 (기존 로직)
      if (input is! File) {
        logger.e('Mobile platform requires File input');
        return input;
      }
      
      final File file = input;
      logger.d('Starting image compression for: ${file.path}');
      
      // 파일 존재 여부 확인
      if (!await file.exists()) {
        logger.e('Source file does not exist: ${file.path}');
        return null;
      }
      
      final originalSize = await file.length();
      logger.d('Original file size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${_uuid.v4()}.jpg',
      );
      
      logger.d('Compression target path: $targetPath');

      // compressAndGetFile은 XFile?를 반환
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        // XFile을 File로 변환
        final compressedFile = File(result.path);
        
        // 압축된 파일 존재 여부 확인
        if (!await compressedFile.exists()) {
          logger.e('Compressed file was not created: ${result.path}');
          return null;
        }
        
        final compressedSize = await compressedFile.length();
        final compressionRatio = (1 - compressedSize / originalSize) * 100;
        
        logger.i('Image compressed successfully');
        logger.i('Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        logger.i('Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        logger.i('Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
        logger.i('Compressed file path: ${compressedFile.path}');
        
        return compressedFile;
      }
      
      logger.w('Image compression returned null result, using original file');
      // 압축 실패 시 원본 파일 사용
      return file;
    } catch (e, stackTrace) {
      logger.e('Error compressing image: $e');
      logger.e('Stack trace: $stackTrace');
      logger.w('Compression failed, using original');
      // 압축 실패해도 원본 사용
      return input;
    }
  }

  /// 이미지 업로드 (게시글용) - Web/Mobile 지원
  Future<String?> uploadPostImage(dynamic input, String userId) async {
    dynamic compressedData;
    
    try {
      logger.i('═══ Starting image upload ═══');
      logger.i('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      logger.i('User ID: $userId');
      
      // Web 플랫폼 처리
      if (kIsWeb) {
        logger.d('Processing Web upload');
        
        XFile xFile;
        if (input is XFile) {
          xFile = input;
        } else if (input is File) {
          logger.e('❌ Web cannot use File type');
          return null;
        } else {
          logger.e('❌ Invalid input type for Web');
          return null;
        }
        
        logger.i('XFile name: ${xFile.name}');
        
        // 이미지 압축 (bytes)
        logger.d('📦 Compressing image...');
        compressedData = await compressImage(xFile);
        
        Uint8List bytes;
        if (compressedData is Uint8List) {
          bytes = compressedData;
        } else {
          logger.w('Compression returned unexpected type, reading original bytes');
          bytes = await xFile.readAsBytes();
        }
        
        logger.i('✅ Image ready for upload: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

        // Storage 경로 생성
        final fileName = '${_uuid.v4()}.jpg';
        final storagePath = 'posts/$userId/$fileName';
        final ref = _storage.ref().child(storagePath);
        
        logger.d('📂 Storage path: $storagePath');

        // 메타데이터 설정
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        // 업로드 (Web은 putData 사용)
        logger.d('☁️ Starting Firebase Storage upload (Web)...');
        final uploadTask = ref.putData(bytes, metadata);
        
        // 업로드 진행률 모니터링
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
            logger.d('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
          },
          onError: (error) {
            logger.e('❌ Upload stream error: $error');
          },
        );
        
        final snapshot = await uploadTask;
        logger.i('✅ Upload completed. State: ${snapshot.state}');

        // 업로드 상태 확인
        if (snapshot.state != TaskState.success) {
          logger.e('❌ Upload failed with state: ${snapshot.state}');
          return null;
        }

        // 다운로드 URL 가져오기
        logger.d('🔗 Getting download URL...');
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        logger.i('✅ Image uploaded successfully (Web)');
        logger.i('🔗 URL: $downloadUrl');
        
        return downloadUrl;
      }
      
      // 모바일 플랫폼 처리 (기존 로직)
      File file;
      if (input is File) {
        file = input;
      } else if (input is XFile) {
        file = File(input.path);
      } else {
        logger.e('❌ Invalid input type for Mobile');
        return null;
      }
      
      logger.i('Image file path: ${file.path}');
      
      // 파일 존재 확인
      if (!await file.exists()) {
        logger.e('❌ File does not exist: ${file.path}');
        return null;
      }
      
      final originalSize = await file.length();
      logger.i('Image file size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      
      // 이미지 압축
      logger.d('📦 Compressing image...');
      compressedData = await compressImage(file);
      if (compressedData == null) {
        logger.e('❌ Image compression failed completely');
        return null;
      }
      
      File compressedFile;
      if (compressedData is File) {
        compressedFile = compressedData;
      } else {
        logger.e('❌ Unexpected compression result type');
        return null;
      }
      
      // 압축된 파일 확인
      if (!await compressedFile.exists()) {
        logger.e('❌ Compressed file does not exist: ${compressedFile.path}');
        return null;
      }
      
      final compressedSize = await compressedFile.length();
      logger.i('✅ Image ready for upload: ${(compressedSize / 1024).toStringAsFixed(2)} KB');

      // Storage 경로 생성
      final fileName = '${_uuid.v4()}.jpg';
      final storagePath = 'posts/$userId/$fileName';
      final ref = _storage.ref().child(storagePath);
      
      logger.d('📂 Storage path: $storagePath');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 업로드 (Mobile은 putFile 사용)
      logger.d('☁️ Starting Firebase Storage upload (Mobile)...');
      final uploadTask = ref.putFile(compressedFile, metadata);
      
      // 업로드 진행률 모니터링 (에러 처리 추가)
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
          logger.d('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
        },
        onError: (error) {
          logger.e('❌ Upload stream error: $error');
        },
      );
      
      final snapshot = await uploadTask;
      logger.i('✅ Upload completed. State: ${snapshot.state}');

      // 업로드 상태 확인
      if (snapshot.state != TaskState.success) {
        logger.e('❌ Upload failed with state: ${snapshot.state}');
        return null;
      }

      // 다운로드 URL 가져오기
      logger.d('🔗 Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      logger.i('✅ Image uploaded successfully (Mobile)');
      logger.i('🔗 URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      logger.e('❌ Error uploading image: $e');
      logger.e('Stack trace: $stackTrace');
      
      if (e is FirebaseException) {
        logger.e('Firebase error code: ${e.code}');
        logger.e('Firebase error message: ${e.message}');
        logger.e('Firebase error plugin: ${e.plugin}');
      }
      
      return null;
    } finally {
      // 임시 파일 정리 (Mobile만 해당)
      if (!kIsWeb && compressedData != null && compressedData is File) {
        try {
          final File compressedFile = compressedData;
          if (input is File) {
            final File originalFile = input;
            if (compressedFile.path != originalFile.path && await compressedFile.exists()) {
              await compressedFile.delete();
              logger.d('🗑️ Temporary compressed file deleted');
            }
          }
        } catch (e) {
          logger.w('Failed to delete temporary file: $e');
        }
      }
    }
  }

  /// 여러 이미지 업로드
  Future<List<String>> uploadMultipleImages(List<File> files, String userId) async {
    logger.i('Starting multiple image upload: ${files.length} files');
    final urls = <String>[];
    
    for (int i = 0; i < files.length; i++) {
      logger.d('Uploading image ${i + 1}/${files.length}');
      final url = await uploadPostImage(files[i], userId);
      if (url != null) {
        urls.add(url);
        logger.i('Image ${i + 1} uploaded successfully');
      } else {
        logger.e('Failed to upload image ${i + 1}');
      }
    }
    
    logger.i('Multiple image upload completed: ${urls.length}/${files.length} successful');
    return urls;
  }

  /// 동영상 업로드
  Future<String?> uploadVideo(File file, String userId) async {
    try {
      final fileName = '${_uuid.v4()}.mp4';
      final ref = _storage.ref().child('videos/$userId/$fileName');

      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      
      // 진행률 로깅
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        logger.d('Video upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      logger.i('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading video: $e');
      return null;
    }
  }

  /// 프로필 사진 업로드
  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      final compressedFile = await compressImage(file);
      if (compressedFile == null) return null;

      final ref = _storage.ref().child('profiles/$userId/profile.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=3600',
      );

      final uploadTask = ref.putFile(compressedFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      logger.i('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading profile image: $e');
      return null;
    }
  }

  /// 파일 삭제
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      logger.i('File deleted successfully: $url');
      return true;
    } catch (e) {
      logger.e('Error deleting file: $e');
      return false;
    }
  }

  /// 여러 파일 삭제
  Future<void> deleteMultipleFiles(List<String> urls) async {
    for (final url in urls) {
      await deleteFile(url);
    }
  }

  /// Uint8List로부터 업로드 (웹용)
  Future<String?> uploadImageFromBytes(
    Uint8List bytes,
    String userId,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref().child('posts/$userId/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      logger.i('Image uploaded from bytes successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading image from bytes: $e');
      return null;
    }
  }
}




