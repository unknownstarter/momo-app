import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_animation.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/widgets/widgets.dart';

/// OnboardingFormPage -- 7단계 사주 정보 온보딩 폼 (토스 스타일)
///
/// "한 화면에 하나의 질문" 패턴으로 사주 분석에 필요한 기본 정보를 수집한다.
/// 선택형 입력(성별, 시진)은 탭 후 0.3초 자동 진행,
/// 텍스트형 입력(이름)은 조건부 버튼 활성화.
///
/// | Step | 캐릭터 | 내용 | 진행 방식 |
/// |------|--------|------|----------|
/// | 0 | 물결이(水) | 이름 | 버튼 활성화 |
/// | 1 | 물결이(水) | 성별 | 자동 진행 |
/// | 2 | 물결이(水) | 생년월일 | 버튼 활성화 |
/// | 3 | 쇠동이(金) | 생시(시진) | 자동 진행 |
/// | 4 | 흙순이(土) | SMS 인증 | 버튼/자동 |
/// | 5 | 불꼬리(火) | 사진(정면) | 버튼 활성화 |
/// | 6 | 물결이(水) | 확인 요약 | CTA 버튼 |
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
  static const _totalSteps = 7;

  final _pageController = PageController();
  int _currentStep = 0;

  // ---------------------------------------------------------------------------
  // Step 0: 이름
  // ---------------------------------------------------------------------------
  final _nameController = TextEditingController();
  String? _nameError;

  // ---------------------------------------------------------------------------
  // Step 1: 성별
  // ---------------------------------------------------------------------------
  String? _selectedGender;

  // ---------------------------------------------------------------------------
  // Step 2: 생년월일
  // ---------------------------------------------------------------------------
  DateTime? _birthDate;

  // ---------------------------------------------------------------------------
  // Step 3: 생시(시진) 선택
  // ---------------------------------------------------------------------------
  int? _selectedSiJinIndex; // 0~11 (자시~해시), null = 모르겠어요
  bool _siJinIsUnknown = false;

  // ---------------------------------------------------------------------------
  // Step 4: SMS 인증
  // ---------------------------------------------------------------------------
  final _phoneController = TextEditingController();
  bool _smsPhase2 = false; // false=전화번호 입력, true=OTP 입력
  bool _smsSending = false;
  bool _smsVerifying = false;
  bool _smsVerified = false;
  bool _otpError = false;
  Timer? _otpTimer;
  int _otpSecondsLeft = 0;
  final _otpKey = GlobalKey<SajuOtpInputState>();

  // ---------------------------------------------------------------------------
  // Step 5: 사진(정면)
  // ---------------------------------------------------------------------------
  String? _photoPath; // 로컬 파일 경로

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

  /// 시진 index → HH:mm 대표 시각 변환
  static String _siJinToHHmm(int index) {
    const times = [
      '00:00', '02:00', '04:00', '06:00', '08:00', '10:00',
      '12:00', '14:00', '16:00', '18:00', '20:00', '22:00',
    ];
    return times[index];
  }

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
      name: '물결이',
      asset: CharacterAssets.mulgyeoriWaterDefault,
      color: SajuColor.water,
    ),
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
    // Step 4: SMS 인증
    _StepCharacter(
      name: '흙순이',
      asset: CharacterAssets.heuksuniEarthDefault,
      color: SajuColor.earth,
    ),
    _StepCharacter(
      name: '불꼬리',
      asset: CharacterAssets.bulkkoriFireDefault,
      color: SajuColor.fire,
    ),
    _StepCharacter(
      name: '물결이',
      asset: CharacterAssets.mulgyeoriWaterDefault,
      color: SajuColor.water,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpTimer?.cancel();
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

  String _stepName(int step) => const [
        'name',
        'gender',
        'birthdate',
        'birthtime',
        'sms',
        'photo',
        'summary',
      ][step];

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    AnalyticsService.completeOnboardingStep(
      step: _currentStep,
      stepName: _stepName(_currentStep),
    );

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      AnalyticsService.clickStartAnalysisInOnboarding();
      HapticService.medium();
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep == 4 && _smsPhase2) {
      // SMS Phase 2에서 뒤로가면 Phase 1으로
      setState(() {
        _smsPhase2 = false;
        _otpError = false;
        _otpTimer?.cancel();
      });
      return;
    }
    // [FIX: I3] Step 4를 완전히 빠져나갈 때 타이머 정리
    if (_currentStep == 4) {
      _otpTimer?.cancel();
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // 이름
        final name = _nameController.text.trim();
        if (name.length < 2) {
          setState(() => _nameError = '이름은 2자 이상이어야 해요');
          return false;
        }
        setState(() => _nameError = null);
        return true;
      case 1: // 성별 — 자동 진행이므로 선택 여부만
        return _selectedGender != null;
      case 2: // 생년월일
        return _birthDate != null;
      case 3: // 시진 — 모르겠어요 허용이므로 항상 통과
        return true;
      case 4: // SMS — 인증 완료 필수
        return _smsVerified;
      case 5: // 사진 — 선택 필수
        return _photoPath != null;
      case 6: // 확인 — 항상 통과
        return true;
      default:
        return true;
    }
  }

  /// 현재 스텝의 입력이 유효한지 (하단 버튼 활성화 조건)
  bool get _isCurrentStepValid => switch (_currentStep) {
    0 => _nameController.text.trim().length >= 2,
    2 => _birthDate != null,
    4 => _smsVerified, // SMS 인증 완료 필수
    5 => _photoPath != null,
    6 => true,
    _ => true,
  };

  void _submitForm() {
    final formData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birthDate': _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      'birthTime': _selectedSiJinIndex != null
          ? _siJinToHHmm(_selectedSiJinIndex!)
          : null,
      'photoPath': _photoPath,
      'phone': _smsVerified
          ? PhoneUtils.toE164(_phoneController.text)
          : null,
      'isPhoneVerified': _smsVerified,
    };

    widget.onComplete(formData);
  }

  // ---------------------------------------------------------------------------
  // 자동 진행 헬퍼 (선택형 입력)
  // ---------------------------------------------------------------------------

  // [FIX: C3] 호출 시점의 step을 캡처하여 stale advance 방지
  void _autoAdvance() {
    final targetStep = _currentStep + 1;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_currentStep != targetStep - 1) return; // 이미 이동됨
      HapticService.light();
      _goToStep(targetStep);
    });
  }

  // ---------------------------------------------------------------------------
  // SMS 인증 로직
  // ---------------------------------------------------------------------------

  bool get _isPhoneValid =>
      PhoneUtils.isValidKorean(_phoneController.text);

  // [FIX: C4] 동기적으로 플래그 세팅 → 더블탭 방지
  Future<void> _sendSmsCode() async {
    if (!_isPhoneValid || _smsSending) return;
    AnalyticsService.clickSendSmsInOnboarding();
    _smsSending = true; // 동기적 세팅 (async gap 전)
    FocusScope.of(context).unfocus();
    setState(() {});

    try {
      // TODO(PROD): 디버그 바이패스 제거 — Firebase Phone Auth 연동 후 실제 발송
      // [BYPASS-6] SMS 발송 mock
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
          _smsSending = false;
          _smsPhase2 = true;
          _otpError = false;
        });
        _startOtpTimer();
        return;
      }

      // TODO: Firebase Phone Auth — verifyPhoneNumber() → SMS 발송
      // await FirebaseAuth.instance.verifyPhoneNumber(
      //   phoneNumber: PhoneUtils.toE164(_phoneController.text),
      //   verificationCompleted: (credential) { ... },
      //   verificationFailed: (e) { ... },
      //   codeSent: (verificationId, resendToken) { ... },
      //   codeAutoRetrievalTimeout: (verificationId) { ... },
      // );
    } catch (e) {
      if (!mounted) return;
      _showSnack('인증번호 발송에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _smsSending = false);
    }
  }

  // [FIX: I5] _smsVerified 체크 추가 → 인증 성공 후 중복 호출 차단
  Future<void> _verifySmsCode(String code) async {
    if (_smsVerifying || _smsVerified || _otpSecondsLeft <= 0) return;
    setState(() {
      _smsVerifying = true;
      _otpError = false;
    });

    try {
      // TODO(PROD): 디버그 바이패스 제거 — Firebase Phone Auth 연동 후 실제 OTP 검증
      // [BYPASS-7] SMS 인증 검증 mock — 코드 "000000" 또는 아무 6자리 성공
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _otpTimer?.cancel();
        setState(() {
          _smsVerifying = false;
          _smsVerified = true;
        });
        AnalyticsService.completeSmsVerification();
        HapticService.success();
        // 성공 애니메이션 후 자동 진행
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _nextStep();
        return;
      }

      // TODO: Firebase Phone Auth — PhoneAuthCredential로 OTP 검증
      // final credential = PhoneAuthProvider.credential(
      //   verificationId: _verificationId,
      //   smsCode: code,
      // );
      // await FirebaseAuth.instance.signInWithCredential(credential);
      // // 인증 성공 → Supabase profiles에 phone 저장 → Firebase signOut
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _smsVerifying = false;
        _otpError = true;
      });
      _otpKey.currentState?.clear();
    }
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _otpSecondsLeft = 180); // 3분
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _otpSecondsLeft--;
        if (_otpSecondsLeft <= 0) timer.cancel();
      });
    });
  }

  String get _timerDisplay {
    final min = _otpSecondsLeft ~/ 60;
    final sec = _otpSecondsLeft % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
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
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Scaffold를 사용하지 않음 — 부모(OnboardingPage)의 Scaffold가 배경을 담당.
    return ColoredBox(
      color: const Color(0xFFF7F3EE),
      child: SafeArea(
        child: Column(
          children: [
            // --- 상단: 뒤로가기 ---
            _buildTopBar(),
            SajuSpacing.gap8,

            // --- 프로그레스 바 ---
            _buildProgressBar(),
            SajuSpacing.gap16,

            // --- 스텝 콘텐츠 ---
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepName(),
                  _buildStepGender(),
                  _buildStepBirthDate(),
                  _buildStepSiJin(),
                  _buildStepSms(),
                  _buildStepPhoto(),
                  _buildStepConfirm(),
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
  // 상단 바 (뒤로가기 + 스텝 카운터)
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space16,
        vertical: SajuSpacing.space8,
      ),
      child: Row(
        children: [
          if (_currentStep > 0 || (_currentStep == 4 && _smsPhase2))
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 리니어 프로그레스 바
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _totalSteps;
    final currentColor = _stepCharacters[_currentStep].color.resolve(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: SajuAnimation.slow,
          curve: SajuAnimation.entrance,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFFE8E4DF),
            valueColor: AlwaysStoppedAnimation<Color>(currentColor),
            minHeight: 4,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0: 이름 (auto-focus, 버튼 활성화)
  // ---------------------------------------------------------------------------

  Widget _buildStepName() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '물결이',
            message: '반가워요! 이름이 어떻게 돼요~?',
            elementColor: SajuColor.water,
            characterAssetPath: CharacterAssets.mulgyeoriWaterDefault,
            size: SajuSize.md,
          ),
          SajuSpacing.gap32,
          SajuInput(
            label: '이름',
            hint: '이름을 입력해주세요',
            controller: _nameController,
            errorText: _nameError,
            autofocus: true,
            maxLength: 20,
            size: SajuSize.lg,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
              setState(() {}); // 버튼 활성화 갱신
            },
            onSubmitted: (_) {
              if (_isCurrentStepValid) _nextStep();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: 성별 (자동 진행)
  // ---------------------------------------------------------------------------

  Widget _buildStepGender() {
    final name = _nameController.text.trim();
    final displayName = name.isNotEmpty ? '$name님' : '너';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '물결이',
            message: '$displayName 반가워요! 성별도 알려주실래요?',
            elementColor: SajuColor.water,
            characterAssetPath: CharacterAssets.mulgyeoriWaterDefault,
            size: SajuSize.md,
          ),
          const SizedBox(height: SajuSpacing.space48),
          Row(
            children: [
              Expanded(
                child: SajuChip(
                  label: '남성',
                  color: SajuColor.water,
                  isSelected: _selectedGender == '남성',
                  size: SajuSize.lg,
                  onTap: () => _selectGender('남성'),
                ),
              ),
              SajuSpacing.hGap16,
              Expanded(
                child: SajuChip(
                  label: '여성',
                  color: SajuColor.fire,
                  isSelected: _selectedGender == '여성',
                  size: SajuSize.lg,
                  onTap: () => _selectGender('여성'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectGender(String gender) {
    setState(() => _selectedGender = gender);
    HapticService.selection();
    _autoAdvance();
  }

  // ---------------------------------------------------------------------------
  // Step 2: 생년월일 (인라인 피커)
  // ---------------------------------------------------------------------------

  Widget _buildStepBirthDate() {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '물결이',
            message: '태어난 날을 알려주면 사주를 펼쳐볼게요!',
            elementColor: SajuColor.water,
            characterAssetPath: CharacterAssets.mulgyeoriWaterDefault,
            size: SajuSize.md,
          ),
          SajuSpacing.gap24,

          // 선택된 날짜 미리보기
          if (_birthDate != null)
            Center(
              child: AnimatedSwitcher(
                duration: SajuAnimation.normal,
                child: Text(
                  '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일',
                  key: ValueKey(_birthDate),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.waterColor,
                  ),
                ),
              ),
            ),

          SajuSpacing.gap16,

          // 인라인 CupertinoDatePicker
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _birthDate ?? DateTime(2000, 1, 1),
              minimumDate: DateTime(1940, 1, 1),
              maximumDate: DateTime(now.year - 18, now.month, now.day),
              onDateTimeChanged: (date) {
                setState(() => _birthDate = date);
                HapticService.selection();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: 시진 선택 (자동 진행)
  // ---------------------------------------------------------------------------

  Widget _buildStepSiJin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '쇠동이',
            message: '태어난 시간까지 알면 훨씬 정확해져요!\n몰라도 전혀 괜찮아요~',
            elementColor: SajuColor.metal,
            characterAssetPath: CharacterAssets.soedongiMetalDefault,
            size: SajuSize.md,
          ),
          SajuSpacing.gap24,

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
              final isSelected =
                  _selectedSiJinIndex == index && !_siJinIsUnknown;

              return GestureDetector(
                onTap: () => _selectSiJin(index),
                child: AnimatedContainer(
                  duration: SajuAnimation.normal,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.metalColor.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.metalColor
                          : const Color(0xFFE0DCD7),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.metalColor
                                  .withValues(alpha: 0.15),
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
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
          SajuSpacing.gap16,

          // "모르겠어요" 옵션
          Center(
            child: SajuChip(
              label: '모르겠어요',
              color: SajuColor.metal,
              isSelected: _siJinIsUnknown,
              size: SajuSize.md,
              leadingIcon: Icons.help_outline,
              onTap: _selectSiJinUnknown,
            ),
          ),
          SajuSpacing.gap16,

          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(SajuSpacing.space16),
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
                SajuSpacing.hGap8,
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
          SajuSpacing.gap32,
        ],
      ),
    );
  }

  void _selectSiJin(int index) {
    setState(() {
      _selectedSiJinIndex = index;
      _siJinIsUnknown = false;
    });
    HapticService.selection();
    _autoAdvance();
  }

  void _selectSiJinUnknown() {
    setState(() {
      _selectedSiJinIndex = null;
      _siJinIsUnknown = true;
    });
    HapticService.selection();
    _autoAdvance();
  }

  // ===========================================================================
  // Step 4: SMS 인증 (2-Phase)
  // ===========================================================================

  Widget _buildStepSms() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: AnimatedSwitcher(
        duration: SajuAnimation.normal,
        child: _smsVerified
            ? _buildSmsSuccess()
            : _smsPhase2
                ? _buildSmsPhase2()
                : _buildSmsPhase1(),
      ),
    );
  }

  /// Phase 1: 전화번호 입력
  Widget _buildSmsPhase1() {
    return Column(
      key: const ValueKey('sms-phase1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SajuSpacing.gap8,
        SajuCharacterBubble(
          characterName: '흙순이',
          message: '거의 다 왔어요!\n진짜 인연만 만나려면 인증은 필수예요~',
          elementColor: SajuColor.earth,
          characterAssetPath: CharacterAssets.heuksuniEarthDefault,
          size: SajuSize.md,
        ),
        SajuSpacing.gap32,

        SajuInput(
          label: '전화번호',
          hint: '010-0000-0000',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          inputFormatters: [PhoneNumberFormatter()],
          size: SajuSize.lg,
          onChanged: (_) => setState(() {}),
        ),
        SajuSpacing.gap24,

        SajuButton(
          label: _smsSending ? '발송 중...' : '인증번호 받기',
          onPressed: _isPhoneValid && !_smsSending ? _sendSmsCode : null,
          color: SajuColor.earth,
          size: SajuSize.xl,
        ),
        SajuSpacing.gap24,

        // 안내 텍스트
        Container(
          padding: const EdgeInsets.all(SajuSpacing.space16),
          decoration: BoxDecoration(
            color: AppTheme.earthPastel.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppTheme.earthColor.withValues(alpha: 0.7),
              ),
              SajuSpacing.hGap8,
              Expanded(
                child: Text(
                  '매칭된 상대와의 연락을 위해 전화번호 인증이 필요해요. '
                  '인증 외 목적으로 사용되지 않아요.',
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
      ],
    );
  }

  /// Phase 2: OTP 코드 입력
  Widget _buildSmsPhase2() {
    final phone = _phoneController.text;

    return Column(
      key: const ValueKey('sms-phase2'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SajuSpacing.gap8,
        Align(
          alignment: Alignment.centerLeft,
          child: SajuCharacterBubble(
            characterName: '흙순이',
            message: _otpError
                ? '앗, 번호가 맞지 않는 것 같아요.\n다시 한 번 확인해봐요~'
                : '인증번호를 보냈어요!\n빨리 확인해봐요~',
            elementColor: SajuColor.earth,
            characterAssetPath: CharacterAssets.heuksuniEarthDefault,
            size: SajuSize.md,
          ),
        ),
        SajuSpacing.gap24,

        // 전화번호 표시 + 변경 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              phone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            SajuSpacing.hGap8,
            GestureDetector(
              onTap: () {
                setState(() {
                  _smsPhase2 = false;
                  _otpError = false;
                  _otpTimer?.cancel();
                });
              },
              child: Text(
                '변경',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.earthColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.earthColor,
                ),
              ),
            ),
          ],
        ),
        SajuSpacing.gap32,

        // OTP 입력 박스
        SajuOtpInput(
          key: _otpKey,
          color: SajuColor.earth,
          hasError: _otpError,
          onCompleted: _verifySmsCode,
        ),
        SajuSpacing.gap24,

        // 타이머 + 재발송
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_otpSecondsLeft > 0) ...[
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: _otpSecondsLeft < 30
                    ? AppTheme.fireColor
                    : const Color(0xFF6B6B6B),
              ),
              const SizedBox(width: 4),
              Text(
                _timerDisplay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _otpSecondsLeft < 30
                      ? AppTheme.fireColor
                      : const Color(0xFF6B6B6B),
                ),
              ),
              SajuSpacing.hGap16,
            ],
            GestureDetector(
              onTap: _otpSecondsLeft <= 0 ? _sendSmsCode : null,
              child: Text(
                '인증번호 재발송',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _otpSecondsLeft <= 0
                      ? AppTheme.earthColor
                      : const Color(0xFFA0A0A0),
                  decoration: _otpSecondsLeft <= 0
                      ? TextDecoration.underline
                      : null,
                  decorationColor: AppTheme.earthColor,
                ),
              ),
            ),
          ],
        ),

        if (_smsVerifying) ...[
          SajuSpacing.gap24,
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.earthColor,
            ),
          ),
        ],
      ],
    );
  }

  /// 인증 성공 표시
  Widget _buildSmsSuccess() {
    return Column(
      key: const ValueKey('sms-success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SajuSpacing.gap8,
        Align(
          alignment: Alignment.centerLeft,
          child: SajuCharacterBubble(
            characterName: '흙순이',
            message: '완벽해요!\n이제 진짜 인연을 찾을 준비가 됐어요!',
            elementColor: SajuColor.earth,
            characterAssetPath: CharacterAssets.heuksuniEarthDefault,
            size: SajuSize.md,
          ),
        ),
        const SizedBox(height: SajuSpacing.space48),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.earthColor.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: AppTheme.earthColor,
          ),
        ),
        SajuSpacing.gap16,
        Text(
          '전화번호 인증 완료',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.earthColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: 사진(정면) — 이미지 피커
  // ---------------------------------------------------------------------------

  Widget _buildStepPhoto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '불꼬리',
            message: '얼굴에 숨은 동물상이 궁금하지 않아요?\n셀카 한 장이면 충분해요!',
            elementColor: SajuColor.fire,
            characterAssetPath: CharacterAssets.bulkkoriFireDefault,
            size: SajuSize.md,
          ),
          const SizedBox(height: SajuSpacing.space32),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: _photoPath != null
                  ? _buildPhotoPreview()
                  : _buildPhotoPlaceholder(),
            ),
          ),
          if (_photoPath != null) ...[
            const SizedBox(height: SajuSpacing.space16),
            Center(
              child: SajuButton(
                label: '다시 찍기',
                onPressed: _pickPhoto,
                variant: SajuVariant.ghost,
                color: SajuColor.fire,
                size: SajuSize.sm,
              ),
            ),
          ],
          const SizedBox(height: SajuSpacing.space24),
          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(SajuSpacing.space16),
            decoration: BoxDecoration(
              color: AppTheme.firePastel.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.fireColor.withValues(alpha: 0.7),
                ),
                SajuSpacing.hGap8,
                Expanded(
                  child: Text(
                    '정면을 바라본 사진이 가장 정확해요.\nAI가 관상을 분석해 동물상을 알려줄게요!',
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
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppTheme.fireColor.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.fireColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 40,
            color: AppTheme.fireColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '사진 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.fireColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.fireColor.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.fireColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.file(
          File(_photoPath!),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _photoPath = image.path);
      HapticService.selection();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 6: 입력 확인 요약
  // ---------------------------------------------------------------------------

  Widget _buildStepConfirm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SajuSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SajuSpacing.gap8,
          SajuCharacterBubble(
            characterName: '물결이',
            message: '좋아요! 이제 조상님의 지혜를 빌려볼게요~',
            elementColor: SajuColor.water,
            characterAssetPath: CharacterAssets.mulgyeoriWaterDefault,
            size: SajuSize.md,
          ),
          SajuSpacing.gap32,
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(SajuSpacing.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFFE0DCD7)),
      ),
      child: Column(
        children: [
          _summaryRow(Icons.person, '이름', _nameController.text.trim(), 0),
          const Divider(height: 24),
          _summaryRow(Icons.wc, '성별', _selectedGender ?? '', 1),
          const Divider(height: 24),
          _summaryRow(
            Icons.cake,
            '생년월일',
            _birthDate != null
                ? '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일'
                : '',
            2,
          ),
          const Divider(height: 24),
          _summaryRow(
            Icons.access_time,
            '생시',
            _selectedSiJinIndex != null
                ? '${_siJinList[_selectedSiJinIndex!].name} (${_siJinList[_selectedSiJinIndex!].timeRange})'
                : '모르겠어요',
            3,
          ),
          const Divider(height: 24),
          _summaryRow(
            Icons.phone_android,
            '전화번호',
            _smsVerified ? '${_phoneController.text} (인증완료)' : '미인증',
            4,
          ),
          const Divider(height: 24),
          _summaryPhotoRow(),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
    int stepIndex,
  ) {
    return GestureDetector(
      onTap: () => _goToStep(stepIndex),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.waterColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.edit_outlined,
            size: 14,
            color: const Color(0xFFA0A0A0),
          ),
        ],
      ),
    );
  }

  Widget _summaryPhotoRow() {
    return GestureDetector(
      onTap: () => _goToStep(5),
      child: Row(
        children: [
          Icon(Icons.camera_alt, size: 20, color: AppTheme.fireColor),
          const SizedBox(width: 12),
          Text(
            '사진',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const Spacer(),
          if (_photoPath != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.fireColor.withValues(alpha: 0.3),
                ),
              ),
              child: ClipOval(
                child: Image.file(
                  File(_photoPath!),
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Text(
              '미선택',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.edit_outlined,
            size: 14,
            color: const Color(0xFFA0A0A0),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 하단 버튼 — 자동 진행 스텝 & SMS Phase 2에서는 숨김
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons() {
    // 성별(1), 시진(3) 스텝은 자동 진행이므로 하단 버튼 숨김
    final isAutoAdvanceStep = _currentStep == 1 || _currentStep == 3;
    // SMS Phase 2 (OTP 입력)에서는 자동 검증이므로 버튼 숨김
    final isSmsOtpPhase = _currentStep == 4 && _smsPhase2;
    // SMS Phase 1 (전화번호 입력 중, 아직 미인증)에서는 하단 버튼 숨김
    // (인증번호 받기 버튼이 콘텐츠 영역에 있으므로)
    final isSmsPhase1 = _currentStep == 4 && !_smsPhase2 && !_smsVerified;

    if (isAutoAdvanceStep || isSmsOtpPhase || isSmsPhase1) {
      return const SizedBox(height: SajuSpacing.space16);
    }

    final isLastStep = _currentStep == _totalSteps - 1;
    final isValid = _isCurrentStepValid;

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
        label: isLastStep ? '운명 분석하기' : '다음',
        onPressed: isValid ? _nextStep : null,
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
