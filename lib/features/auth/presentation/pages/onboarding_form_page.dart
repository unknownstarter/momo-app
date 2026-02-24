import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// OnboardingFormPage -- 2단계 사주 정보 온보딩 폼 (Phase A)
///
/// 사주 분석에 필요한 기본 정보만 수집한다.
/// 매칭에 필요한 추가 정보(사진, 자기소개, 키, 직업 등)는
/// 사주 결과 확인 후 Phase B(MatchingProfilePage)에서 수집한다.
///
/// | Step | 캐릭터 | 내용 |
/// |------|--------|------|
/// | 1    | 물결이(水) | 이름, 성별, 생년월일 |
/// | 2    | 쇠동이(金) | 생시(시진) 선택 |
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
      asset: CharacterAssets.mulgyeoriWaterDefault,
      color: SajuColor.water,
    ),
    _StepCharacter(
      name: '쇠동이',
      asset: CharacterAssets.soedongiMetalDefault,
      color: SajuColor.metal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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

    if (_currentStep < 1) {
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
            '${_currentStep + 1} / 2',
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
        children: List.generate(2, (index) {
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
                if (index < 1)
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
  // 하단 버튼
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 1;

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
      child: SajuButton(
        label: isLastStep ? '사주 분석하기' : '다음',
        onPressed: _nextStep,
        color: _stepCharacters[_currentStep].color,
        size: SajuSize.xl,
        leadingIcon: isLastStep ? Icons.auto_awesome : null,
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

