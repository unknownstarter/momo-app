import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../providers/matching_profile_provider.dart';

/// 데이팅 프로필 완성 페이지 — 단일 스크롤 폼
///
/// 사주/관상 분석 후 매칭에 필요한 프로필 정보를 수집한다.
///
/// **필수**: 키, 직업, 활동 지역
/// **선택**: 자기소개, 체형, 종교, 관심사, 이상형
///
/// quickMode=true 시 필수 정보만 표시하여 빠르게 완료할 수 있다.
class MatchingProfilePage extends ConsumerStatefulWidget {
  const MatchingProfilePage({
    super.key,
    this.quickMode = false,
    this.gwansangPhotoUrls,
  });

  /// 퀵 모드: 필수 정보(키/직업/지역)만 수집
  final bool quickMode;

  /// 관상 분석에서 넘어온 사진 URL 목록
  final List<String>? gwansangPhotoUrls;

  @override
  ConsumerState<MatchingProfilePage> createState() =>
      _MatchingProfilePageState();
}

class _MatchingProfilePageState extends ConsumerState<MatchingProfilePage> {
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  // --- 필수 정보 ---
  final _heightController = TextEditingController();
  final _occupationController = TextEditingController();
  String? _selectedLocation;

  // --- 자기소개 ---
  final _bioController = TextEditingController();

  // --- 나에 대해 ---
  BodyType? _selectedBodyType;
  Religion? _selectedReligion;
  final Set<String> _selectedInterests = {};
  final _customInterestController = TextEditingController();

  // --- 이상형 ---
  final _idealTypeController = TextEditingController();

  // =========================================================================
  // 상수
  // =========================================================================

  static const _locationOptions = [
    '서울 강남',
    '서울 강북',
    '서울 강서',
    '서울 강동',
    '경기 남부',
    '경기 북부',
    '인천',
    '부산',
    '대구',
    '대전',
    '광주',
    '제주도',
    '경상도',
    '전라도',
    '충청도',
    '강원도',
    '국내 기타',
    '해외',
  ];

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

  @override
  void dispose() {
    _scrollController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _customInterestController.dispose();
    _idealTypeController.dispose();
    super.dispose();
  }

  // =========================================================================
  // Validation & Submit
  // =========================================================================

  bool _validate() {
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
  }

