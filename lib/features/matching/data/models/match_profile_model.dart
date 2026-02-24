/// 매칭 프로필 DTO (Data Transfer Object)
///
/// Supabase JSON ↔ Domain Entity 변환을 담당합니다.
/// 현재는 Mock 데이터를 사용하므로 domain entity를 재수출합니다.
/// Supabase 연동 시 fromJson/toJson 메서드를 추가합니다.
library;

// Domain entity를 data 레이어 내부에서 사용할 수 있도록 재수출
export '../../domain/entities/match_profile.dart';
