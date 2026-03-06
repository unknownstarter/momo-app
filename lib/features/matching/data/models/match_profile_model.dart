/// 매칭 프로필 DTO (Data Transfer Object)
///
/// Supabase JSON ↔ Domain Entity 변환을 담당합니다.
/// Repository에서 raw Map을 MatchProfile로 변환할 때 domain entity를 재수출합니다.
library;

// Domain entity를 data 레이어 내부에서 사용할 수 있도록 재수출
export '../../domain/entities/match_profile.dart';
