import 'package:flutter_riverpod/flutter_riverpod.dart';

// 현재 선택된 네비게이션 인덱스를 관리하는 Provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);