  Future<void> _submitProfile() async {
    if (_isSubmitting || !_validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    // 관상에서 넘어온 사진 or 빈 목록
    final photoUrls = widget.gwansangPhotoUrls ?? [];

    final result = await ref
        .read(matchingProfileNotifierProvider.notifier)
        .saveMatchingProfile(
          profileImageUrls: photoUrls,
          height: int.parse(_heightController.text.trim()),
          occupation: _occupationController.text.trim(),
          location: _selectedLocation!,
          bio: _bioController.text.trim(),
          interests: _selectedInterests.toList(),
          religion: _selectedReligion,
          bodyType: _selectedBodyType,
          idealType: _idealTypeController.text.trim().isNotEmpty
              ? _idealTypeController.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      AnalyticsService.completeMatchingProfile();
      context.go(RoutePaths.postAnalysisMatches);
    } else {
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
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),

            // 스크롤 폼
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: SajuSpacing.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SajuSpacing.gap16,

                    // 캐릭터 가이드
                    SajuCharacterBubble(
                      characterName: '흙순이',
                      message: widget.quickMode
                          ? '간단한 정보만 알려주면\n바로 매칭 시작할 수 있어!'
                          : '프로필을 채우면\n더 좋은 인연을 만날 수 있어!',
                      elementColor: SajuColor.earth,
                      size: SajuSize.md,
                    ),
                    SajuSpacing.gap24,

                    // ─── 섹션 1: 필수 정보 ───
                    _buildSectionHeader('필수 정보', isRequired: true),
                    SajuSpacing.gap16,
                    _buildRequiredSection(),
                    SajuSpacing.gap32,

                    // 퀵 모드가 아닌 경우에만 선택 섹션 표시
                    if (!widget.quickMode) ...[
                      // ─── 섹션 2: 자기소개 ───
                      _buildSectionHeader('자기소개'),
                      SajuSpacing.gap16,
                      _buildBioSection(),
                      SajuSpacing.gap32,

                      // ─── 섹션 3: 나에 대해 ───
                      _buildSectionHeader('나에 대해'),
                      SajuSpacing.gap16,
                      _buildAboutMeSection(),
                      SajuSpacing.gap32,

                      // ─── 섹션 4: 이상형 ───
                      _buildSectionHeader('이상형'),
                      SajuSpacing.gap16,
                      _buildIdealTypeSection(),
                      SajuSpacing.gap32,
                    ],

                    // 하단 여백 (버튼 영역만큼)
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 하단 고정 버튼
            _buildBottomButton(theme),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 상단 바
  // =========================================================================

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space16,
        vertical: SajuSpacing.space8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RoutePaths.home);
              }
            },
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
          ),
          const Spacer(),
          Text(
            '프로필 완성하기',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
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

  // =========================================================================
  // 섹션 헤더
  // =========================================================================

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.earthColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SajuSpacing.hGap8,
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        if (isRequired) ...[
          SajuSpacing.hGap4,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.fireColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '필수',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.fireColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // 필수 정보: 키, 직업, 활동 지역
  // =========================================================================

  Widget _buildRequiredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 키
        SajuInput(
          label: '키 (cm)',
          hint: '예: 170',
          controller: _heightController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          size: SajuSize.lg,
        ),
        SajuSpacing.gap24,

        // 직업
        SajuInput(
          label: '직업',
          hint: '예: 마케터, 개발자, 대학생',
          controller: _occupationController,
          size: SajuSize.lg,
        ),
        SajuSpacing.gap24,

        // 활동 지역
        _buildFieldLabel('활동 지역'),
        SajuSpacing.gap8,
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
      ],
    );
  }

  // =========================================================================
  // 자기소개
  // =========================================================================

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SajuInput(
          label: '나를 소개해주세요',
          hint: '취미, 성격, 하고 싶은 이야기 등 자유롭게 적어주세요',
          controller: _bioController,
          maxLines: 5,
          maxLength: 1000,
          size: SajuSize.lg,
        ),
        SajuSpacing.gap4,
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _bioController,
            builder: (_, value, _) {
              return Text(
                '${value.text.length}/1,000',
                style: TextStyle(
                  fontSize: 12,
                  color: value.text.length > 900
                      ? AppTheme.fireColor
                      : const Color(0xFFA0A0A0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 나에 대해: 체형, 종교, 관심사
  // =========================================================================

  Widget _buildAboutMeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 체형
        _buildFieldLabel('체형'),
        SajuSpacing.gap8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BodyType.values.map((type) {
            final isSelected = _selectedBodyType == type;
            return SajuChip(
              label: type.label,
              color: SajuColor.earth,
              isSelected: isSelected,
              size: SajuSize.md,
              onTap: () => setState(() {
                _selectedBodyType = _selectedBodyType == type ? null : type;
              }),
            );
          }).toList(),
        ),
        SajuSpacing.gap24,

        // 종교
        _buildFieldLabel('종교'),
        SajuSpacing.gap8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Religion.values.map((rel) {
            final isSelected = _selectedReligion == rel;
            return SajuChip(
              label: rel.label,
              color: SajuColor.earth,
              isSelected: isSelected,
              size: SajuSize.md,
              onTap: () => setState(() {
                _selectedReligion = _selectedReligion == rel ? null : rel;
              }),
            );
          }).toList(),
        ),
        SajuSpacing.gap24,

        // 관심사
        _buildFieldLabel('관심사/취미'),
        SajuSpacing.gap8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return SajuChip(
              label: interest,
              color: SajuColor.earth,
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
        SajuSpacing.gap12,

        // 커스텀 관심사
        Row(
          children: [
            Expanded(
              child: SajuInput(
                label: '직접 입력',
                hint: '관심사를 입력해주세요',
                controller: _customInterestController,
                maxLength: 20,
                size: SajuSize.md,
                onSubmitted: (_) => _addCustomInterest(),
              ),
            ),
            SajuSpacing.hGap8,
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: SajuButton(
                label: '추가',
                onPressed: _addCustomInterest,
                color: SajuColor.earth,
                size: SajuSize.md,
                expand: false,
              ),
            ),
          ],
        ),

        // 커스텀 관심사 태그
        if (_selectedInterests
            .where((i) => !_presetInterests.contains(i))
            .isNotEmpty) ...[
          SajuSpacing.gap8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests
                .where((i) => !_presetInterests.contains(i))
                .map((interest) {
              return SajuChip(
                label: interest,
                color: SajuColor.earth,
                isSelected: true,
                size: SajuSize.sm,
                onDeleted: () {
                  setState(() => _selectedInterests.remove(interest));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // 이상형
  // =========================================================================

  Widget _buildIdealTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SajuInput(
          label: '어떤 사람을 만나고 싶나요?',
          hint: '이상형을 자유롭게 적어주세요',
          controller: _idealTypeController,
          maxLines: 3,
          maxLength: 200,
          size: SajuSize.lg,
        ),
        SajuSpacing.gap4,
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _idealTypeController,
            builder: (_, value, _) {
              return Text(
                '${value.text.length}/200',
                style: TextStyle(
                  fontSize: 12,
                  color: value.text.length > 180
                      ? AppTheme.fireColor
                      : const Color(0xFFA0A0A0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 하단 고정 버튼
  // =========================================================================

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SajuSpacing.space24,
        SajuSpacing.space8,
        SajuSpacing.space24,
        SajuSpacing.space16,
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
      child: SajuButton(
        label: _isSubmitting ? '저장 중...' : '프로필 완성!',
        onPressed: _isSubmitting ? null : _submitProfile,
        color: SajuColor.earth,
        size: SajuSize.xl,
        leadingIcon: _isSubmitting ? null : Icons.celebration,
      ),
    );
  }

  // =========================================================================
  // 공통 위젯
  // =========================================================================

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: SajuSize.lg.fontSize * 0.9,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
