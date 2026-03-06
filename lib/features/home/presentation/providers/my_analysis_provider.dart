/// 내 운명 분석 데이터 Provider
///
/// 홈 화면의 "내 운명 분석" 섹션에서 사용하는 사주/관상 데이터를 로드한다.
/// 사주는 DB에서 직접 조회하고, 관상은 gwansangRepository를 통해 조회한다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gwansang/domain/entities/gwansang_entity.dart';
import '../../../saju/data/models/saju_profile_model.dart';
import '../../../saju/domain/entities/saju_entity.dart';

part 'my_analysis_provider.g.dart';

/// 내 사주 + 관상 데이터를 병렬로 로드하는 Provider
@riverpod
Future<({SajuProfile? saju, GwansangProfile? gwansang})> myAnalysis(
  Ref ref,
) async {
  final userAsync = await ref.watch(currentUserProfileProvider.future);
  if (userAsync == null) {
    return (saju: null, gwansang: null);
  }

  final userId = userAsync.id;
  final helper = ref.watch(supabaseHelperProvider);
  final gwansangRepo = ref.watch(gwansangRepositoryProvider);

  // 사주와 관상을 병렬로 조회
  final results = await Future.wait([
    _fetchSajuProfile(helper, userId),
    gwansangRepo.getGwansangProfile(userId),
  ]);

  final sajuProfile = results[0] as SajuProfile?;
  final gwansangProfile = results[1] as GwansangProfile?;

  return (saju: sajuProfile, gwansang: gwansangProfile);
}

/// Supabase에서 saju_profiles 행을 직접 조회하여 SajuProfile로 변환
Future<SajuProfile?> _fetchSajuProfile(
  SupabaseHelper helper,
  String userId,
) async {
  try {
    final row = await helper.getSingleBy('saju_profiles', 'user_id', userId);
    if (row == null) return null;

    final id = row['id'] as String?;
    final userIdFromRow = row['user_id'] as String?;
    if (id == null || userIdFromRow == null) return null;

    // personality_traits: jsonb 배열
    final rawTraits = row['personality_traits'];
    final personalityTraits = <String>[];
    if (rawTraits is List) {
      for (final t in rawTraits) {
        if (t is String) personalityTraits.add(t);
      }
    }

    // ai_interpretation: text
    final aiInterpretation = row['ai_interpretation'] as String?;

    // pillar/fiveElements 데이터가 없으면 null
    final yearPillar = row['year_pillar'];
    final monthPillar = row['month_pillar'];
    final dayPillar = row['day_pillar'];
    final fiveElements = row['five_elements'];
    final dominantElement = row['dominant_element'];
    if (yearPillar == null ||
        monthPillar == null ||
        dayPillar == null ||
        fiveElements == null) {
      return null;
    }

    // SajuProfileModel.fromJson으로 파싱 후 toEntity
    final model = SajuProfileModel.fromJson({
      'yearPillar': yearPillar,
      'monthPillar': monthPillar,
      'dayPillar': dayPillar,
      'hourPillar': row['hour_pillar'],
      'fiveElements': fiveElements,
      'dominantElement': dominantElement,
      'birthDate': '2000-01-01', // DB에 birthDate 컬럼 없음, 더미값
      'birthTime': null,
      'isLunar': row['is_lunar_calendar'] == true,
    });

    return model.toEntity(
      id: id,
      userId: userIdFromRow,
      personalityTraits: personalityTraits,
      aiInterpretation: aiInterpretation,
    );
  } catch (_) {
    return null;
  }
}
