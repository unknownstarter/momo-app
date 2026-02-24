import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/matching_profile_provider.dart';

/// Phase B 매칭 프로필 완성 온보딩 — 5스텝
///
/// 사주 결과 확인 후, 매칭에 필요한 추가 정보를 수집한다.
///
/// | Step | 캐릭터 | 내용 |
/// |------|--------|------|
/// | 1    | 불꼬리(火) | 프로필 사진 (최소 2장) |
/// | 2    | 흙순이(土) | 키, 직업, 활동 지역 |
/// | 3    | 물결이(水) | 자기소개, MBTI, 관심사 |
/// | 4    | 쇠동이(金) | 음주, 흡연, 연애스타일, 종교 |
/// | 5    | 나무리(木) | 본인인증 (셀카) |
class MatchingProfilePage extends ConsumerStatefulWidget {
  const MatchingProfilePage({super.key});

  @override
  ConsumerState<MatchingProfilePage> createState() =>
      _MatchingProfilePageState();
}

class _MatchingProfilePageState extends ConsumerState<MatchingProfilePage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // -------------------------------------------------------------------------
  // Step 1: 프로필 사진
  // -------------------------------------------------------------------------
  final List<bool> _photoSlots = List.filled(6, false);

  // -------------------------------------------------------------------------
  // Step 2: 기본 정보
  // -------------------------------------------------------------------------
  final _heightController = TextEditingController();
  final _occupationController = TextEditingController();
  String? _selectedLocation;

  static const _locationOptions = [
    '서울 강남/서초',
    '서울 송파/잠실',
    '서울 마포/홍대',
    '서울 종로/중구',
    '서울 영등포/여의도',
    '서울 성동/광진',
    '서울 강서/양천',
    '서울 노원/도봉',
    '서울 기타',
    '경기 성남/분당',
    '경기 수원',
    '경기 용인',
    '경기 고양/일산',
    '경기 기타',
    '인천',
    '부산',
    '대구',
    '대전',
    '광주',
    '기타',
  ];

  // -------------------------------------------------------------------------
  // Step 3: 자기표현
  // -------------------------------------------------------------------------
  final _bioController = TextEditingController();
  final Set<String> _selectedInterests = {};
  final _customInterestController = TextEditingController();
  String? _selectedMbti;

  static const _presetInterests = [
    '여행',
    '음악',
    '영화',
    '운동',
    '독서',
    '요리',
    '사진',
    '게임',
    '반려동물',
    '카페',
    '맛집',
    '전시/공연',
  ];

  static const _mbtiTypes = [
    'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
    'ISTP', 'ISFP', 'INFP', 'INTP',
    'ESTP', 'ESFP', 'ENFP', 'ENTP',
    'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
  ];

  // -------------------------------------------------------------------------
  // Step 4: 라이프스타일
  // -------------------------------------------------------------------------
  DrinkingFrequency? _selectedDrinking;
  SmokingStatus? _selectedSmoking;
  Religion? _selectedReligion;

  // -------------------------------------------------------------------------
  // 스텝 캐릭터 정보
  // -------------------------------------------------------------------------
  static const _stepCharacters = [
    _StepInfo(
      name: '불꼬리',
      asset: 'assets/images/characters/bulkkori_fire_default.png',
      color: SajuColor.fire,
    ),
    _StepInfo(
      name: '흙순이',
      asset: 'assets/images/characters/heuksuni_earth_default.png',
      color: SajuColor.earth,
    ),
    _StepInfo(
      name: '물결이',
      asset: 'assets/images/characters/mulgyeori_water_default.png',
      color: SajuColor.water,
    ),
    _StepInfo(
      name: '쇠동이',
      asset: 'assets/images/characters/soedongi_metal_default.png',
      color: SajuColor.metal,
    ),
    _StepInfo(
      name: '나무리',
      asset: 'assets/images/characters/namuri_wood_default.png',
      color: SajuColor.wood,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // 네비게이션
  // -------------------------------------------------------------------------

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 4) {
      _goToStep(_currentStep + 1);
    } else {
      _submitProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // 사진: 최소 2장
        final photoCount = _photoSlots.where((s) => s).length;
        if (photoCount < 2) {
          _showSnack('프로필 사진을 최소 2장 추가해주세요');
          return false;
        }
        return true;

      case 1: // 기본 정보: 키, 직업, 지역 필수
        final height = int.tryParse(_heightController.text.trim());
        if (height == null || height < 140 || height > 220) {
          _showSnack('키를 올바르게 입력해주세요 (140~220cm)');
          return false;
        }
        if (_occupationController.text.trim().isEmpty) {
          _showSnack('직업을 입력해주세요');
          return false;
        }
        if (_selectedLocation == null) {
          _showSnack('활동 지역을 선택해주세요');
          return false;
        }
        return true;

      case 2: // 자기표현: 자기소개 필수 (20자+), 관심사 3개+
        final bio = _bioController.text.trim();
        if (bio.length < 20) {
          _showSnack('자기소개를 20자 이상 입력해주세요');
          return false;
        }
        if (_selectedInterests.length < 3) {
          _showSnack('관심사를 최소 3개 선택해주세요');
          return false;
        }
        return true;

      case 3: // 라이프스타일: 선택 사항이므로 항상 통과
        return true;

      case 4: // 본인인증: 선택 사항
        return true;

      default:
        return true;
    }
  }

  Future<void> _submitProfile() async {
    // 사진 URL은 실제로는 Storage 업로드 후 URL을 받아야 하지만
    // 현재는 placeholder URL로 처리
    final photoUrls = <String>[];
    for (int i = 0; i < _photoSlots.length; i++) {
      if (_photoSlots[i]) {
        photoUrls.add('https://placeholder.com/profile_$i.jpg');
      }
    }

    final result = await ref
        .read(matchingProfileNotifierProvider.notifier)
        .saveMatchingProfile(
          profileImageUrls: photoUrls,
          height: int.parse(_heightController.text.trim()),
          occupation: _occupationController.text.trim(),
          location: _selectedLocation!,
          bio: _bioController.text.trim(),
          interests: _selectedInterests.toList(),
          mbti: _selectedMbti,
          drinking: _selectedDrinking,
          smoking: _selectedSmoking,
          religion: _selectedReligion,
        );

    if (result != null && mounted) {
      context.go(RoutePaths.home);
    } else if (mounted) {
      _showSnack('프로필 저장에 실패했어요. 다시 시도해주세요.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 프로그레스 퍼센트 계산
  // -------------------------------------------------------------------------

  int get _progressPercent {
    // 사주 완료 = 40%, 각 스텝 +12%
    return 40 + (_currentStep * 12);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            _buildTopBar(theme),
            const SizedBox(height: AppTheme.spacingXs),

            // 프로그레스 바
            _buildProgressBar(theme),
            const SizedBox(height: AppTheme.spacingMd),

            // 스텝 콘텐츠
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Photos(),
                  _buildStep2BasicInfo(),
                  _buildStep3Expression(),
                  _buildStep4Lifestyle(),
                  _buildStep5Verification(),
                ],
              ),
            ),

            // 하단 버튼
            _buildBottomButtons(theme),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 상단 바
  // -------------------------------------------------------------------------

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(
            '프로필 완성하기  ${_currentStep + 1}/5',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const Spacer(),
          // 나중에 하기 (스킵)
          GestureDetector(
            onTap: () => context.go(RoutePaths.home),
            child: Text(
              '나중에',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 프로그레스 바
  // -------------------------------------------------------------------------

  Widget _buildProgressBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '프로필 완성도',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                '$_progressPercent%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _stepCharacters[_currentStep].color.resolve(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressPercent / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _stepCharacters[_currentStep].color.resolve(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Step 1: 프로필 사진
  // =========================================================================

  Widget _buildStep1Photos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          SajuCharacterBubble(
            characterName: '불꼬리',
            message: '첫인상이 중요해!\n멋진 사진 보여줘~',
            elementColor: SajuColor.fire,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 사진 그리드 (6슬롯, 첫 2개 필수)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final isRequired = index < 2;
              final isFilled = _photoSlots[index];

              return GestureDetector(
                onTap: () {
                  // TODO: 실제 이미지 피커 연결
                  setState(() => _photoSlots[index] = !_photoSlots[index]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppTheme.firePastel.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isFilled
                          ? AppTheme.fireColor
                          : const Color(0xFFD0CCC7),
                      width: isFilled ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFilled
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            size: 28,
                            color: isFilled
                                ? AppTheme.fireColor
                                : const Color(0xFFA0A0A0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFilled
                                ? '추가됨'
                                : index == 0
                                    ? '대표 사진'
                                    : index == 1
                                        ? '정면 사진'
                                        : '사진 ${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isFilled
                                  ? AppTheme.fireColor
                                  : const Color(0xFFA0A0A0),
                              fontWeight: isRequired && !isFilled
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // 필수 뱃지
                      if (isRequired && !isFilled)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.fireColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '필수',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.fireColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 팁
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.firePastel.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppTheme.fireColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '얼굴이 잘 보이는 사진이 매칭 확률을 2배 높여요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B6B6B),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  // =========================================================================
  // Step 2: 기본 정보 (키, 직업, 지역)
  // =========================================================================

  Widget _buildStep2BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          SajuCharacterBubble(
            characterName: '흙순이',
            message: '몇 가지만 더 알려줘!\n금방이야~',
            elementColor: SajuColor.earth,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 키
          SajuInput(
            label: '키 (cm)',
            hint: '예: 170',
            controller: _heightController,
            keyboardType: TextInputType.number,
            size: SajuSize.lg,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 직업
          SajuInput(
            label: '직업',
            hint: '예: 마케터, 개발자, 대학생',
            controller: _occupationController,
            size: SajuSize.lg,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 활동 지역
          Text(
            '활동 지역',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locationOptions.map((loc) {
              final isSelected = _selectedLocation == loc;
              return SajuChip(
                label: loc,
                color: SajuColor.earth,
                isSelected: isSelected,
                size: SajuSize.sm,
                onTap: () => setState(() => _selectedLocation = loc),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  // =========================================================================
  // Step 3: 자기표현 (자기소개, MBTI, 관심사)
  // =========================================================================

  Widget _buildStep3Expression() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          SajuCharacterBubble(
            characterName: '물결이',
            message: '어떤 사람인지 궁금해!\n알려줘~',
            elementColor: SajuColor.water,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 자기소개
          SajuInput(
            label: '자기소개',
            hint: '나를 한마디로 표현한다면? (20자 이상)',
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            size: SajuSize.lg,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _bioController,
              builder: (_, value, _) {
                return Text(
                  '${value.text.length}/300',
                  style: TextStyle(
                    fontSize: 12,
                    color: value.text.length > 280
                        ? AppTheme.fireColor
                        : const Color(0xFFA0A0A0),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // MBTI
          Text(
            'MBTI (선택)',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._mbtiTypes.map((mbti) {
                final isSelected = _selectedMbti == mbti;
                return SajuChip(
                  label: mbti,
                  color: SajuColor.water,
                  isSelected: isSelected,
                  size: SajuSize.sm,
                  onTap: () => setState(() {
                    _selectedMbti = _selectedMbti == mbti ? null : mbti;
                  }),
                );
              }),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 관심사 (최소 3개)
          Text(
            '관심사 (3~10개 선택)',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return SajuChip(
                label: interest,
                color: SajuColor.water,
                isSelected: isSelected,
                size: SajuSize.md,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 10) {
                      _selectedInterests.add(interest);
                    } else {
                      _showSnack('관심사는 최대 10개까지 선택 가능해요');
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 커스텀 관심사 추가
          Row(
            children: [
              Expanded(
                child: SajuInput(
                  label: '직접 입력',
                  hint: '관심사를 입력해주세요',
                  controller: _customInterestController,
                  size: SajuSize.md,
                  onSubmitted: (_) => _addCustomInterest(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: SajuButton(
                  label: '추가',
                  onPressed: _addCustomInterest,
                  color: SajuColor.water,
                  size: SajuSize.md,
                  expand: false,
                ),
              ),
            ],
          ),

          // 커스텀 관심사 표시
          if (_selectedInterests
              .where((i) => !_presetInterests.contains(i))
              .isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '내가 추가한 관심사',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedInterests
                  .where((i) => !_presetInterests.contains(i))
                  .map((interest) {
                return SajuChip(
                  label: interest,
                  color: SajuColor.water,
                  isSelected: true,
                  size: SajuSize.sm,
                  onDeleted: () {
                    setState(() => _selectedInterests.remove(interest));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  void _addCustomInterest() {
    final text = _customInterestController.text.trim();
    if (text.isEmpty) return;
    if (_selectedInterests.length >= 10) {
      _showSnack('관심사는 최대 10개까지 선택 가능해요');
      return;
    }
    if (_selectedInterests.contains(text)) {
      _showSnack('이미 추가된 관심사예요');
      return;
    }
    setState(() {
      _selectedInterests.add(text);
      _customInterestController.clear();
    });
  }

  // =========================================================================
  // Step 4: 라이프스타일 (음주, 흡연, 연애스타일, 종교)
  // =========================================================================

  Widget _buildStep4Lifestyle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          SajuCharacterBubble(
            characterName: '쇠동이',
            message: '거의 다 왔어!\n조금만 더~',
            elementColor: SajuColor.metal,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 음주
          Text(
            '음주',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: DrinkingFrequency.values.map((freq) {
              final isSelected = _selectedDrinking == freq;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: freq != DrinkingFrequency.values.last
                        ? AppTheme.spacingSm
                        : 0,
                  ),
                  child: SajuChip(
                    label: freq.label,
                    color: SajuColor.metal,
                    isSelected: isSelected,
                    size: SajuSize.lg,
                    onTap: () => setState(() {
                      _selectedDrinking =
                          _selectedDrinking == freq ? null : freq;
                    }),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 흡연
          Text(
            '흡연',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: SmokingStatus.values.map((status) {
              final isSelected = _selectedSmoking == status;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: status != SmokingStatus.values.last
                        ? AppTheme.spacingSm
                        : 0,
                  ),
                  child: SajuChip(
                    label: status.label,
                    color: SajuColor.metal,
                    isSelected: isSelected,
                    size: SajuSize.lg,
                    onTap: () => setState(() {
                      _selectedSmoking =
                          _selectedSmoking == status ? null : status;
                    }),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 종교
          Text(
            '종교 (선택)',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Religion.values.map((rel) {
              final isSelected = _selectedReligion == rel;
              return SajuChip(
                label: rel.label,
                color: SajuColor.metal,
                isSelected: isSelected,
                size: SajuSize.md,
                onTap: () => setState(() {
                  _selectedReligion = _selectedReligion == rel ? null : rel;
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  // =========================================================================
  // Step 5: 본인인증 (셀카)
  // =========================================================================

  Widget _buildStep5Verification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          SajuCharacterBubble(
            characterName: '나무리',
            message: '마지막 단계야!\n안전한 만남을 위해 부탁해~',
            elementColor: SajuColor.wood,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 셀카 인증 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.woodColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.woodPastel.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: AppTheme.woodColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  '셀카 인증',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildVerificationBenefit(
                  Icons.verified_user,
                  '프로필에 인증 뱃지가 표시돼요',
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildVerificationBenefit(
                  Icons.trending_up,
                  '매칭 확률이 높아져요',
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildVerificationBenefit(
                  Icons.shield_outlined,
                  '안전한 만남을 보장해요',
                ),
                const SizedBox(height: AppTheme.spacingLg),
                SajuButton(
                  label: '셀카 촬영하기',
                  onPressed: () {
                    // TODO: 카메라 연동 후 AI 얼굴 비교
                    _showSnack('셀카 인증 기능은 준비 중이에요!');
                  },
                  color: SajuColor.wood,
                  size: SajuSize.lg,
                  leadingIcon: Icons.camera_alt,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildVerificationBenefit(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.woodColor),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF4A4F54),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 하단 버튼
  // -------------------------------------------------------------------------

  Widget _buildBottomButtons(ThemeData theme) {
    final isLastStep = _currentStep == 4;
    final currentColor = _stepCharacters[_currentStep].color;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SajuButton(
            label: isLastStep ? '프로필 완성!' : '다음',
            onPressed: _nextStep,
            color: currentColor,
            size: SajuSize.xl,
            leadingIcon: isLastStep ? Icons.celebration : null,
          ),
          // Step 4(라이프스타일), Step 5(인증)는 건너뛰기 가능
          if (_currentStep >= 3) ...[
            const SizedBox(height: AppTheme.spacingXs),
            SajuButton(
              label: isLastStep ? '나중에 인증할게요' : '건너뛰기',
              onPressed: () {
                if (isLastStep) {
                  _submitProfile();
                } else {
                  _goToStep(_currentStep + 1);
                }
              },
              variant: SajuVariant.ghost,
              color: SajuColor.primary,
              size: SajuSize.sm,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 헬퍼
// =============================================================================

class _StepInfo {
  const _StepInfo({
    required this.name,
    required this.asset,
    required this.color,
  });

  final String name;
  final String asset;
  final SajuColor color;
}
