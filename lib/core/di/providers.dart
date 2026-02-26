/// 중앙 DI(의존성 주입) 레이어
///
/// 모든 Repository와 Datasource 인스턴스화를 이곳에서 관리합니다.
/// Presentation 레이어는 이 파일의 Provider만 참조하여
/// data 레이어에 직접 의존하지 않습니다.
///
/// 의존성 흐름:
/// presentation → core/di → data → domain
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// --- Data Layer (구현체) ---
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/mock_chat_repository.dart';
import '../../features/gwansang/data/datasources/gwansang_remote_datasource.dart';
import '../../features/gwansang/data/repositories/gwansang_repository_impl.dart';
import '../../features/gwansang/data/services/mlkit_face_analyzer_service.dart';
import '../../features/gwansang/data/services/mock_face_analyzer_service.dart';
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/saju/data/datasources/saju_remote_datasource.dart';
import '../../features/saju/data/repositories/saju_repository_impl.dart';

// --- Domain Layer (인터페이스) ---
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/gwansang/domain/repositories/gwansang_repository.dart';
import '../../features/gwansang/domain/services/face_analyzer_service.dart';
import '../../features/matching/domain/repositories/matching_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/saju/domain/repositories/saju_repository.dart';

// --- Core ---
import '../network/supabase_client.dart';

part 'providers.g.dart';

// =============================================================================
// Auth
// =============================================================================

/// Auth 데이터소스 Provider
@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) {
  return AuthRemoteDatasource(ref.watch(supabaseClientProvider));
}

/// Auth Repository Provider
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
}

// =============================================================================
// Saju
// =============================================================================

/// 사주 데이터소스 Provider
@riverpod
SajuRemoteDatasource sajuRemoteDatasource(Ref ref) {
  return SajuRemoteDatasource(ref.watch(supabaseHelperProvider));
}

/// 사주 Repository Provider
@riverpod
SajuRepository sajuRepository(Ref ref) {
  return SajuRepositoryImpl(ref.watch(sajuRemoteDatasourceProvider));
}

// =============================================================================
// Matching
// =============================================================================

/// 매칭 Repository Provider
///
/// Phase 1: 실궁합(calculate-compatibility) 연동 구현체 사용.
/// 추천/좋아요는 Mock 유지. 테스트 시 Mock으로 교체 가능.
@riverpod
MatchingRepository matchingRepository(Ref ref) {
  return MatchingRepositoryImpl(
    authRepository: ref.watch(authRepositoryProvider),
    sajuRepository: ref.watch(sajuRepositoryProvider),
    supabaseHelper: ref.watch(supabaseHelperProvider),
  );
}

// =============================================================================
// Profile
// =============================================================================

/// Profile Repository Provider
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
}

// =============================================================================
// Chat
// =============================================================================

/// Chat 데이터소스 Provider
@riverpod
ChatRemoteDatasource chatRemoteDatasource(Ref ref) {
  return ChatRemoteDatasource(ref.watch(supabaseClientProvider));
}

/// Chat Repository Provider
///
/// 현재는 Mock 구현체를 반환합니다.
/// Supabase 연동 후 ChatRepositoryImpl로 교체합니다.
@riverpod
ChatRepository chatRepository(Ref ref) {
  return MockChatRepository();
  // TODO: Supabase 연동 시 아래로 교체
  // return ChatRepositoryImpl(ref.watch(chatRemoteDatasourceProvider));
}

// =============================================================================
// Gwansang (관상)
// =============================================================================

/// 관상 데이터소스 Provider
@riverpod
GwansangRemoteDatasource gwansangRemoteDatasource(Ref ref) {
  return GwansangRemoteDatasource(ref.watch(supabaseHelperProvider));
}

/// 관상 Repository Provider
@riverpod
GwansangRepository gwansangRepository(Ref ref) {
  return GwansangRepositoryImpl(ref.watch(gwansangRemoteDatasourceProvider));
}

/// 얼굴 분석 서비스 Provider
///
/// 실 기기: MlKitFaceAnalyzerService (Google ML Kit 온디바이스 분석)
/// 시뮬레이터: MockFaceAnalyzerService (개발/테스트용 Mock 데이터)
///
/// iOS 시뮬레이터에서는 ML Kit 네이티브 라이브러리가 동작하지 않으므로
/// 자동으로 Mock 구현체를 사용합니다.
@riverpod
FaceAnalyzerService faceAnalyzerService(Ref ref) {
  // 시뮬레이터 감지: 실 기기는 physical device이므로 isPhysicalDevice로 판별
  // 런타임에 ML Kit 초기화를 시도하고, 실패 시 Mock으로 fallback
  try {
    return MlKitFaceAnalyzerService();
  } catch (_) {
    return MockFaceAnalyzerService();
  }
}
