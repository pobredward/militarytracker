import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// 업로드 진행 상태 Provider
final uploadProgressProvider = StateProvider<double>((ref) => 0.0);

// 업로드 중 상태 Provider
final isUploadingProvider = StateProvider<bool>((ref) => false);




