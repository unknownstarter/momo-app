/// 사주 분석 Riverpod Providers
///
/// 사주 분석 상태 관리를 담당합니다.
/// DI(의존성 주입)는 core/di/providers.dart에서 처리합니다.
///
/// Provider 구성:
/// - [SajuAnalysisNotifier]: 사주 분석 상태 관리 (AsyncNotifier)
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/saju_entity.dart';

part 'saju_provider.g.dart';

// =============================================================================
// 사주 분석 결과 (프레젠테이션용)
// =============================================================================

/// 사주 분석 최종 결과
///
/// 도메인 엔티티([SajuProfile])에 프레젠테이션 레이어에서 필요한
/// 캐릭터 정보를 추가한 클래스입니다.
class SajuAnalysisResult {
  const SajuAnalysisResult({
    required this.profile,
    required this.characterName,
    required this.characterAssetPath,
    required this.characterGreeting,
  });

  /// 사주 프로필 (도메인 엔티티)
  final SajuProfile profile;

  /// 배정된 오행이 캐릭터 이름 (예: "나무리")
  final String characterName;

  /// 캐릭터 에셋 경로 (예: "assets/images/characters/namuri_wood_default.png")
  final String characterAssetPath;

  /// 캐릭터 인사말
  final String characterGreeting;

  @override
  String toString() =>
      'SajuAnalysisResult(character: $characterName, element: ${profile.dominantElement})';
}

// =============================================================================
// 캐릭터 매핑
// =============================================================================

/// 오행 → 오행이 캐릭터 매핑 정보
class _CharacterInfo {
  const _CharacterInfo({
    required this.name,
    required this.assetPath,
    required this.defaultGreeting,
  });

  final String name;
  final String assetPath;
  final String defaultGreeting;
}

/// 오행별 캐릭터 매핑 테이블
const _characterMap = <FiveElementType, _CharacterInfo>{
  FiveElementType.wood: _CharacterInfo(
    name: '나무리',
    assetPath: CharacterAssets.namuriWoodDefault,
    defaultGreeting: '안녕! 나는 나무리야. 너의 성장하는 기운이 느껴져!',
  ),
  FiveElementType.fire: _CharacterInfo(
    name: '불꼬리',
    assetPath: CharacterAssets.bulkkoriFireDefault,
    defaultGreeting: '반가워! 나는 불꼬리야. 너의 열정이 활활 타오르고 있어!',
  ),
  FiveElementType.earth: _CharacterInfo(
    name: '흙순이',
    assetPath: CharacterAssets.heuksuniEarthDefault,
    defaultGreeting: '어서와! 나는 흙순이야. 너의 든든한 기운이 좋아!',
  ),
  FiveElementType.metal: _CharacterInfo(
    name: '쇠동이',
    assetPath: CharacterAssets.soedongiMetalDefault,
    defaultGreeting: '안녕! 나는 쇠동이야. 너의 단단한 의지가 느껴져!',
  ),
  FiveElementType.water: _CharacterInfo(
    name: '물결이',
    assetPath: CharacterAssets.mulgyeoriWaterDefault,
    defaultGreeting: '반가워! 나는 물결이야. 너의 깊은 지혜가 느껴져!',
  ),
};

/// 기본 캐릭터 (오행을 판별할 수 없을 때)
const _defaultCharacter = _CharacterInfo(
  name: '나무리',
  assetPath: CharacterAssets.namuriWoodDefault,
  defaultGreeting: '안녕! 나는 나무리야. 함께 너의 사주를 알아보자!',
);

// =============================================================================
// 사주 분석 상태 관리 (AsyncNotifier)
// =============================================================================

/// 사주 분석 상태 관리 Notifier
@riverpod
class SajuAnalysisNotifier extends _$SajuAnalysisNotifier {
  @override
  FutureOr<SajuAnalysisResult?> build() {
    return null;
  }

  /// 사주 분석 실행
  Future<void> analyze({
    required String userId,
    required String birthDate,
    String? birthTime,
    bool isLunar = false,
    String? userName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(sajuRepositoryProvider);

      final profile = await repository.analyzeSaju(
        userId: userId,
        birthDate: birthDate,
        birthTime: birthTime,
        isLunar: isLunar,
        userName: userName,
      );

      final characterInfo = _resolveCharacter(profile.dominantElement);

      return SajuAnalysisResult(
        profile: profile,
        characterName: characterInfo.name,
        characterAssetPath: characterInfo.assetPath,
        characterGreeting: characterInfo.defaultGreeting,
      );
    });
  }

  /// 분석 결과 초기화 (재분석 시)
  void reset() {
    state = const AsyncData(null);
  }

  /// 오행 → 캐릭터 정보 매핑
  _CharacterInfo _resolveCharacter(FiveElementType? element) {
    if (element == null) return _defaultCharacter;
    return _characterMap[element] ?? _defaultCharacter;
  }
}
