import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/matching_profile_provider.dart';

/// 데이팅 프로필 완성 페이지 — 단일 스크롤 폼
///
/// 사주/관상 분석 후 매칭에 필요한 프로필 정보를 수집한다.
///
/// **필수**: 키, 직업, 활동 지역
/// **선택**: 자기소개, 체형, 종교, 관심사, 이상형
///
/// 사진(최소 1장) + 필수 + 선택 정보를 한 화면에서 수집한다.
class MatchingProfilePage extends ConsumerStatefulWidget {
  const MatchingProfilePage({super.key, this.isEditMode = false});
  final bool isEditMode;

  @override
  ConsumerState<MatchingProfilePage> createState() =>
      _MatchingProfilePageState();
}

class _MatchingProfilePageState extends ConsumerState<MatchingProfilePage> {
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  final _picker = ImagePicker();

  // --- 사진 (최대 5장) ---
  // 각 슬롯: 로컬 파일 경로(String) or 이미 업로드된 URL(String)
  final List<String> _photoSlots = [];
  static const _maxPhotos = AppLimits.maxPhotos;
  static const _minPhotos = AppLimits.minPhotos;

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
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadProfileForEdit();
    } else {
      _loadExistingPhotos();
    }
  }

  /// 편집 모드: 기존 프로필 데이터를 한번에 로드 (사진 + 폼 데이터)
  Future<void> _loadProfileForEdit() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      if (profile != null && mounted) {
        setState(() {
          // 사진
          for (final url in profile.profileImageUrls) {
            if (_photoSlots.length < _maxPhotos) {
              _photoSlots.add(url);
            }
          }
          // 폼 데이터
          _heightController.text = profile.height?.toString() ?? '';
          _occupationController.text = profile.occupation ?? '';
          _selectedLocation = profile.location;
          _bioController.text = profile.bio ?? '';
          _selectedBodyType = profile.bodyType;
          _selectedReligion = profile.religion;
          _selectedInterests.addAll(profile.interests);
          _idealTypeController.text = profile.idealType ?? '';
        });
      }
    } catch (_) {
      // 실패해도 빈 상태로 진행
    }
  }

  /// DB에서 기존 사진 로드 (profiles.profile_images)
  Future<void> _loadExistingPhotos() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      if (profile != null && mounted) {
        setState(() {
          for (final url in profile.profileImageUrls) {
            if (_photoSlots.length < _maxPhotos) {
              _photoSlots.add(url);
            }
          }
        });
      }
    } catch (_) {
      // 실패해도 빈 상태로 진행
    }
  }

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
    if (_photoSlots.length < _minPhotos) {
      _showSnack('사진을 최소 $_minPhotos장 이상 등록해주세요 (현재 ${_photoSlots.length}장)');
      return false;
    }
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

    // 슬롯 순서를 유지하면서 로컬 파일만 업로드
    final localPaths = _photoSlots.where((p) => !p.startsWith('http')).toList();

    Map<String, String> localToUrl = {};
    if (localPaths.isNotEmpty) {
      try {
        final repo = ref.read(profileRepositoryProvider);
        final uploaded = await repo.uploadProfileImages(localPaths);
        for (var i = 0; i < localPaths.length; i++) {
          localToUrl[localPaths[i]] = uploaded[i];
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSnack('사진 업로드에 실패했어요. 다시 시도해주세요.');
        }
        return;
      }
    }

    // 원래 슬롯 순서 유지
    final photoUrls = _photoSlots.map((p) {
      return p.startsWith('http') ? p : (localToUrl[p] ?? p);
    }).toList();

    // --- 편집 모드: updateProfile + pop ---
    if (widget.isEditMode) {
      try {
        final repo = ref.read(profileRepositoryProvider);
        await repo.updateProfile({
          'profile_images': photoUrls,
          'height': int.parse(_heightController.text.trim()),
          'occupation': _occupationController.text.trim(),
          'location': _selectedLocation,
          'bio': _bioController.text.trim(),
          'interests': _selectedInterests.toList(),
          'religion': _selectedReligion?.name,
          'body_type': _selectedBodyType?.name,
          'ideal_type': _idealTypeController.text.trim().isNotEmpty
              ? _idealTypeController.text.trim()
              : null,
        });
        if (!mounted) return;
        ref.invalidate(currentUserProfileProvider);
        setState(() => _isSubmitting = false);
        context.pop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showSnack('저장에 실패했어요. 다시 시도해주세요.');
      }
      return;
    }

    // --- 온보딩 모드: 기존 로직 ---
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
                    const SizedBox(height: 20),

                    // 캐릭터 가이드
                    SajuCharacterBubble(
                      characterName: '흙순이',
                      message: '사진과 정보를 채우면\n더 좋은 인연을 만날 수 있어!',
                      elementColor: SajuColor.earth,
                      size: SajuSize.md,
                    ),
                    const SizedBox(height: 28),

                    // ─── 섹션 0: 사진 ───
                    _buildSectionHeader('내 사진', isRequired: true),
                    const SizedBox(height: 6),
                    Text(
                      '최소 $_minPhotos장, 최대 $_maxPhotos장',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA0A0A0),
                      ),
                    ),
                    SajuSpacing.gap16,
                    _buildPhotoGrid(),
                    const SizedBox(height: 40),

                    // ─── 섹션 1: 필수 정보 ───
                    _buildSectionHeader('필수 정보', isRequired: true),
                    const SizedBox(height: 20),
                    _buildRequiredSection(),
                    const SizedBox(height: 40),

                    // ─── 섹션 2: 자기소개 ───
                    _buildSectionHeader('자기소개'),
                    const SizedBox(height: 20),
                    _buildBioSection(),
                    const SizedBox(height: 40),

                    // ─── 섹션 3: 나에 대해 ───
                    _buildSectionHeader('나에 대해'),
                    const SizedBox(height: 20),
                    _buildAboutMeSection(),
                    const SizedBox(height: 40),

                    // ─── 섹션 4: 이상형 ───
                    _buildSectionHeader('이상형'),
                    const SizedBox(height: 20),
                    _buildIdealTypeSection(),
                    const SizedBox(height: 40),

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

  /// 상단 앱바 — 뒤로가기/나중에 없음. 필수 정보 입력 후에만 진행 가능.
  /// 영역 유지로 하단 콘텐츠가 끌려 올라오지 않도록 좌우에 빈 공간 배치.
  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SajuSpacing.space16,
        vertical: SajuSpacing.space8,
      ),
      child: Row(
        children: [
          widget.isEditMode
              ? IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                )
              : const SizedBox(width: 40, height: 40),
          const Spacer(),
          Text(
            widget.isEditMode ? '프로필 편집' : '프로필 완성하기',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40, height: 40),
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
        const SizedBox(height: 28),

        // 직업
        SajuInput(
          label: '직업',
          hint: '예: 마케터, 개발자, 대학생',
          controller: _occupationController,
          size: SajuSize.lg,
        ),
        const SizedBox(height: 28),

        // 활동 지역
        _buildFieldLabel('활동 지역'),
        SajuSpacing.gap12,
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
          maxLength: AppLimits.maxBioLength,
          size: SajuSize.lg,
        ),
        SajuSpacing.gap8,
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _bioController,
            builder: (_, value, _) {
              return Text(
                '${value.text.length}/${AppLimits.maxBioLength}',
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
        SajuSpacing.gap12,
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
        const SizedBox(height: 28),

        // 종교
        _buildFieldLabel('종교'),
        SajuSpacing.gap12,
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
        const SizedBox(height: 28),

        // 관심사
        _buildFieldLabel('관심사/취미'),
        SajuSpacing.gap12,
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
        SajuSpacing.gap16,

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
          SajuSpacing.gap12,
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
        SajuSpacing.gap8,
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
        label: _isSubmitting
            ? '저장 중...'
            : widget.isEditMode
                ? '저장'
                : '프로필 완성!',
        onPressed: _isSubmitting ? null : _submitProfile,
        color: SajuColor.earth,
        size: SajuSize.xl,
        leadingIcon: _isSubmitting ? null : (widget.isEditMode ? Icons.save : Icons.celebration),
      ),
    );
  }

  // =========================================================================
  // 공통 위젯
  // =========================================================================

  // =========================================================================
  // 사진 그리드
  // =========================================================================

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _maxPhotos,
      itemBuilder: (context, index) {
        if (index < _photoSlots.length) {
          return _buildPhotoSlot(index);
        }
        return _buildEmptySlot(index);
      },
    );
  }

  Widget _buildPhotoSlot(int index) {
    final path = _photoSlots[index];
    final isUrl = path.startsWith('http');

    return Stack(
      children: [
        // 사진
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(
            child: isUrl
                ? Image.network(path, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8E0D6),
                      child: const Icon(Icons.broken_image, color: Color(0xFFA0A0A0)),
                    ),
                  )
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        // 대표 사진 뱃지 (첫 번째)
        if (index == 0)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '대표',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // 삭제 버튼
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _photoSlots.removeAt(index));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlot(int index) {
    final isNext = index == _photoSlots.length;

    return GestureDetector(
      onTap: isNext ? _showPhotoSourcePicker : null,
      child: Container(
        decoration: BoxDecoration(
          color: isNext
              ? const Color(0xFFE8E0D6).withValues(alpha: 0.6)
              : const Color(0xFFF0EBE5),
          borderRadius: BorderRadius.circular(12),
          border: isNext
              ? Border.all(
                  color: AppTheme.earthColor.withValues(alpha: 0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: Center(
          child: Icon(
            isNext ? Icons.add_a_photo_outlined : Icons.photo_outlined,
            size: isNext ? 28 : 20,
            color: isNext
                ? AppTheme.earthColor
                : const Color(0xFFC0B8AE),
          ),
        ),
      ),
    );
  }

  void _showPhotoSourcePicker() {
    if (_photoSlots.length >= _maxPhotos) {
      _showSnack('사진은 최대 $_maxPhotos장까지 등록할 수 있어요');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F3EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0C8BE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppTheme.earthColor),
                title: const Text('카메라로 촬영'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppTheme.earthColor),
                title: const Text('앨범에서 선택'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        if (_photoSlots.length < _maxPhotos) {
          _photoSlots.add(image.path);
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('사진을 가져오지 못했어요: $e');
    }
  }

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
