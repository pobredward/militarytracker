import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/config/logger.dart';
import '../core/utils/result.dart';

/// 프로필 이미지 업로드 및 처리를 담당하는 서비스
class ProfileImageService {
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  ProfileImageService({
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  /// 이미지 선택 (갤러리 or 카메라)
  Future<Result<File>> pickImage({
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return const Failure('이미지를 선택하지 않았습니다');
      }

      final file = File(pickedFile.path);
      AppLogger.d('이미지 선택 완료: ${file.path}');
      return Success(file);
    } catch (e) {
      AppLogger.e('이미지 선택 실패: $e');
      return Failure('이미지 선택 실패: ${e.toString()}');
    }
  }

  /// 이미지 압축 (파일 크기 최적화)
  Future<Result<File>> compressImage(File file) async {
    try {
      final String targetPath = '${file.path}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        return const Failure('이미지 압축 실패');
      }

      final compressedFile = File(result.path);
      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();
      
      AppLogger.d('이미지 압축 완료: ${originalSize}bytes -> ${compressedSize}bytes');
      
      return Success(compressedFile);
    } catch (e) {
      AppLogger.e('이미지 압축 실패: $e');
      return Failure('이미지 압축 실패: ${e.toString()}');
    }
  }

  /// Firebase Storage에 프로필 이미지 업로드
  Future<Result<String>> uploadProfileImage({
    required String userId,
    required File imageFile,
    bool compress = true,
  }) async {
    try {
      // 압축 옵션이 켜져있으면 이미지 압축
      File uploadFile = imageFile;
      if (compress) {
        final compressResult = await compressImage(imageFile);
        final error = compressResult.errorOrNull;
        if (error != null) {
          return Failure(error);
        }
        uploadFile = (compressResult as Success<File>).data;
      }

      // Firebase Storage 경로 설정
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('profile_images/$userId/$fileName');

      // 업로드 시작
      AppLogger.d('프로필 이미지 업로드 시작: ${storageRef.fullPath}');
      
      final UploadTask uploadTask = storageRef.putFile(
        uploadFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // 업로드 진행 상태 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.d('업로드 진행률: ${progress.toStringAsFixed(2)}%');
      });

      // 업로드 완료 대기
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.d('프로필 이미지 업로드 완료: $downloadUrl');
      
      return Success(downloadUrl);
    } catch (e) {
      AppLogger.e('프로필 이미지 업로드 실패: $e');
      return Failure('이미지 업로드 실패: ${e.toString()}');
    }
  }

  /// 기존 프로필 이미지 삭제
  Future<Result<void>> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebase')) {
        return const Success(null);
      }

      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      AppLogger.d('프로필 이미지 삭제 완료: $imageUrl');
      return const Success(null);
    } catch (e) {
      AppLogger.e('프로필 이미지 삭제 실패: $e');
      // 이미지 삭제 실패는 치명적이지 않으므로 경고만 로그
      return const Success(null);
    }
  }

  /// 프로필 이미지 선택 다이얼로그 표시용 열거형
  static const List<ImageSourceOption> imageSourceOptions = [
    ImageSourceOption(
      label: '카메라로 촬영',
      icon: '📷',
      source: ImageSource.camera,
    ),
    ImageSourceOption(
      label: '갤러리에서 선택',
      icon: '🖼️',
      source: ImageSource.gallery,
    ),
  ];
}

/// 이미지 소스 옵션
class ImageSourceOption {
  final String label;
  final String icon;
  final ImageSource source;

  const ImageSourceOption({
    required this.label,
    required this.icon,
    required this.source,
  });
}
