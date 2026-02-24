import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// OnboardingFormPage -- 4단계 캐릭터 가이드 온보딩 폼
///
/// 각 단계마다 오행이 캐릭터가 말풍선으로 안내하며,
/// 사용자 기본 정보를 수집한다.
///
/// | Step | 캐릭터 | 내용 |
/// |------|--------|------|
/// | 1    | 물결이(水) | 이름, 성별, 생년월일 |
/// | 2    | 쇠동이(金) | 생시(시진) 선택 |
/// | 3    | 불꼬리(火) | 프로필 사진 |
/// | 4    | 흙순이(土) | 자기소개, 관심사 |
class OnboardingFormPage extends StatefulWidget {
  const OnboardingFormPage({
    super.key,
    required this.onComplete,
  });

  /// 폼 완료 시 수집된 데이터를 전달하는 콜백
  final void Function(Map<String, dynamic> formData) onComplete;

  @override
  State<OnboardingFormPage> createState() => _OnboardingFormPageState();
}

class _OnboardingFormPageState extends State<OnboardingFormPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // ---------------------------------------------------------------------------
  // Step 1: 이름 / 성별 / 생년월일
  // ---------------------------------------------------------------------------
  final _nameController = TextEditingController();
  String? _nameError;
  String? _selectedGender;
  DateTime? _birthDate;

  // ---------------------------------------------------------------------------
  // Step 2: 생시(시진) 선택
  // ---------------------------------------------------------------------------
  int? _selectedSiJinIndex; // 0~11 (자시~해시), null = 모르겠어요

  // ---------------------------------------------------------------------------
  // Step 3: 프로필 사진
  // ---------------------------------------------------------------------------
  // 사진 슬롯 6개 — 실제 이미지 피커는 추후 구현
  final List<bool> _photoSlots = List.filled(6, false);
  bool _skipPhotos = false;

  // ---------------------------------------------------------------------------
  // Step 4: 자기소개 + 관심사
  // ---------------------------------------------------------------------------
  final _bioController = TextEditingController();
  final Set<String> _selectedInterests = {};
  final _customInterestController = TextEditingController();

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
  ];

  // ---------------------------------------------------------------------------
  // 12시진 데이터
  // ---------------------------------------------------------------------------
  static const _siJinList = [
    _SiJin(name: '자시', hanja: '子時', timeRange: '23:00~01:00'),
    _SiJin(name: '축시', hanja: '丑時', timeRange: '01:00~03:00'),
    _SiJin(name: '인시', hanja: '寅時', timeRange: '03:00~05:00'),
    _SiJin(name: '묘시', hanja: '卯時', timeRange: '05:00~07:00'),
    _SiJin(name: '진시', hanja: '辰時', timeRange: '07:00~09:00'),
    _SiJin(name: '사시', hanja: '巳時', timeRange: '09:00~11:00'),
    _SiJin(name: '오시', hanja: '午時', timeRange: '11:00~13:00'),
    _SiJin(name: '미시', hanja: '未時', timeRange: '13:00~15:00'),
    _SiJin(name: '신시', hanja: '申時', timeRange: '15:00~17:00'),
    _SiJin(name: '유시', hanja: '酉時', timeRange: '17:00~19:00'),
    _SiJin(name: '술시', hanja: '戌時', timeRange: '19:00~21:00'),
    _SiJin(name: '해시', hanja: '亥時', timeRange: '21:00~23:00'),
  ];

  // ---------------------------------------------------------------------------
  // 각 단계의 캐릭터 정보
  // ---------------------------------------------------------------------------
  static const _stepCharacters = [
    _StepCharacter(
      name: '물결이',
      asset: 'assets/images/characters/mulgyeori_water_default.png',
      color: SajuColor.water,
    ),
    _StepCharacter(
      name: '쇠동이',
      asset: 'assets/images/characters/soedongi_metal_default.png',
      color: SajuColor.metal,
    ),
    _StepCharacter(
      name: '불꼬리',
      asset: 'assets/images/characters/bulkkori_fire_default.png',
      color: SajuColor.fire,
    ),
    _StepCharacter(
      name: '흙순이',
      asset: 'assets/images/characters/heuksuni_earth_default.png',
      color: SajuColor.earth,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 네비게이션
  // ---------------------------------------------------------------------------

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

    if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        final name = _nameController.text.trim();
        if (name.length < 2) {
          setState(() => _nameError = '이름은 2자 이상 입력해주세요');
          return false;
        }
        if (_selectedGender == null) {
          _showSnack('성별을 선택해주세요');
          return false;
        }
        if (_birthDate == null) {
          _showSnack('생년월일을 선택해주세요');
          return false;
        }
        setState(() => _nameError = null);
        return true;

      case 1:
        // 시진은 "모르겠어요"도 허용하므로 항상 통과
        return true;

      case 2:
        // 사진도 건너뛸 수 있으므로 항상 통과
        return true;

      case 3:
        // 자기소개는 필수 아님, 관심사도 선택사항
        return true;

      default:
        return true;
    }
  }

  void _submitForm() {
    final formData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birthDate': _birthDate?.toIso8601String(),
      'birthHour': _selectedSiJinIndex != null
          ? _siJinList[_selectedSiJinIndex!].name
          : null,
      'hasPhotos': _photoSlots.any((slot) => slot),
      'bio': _bioController.text.trim(),
      'interests': _selectedInterests.toList(),
    };

    widget.onComplete(formData);
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

  // ---------------------------------------------------------------------------
  // 생년월일 피커
  // ---------------------------------------------------------------------------

  Future<void> _showBirthDatePicker() async {
    final now = DateTime.now();

    // iOS 스타일 date picker를 바텀시트로 표시
    DateTime tempDate = _birthDate ?? DateTime(2000, 1, 1);

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    Text(
                      '생년월일',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _birthDate = tempDate);
                        Navigator.pop(ctx);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 날짜 피커
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: DateTime(1940, 1, 1),
                  maximumDate: DateTime(now.year - 18, now.month, now.day),
                  onDateTimeChanged: (date) => tempDate = date,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          children: [
            // --- 상단: 뒤로가기 + 프로그레스 바 ---
            _buildTopBar(),
            const SizedBox(height: AppTheme.spacingSm),

            // --- 캐릭터 프로그레스 인디케이터 ---
            _buildCharacterProgress(),
            const SizedBox(height: AppTheme.spacingMd),

            // --- 스텝 콘텐츠 ---
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),

            // --- 하단 버튼 ---
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 상단 바 (뒤로가기 + 스텝 표시)
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF4A4F54),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(
            '${_currentStep + 1} / 4',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B6B6B),
                ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 캐릭터 프로그레스 인디케이터
  // ---------------------------------------------------------------------------

  Widget _buildCharacterProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Row(
        children: List.generate(4, (index) {
          final character = _stepCharacters[index];
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final color = character.color.resolve(context);
          final pastel = character.color.resolvePastel(context);

          return Expanded(
            child: Row(
              children: [
                // 캐릭터 아이콘
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent ? pastel : const Color(0xFFE8E4DF),
                    border: Border.all(
                      color: isCurrent
                          ? color
                          : isCompleted
                              ? color.withValues(alpha: 0.5)
                              : const Color(0xFFD0CCC7),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 18, color: color)
                        : Image.asset(
                            character.asset,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Text(
                              character.name.characters.first,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? color
                                    : const Color(0xFFA0A0A0),
                              ),
                            ),
                          ),
                  ),
                ),
                // 연결선 (마지막 아이템 제외)
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: isCompleted
                            ? color.withValues(alpha: 0.4)
                            : const Color(0xFFE0DCD7),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: 이름 / 성별 / 생년월일
  // ---------------------------------------------------------------------------

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          // 캐릭터 가이드 말풍선
          SajuCharacterBubble(
            characterName: '물결이',
            message: '먼저 너에 대해 알려줘!',
            elementColor: SajuColor.water,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 이름 입력
          SajuInput(
            label: '이름',
            hint: '이름을 입력해주세요',
            controller: _nameController,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
            maxLength: 20,
            size: SajuSize.lg,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 성별 선택
          Text(
            '성별',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: SajuChip(
                  label: '남성',
                  color: SajuColor.water,
                  isSelected: _selectedGender == '남성',
                  size: SajuSize.lg,
                  onTap: () => setState(() => _selectedGender = '남성'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: SajuChip(
                  label: '여성',
                  color: SajuColor.fire,
                  isSelected: _selectedGender == '여성',
                  size: SajuSize.lg,
                  onTap: () => setState(() => _selectedGender = '여성'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 생년월일
          Text(
            '생년월일',
            style: TextStyle(
              fontSize: SajuSize.lg.fontSize * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GestureDetector(
            onTap: _showBirthDatePicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDE8),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: _birthDate != null
                    ? Border.all(
                        color: AppTheme.waterColor.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _birthDate != null
                          ? '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일'
                          : '생년월일을 선택해주세요',
                      style: TextStyle(
                        fontSize: 15,
                        color: _birthDate != null
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFA0A0A0),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: _birthDate != null
                        ? AppTheme.waterColor
                        : const Color(0xFFA0A0A0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: 생시(시진) 선택
  // ---------------------------------------------------------------------------

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          // 캐릭터 가이드 말풍선
          SajuCharacterBubble(
            characterName: '쇠동이',
            message: '태어난 시간까지 알면 더 정확해져!\n몰라도 괜찮아~',
            elementColor: SajuColor.metal,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 12시진 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: _siJinList.length,
            itemBuilder: (context, index) {
              final siJin = _siJinList[index];
              final isSelected = _selectedSiJinIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSiJinIndex =
                        _selectedSiJinIndex == index ? null : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.metalColor.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.metalColor
                          : const Color(0xFFE0DCD7),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.metalColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${siJin.name} ${siJin.hanja}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.metalColor
                              : const Color(0xFF4A4F54),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        siJin.timeRange,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? AppTheme.metalColor.withValues(alpha: 0.7)
                              : const Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // "모르겠어요" 옵션
          Center(
            child: SajuChip(
              label: '모르겠어요',
              color: SajuColor.metal,
              isSelected: _selectedSiJinIndex == null,
              size: SajuSize.md,
              leadingIcon: Icons.help_outline,
              onTap: () {
                setState(() => _selectedSiJinIndex = null);
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.metalPastel.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.metalColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '태어난 시간을 모르면 일주(日柱) 기반으로 분석해요.\n나중에 수정할 수 있어요!',
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

  // ---------------------------------------------------------------------------
  // Step 3: 프로필 사진
  // ---------------------------------------------------------------------------

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          // 캐릭터 가이드 말풍선
          SajuCharacterBubble(
            characterName: '불꼬리',
            message: '멋진 사진 보여줘!\n인연이 기다리고 있어~',
            elementColor: SajuColor.fire,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 사진 그리드 (6슬롯)
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
              final isFirst = index == 0;

              return GestureDetector(
                onTap: () {
                  // TODO: 이미지 피커 연결
                  setState(() {
                    _photoSlots[index] = !_photoSlots[index];
                    if (_photoSlots[index]) _skipPhotos = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _photoSlots[index]
                        ? AppTheme.firePastel.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _photoSlots[index]
                          ? AppTheme.fireColor
                          : const Color(0xFFD0CCC7),
                      width: _photoSlots[index] ? 2 : 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 빈 슬롯 — 점선 + 아이콘
                      if (!_photoSlots[index])
                        CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: _DashedBorderPainter(
                            color: const Color(0xFFD0CCC7),
                            radius: AppTheme.radiusMd,
                          ),
                        ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photoSlots[index]
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            size: 28,
                            color: _photoSlots[index]
                                ? AppTheme.fireColor
                                : const Color(0xFFA0A0A0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _photoSlots[index]
                                ? '추가됨'
                                : isFirst
                                    ? '대표 사진'
                                    : '사진 ${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _photoSlots[index]
                                  ? AppTheme.fireColor
                                  : const Color(0xFFA0A0A0),
                              fontWeight: isFirst && !_photoSlots[index]
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // "필수" 뱃지 (첫 번째 슬롯)
                      if (isFirst && !_photoSlots[index])
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
          const SizedBox(height: AppTheme.spacingLg),

          // "나중에 추가할게요" 옵션
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _skipPhotos = true;
                  for (int i = 0; i < _photoSlots.length; i++) {
                    _photoSlots[i] = false;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: _skipPhotos
                        ? AppTheme.fireColor.withValues(alpha: 0.5)
                        : const Color(0xFFD0CCC7),
                  ),
                  color: _skipPhotos
                      ? AppTheme.firePastel.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                child: Text(
                  '사진은 나중에 추가할게요',
                  style: TextStyle(
                    fontSize: 13,
                    color: _skipPhotos
                        ? AppTheme.fireColor
                        : const Color(0xFF6B6B6B),
                    fontWeight: _skipPhotos ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: 자기소개 + 관심사
  // ---------------------------------------------------------------------------

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSm),

          // 캐릭터 가이드 말풍선
          SajuCharacterBubble(
            characterName: '흙순이',
            message: '어떤 사람인지 한마디로!',
            elementColor: SajuColor.earth,
            size: SajuSize.md,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 자기소개
          SajuInput(
            label: '자기소개',
            hint: '나를 한마디로 표현한다면?',
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

          // 관심사
          Text(
            '관심사',
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
                  color: SajuColor.earth,
                  size: SajuSize.md,
                  expand: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // 선택된 관심사 표시 (커스텀 포함)
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

  // ---------------------------------------------------------------------------
  // 하단 버튼
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 3;

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
            label: isLastStep ? '완료! 사주 보러가기' : '다음',
            onPressed: _nextStep,
            color: _stepCharacters[_currentStep].color,
            size: SajuSize.xl,
            leadingIcon: isLastStep ? Icons.auto_awesome : null,
          ),
          if (_currentStep == 2 || _currentStep == 3) ...[
            const SizedBox(height: AppTheme.spacingXs),
            SajuButton(
              label: _currentStep == 2 ? '나중에 할게요' : '건너뛰기',
              onPressed: () {
                if (_currentStep == 2) {
                  setState(() => _skipPhotos = true);
                }
                _nextStep();
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
// 헬퍼 모델
// =============================================================================

/// 12시진 데이터 모델
class _SiJin {
  const _SiJin({
    required this.name,
    required this.hanja,
    required this.timeRange,
  });

  final String name;
  final String hanja;
  final String timeRange;
}

/// 스텝별 캐릭터 정보
class _StepCharacter {
  const _StepCharacter({
    required this.name,
    required this.asset,
    required this.color,
  });

  final String name;
  final String asset;
  final SajuColor color;
}

// =============================================================================
// 사진 슬롯 점선 테두리 페인터
// =============================================================================

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    // 단순화된 점선: path의 dash 효과
    final path = Path()..addRRect(rect);
    final dashWidth = 6.0;
    final dashSpace = 4.0;

    final metric = path.computeMetrics().first;
    var distance = 0.0;

    while (distance < metric.length) {
      final end = distance + dashWidth;
      final extractPath = metric.extractPath(
        distance,
        end > metric.length ? metric.length : end,
      );
      canvas.drawPath(extractPath, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) {
    return old.color != color || old.radius != radius;
  }
}
