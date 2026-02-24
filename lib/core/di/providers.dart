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
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/saju/data/datasources/saju_remote_datasource.dart';
import '../../features/saju/data/repositories/saju_repository_impl.dart';

// --- Domain Layer (인터페이스) ---
import '../../features/auth/domain/repositories/auth_repository.dart';
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
/// 현재는 Mock 구현체를 반환합니다.
/// Supabase 연동 후 실제 구현체로 교체합니다.
@riverpod
MatchingRepository matchingRepository(Ref ref) {
  return MockMatchingRepository();
}

// =============================================================================
// Profile
// =============================================================================

/// Profile Repository Provider
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
}
