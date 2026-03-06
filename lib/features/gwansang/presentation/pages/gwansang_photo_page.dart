/// 관상 사진 업로드 페이지 — 정면 얼굴 사진 1장 촬영/선택
///
/// 온보딩과 동일하게 정면 1장으로 관상 분석.
/// image_picker로 카메라/갤러리 선택, 서버 사이드 Claude Vision으로 분석.
/// 다크 테마(미스틱 모드).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens/saju_colors.dart';
import '../../../../core/theme/tokens/saju_spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// 사진 단계 가이드 데이터
class _PhotoGuide {
  const _PhotoGuide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

const _photoGuide = _PhotoGuide(
  title: '정면 사진',
  description: '이목구비를 정확하게 분석할 수 있어요',
  icon: Icons.face,
);

/// 관상 사진 업로드 페이지
class GwansangPhotoPage extends ConsumerStatefulWidget {
  const GwansangPhotoPage({super.key, this.sajuResult});

  /// 사주 분석 결과 (GoRouter extra)
  final dynamic sajuResult;

  @override
  ConsumerState<GwansangPhotoPage> createState() => _GwansangPhotoPageState();
}

class _GwansangPhotoPageState extends ConsumerState<GwansangPhotoPage> {
  final _picker = ImagePicker();
  String? _photoPath;

  bool get _allPhotosReady => _photoPath != null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.sajuColors;

          return Scaffold(
            backgroundColor: colors.bgPrimary,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_ios_new,
                    color: colors.textPrimary, size: 20),
              ),
              title: Text(
                '관상 사진 촬영',
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: SajuSpacing.page,
                child: Column(
                  children: [
                    SajuSpacing.gap16,

                    // 현재 단계 가이드
                    _buildCurrentGuide(context, colors),

                    SajuSpacing.gap24,

                    // 사진 슬롯들
                    Expanded(
                      child: _buildPhotoSlots(context, colors),
                    ),

                    SajuSpacing.gap16,

                    // Progress dots
                    _buildProgressDots(colors),

                    SajuSpacing.gap24,

                    // CTA 버튼
                    if (_allPhotosReady)
                      SajuButton(
                        label: '관상 분석 시작',
                        onPressed: _onStartAnalysis,
                        variant: SajuVariant.filled,
                        color: SajuColor.primary,
                        size: SajuSize.lg,
                        leadingIcon: Icons.auto_awesome,
                      )
                    else
                      SajuButton(
                        label: '사진을 선택해주세요',
                        onPressed: null,
                        variant: SajuVariant.filled,
                        color: SajuColor.primary,
                        size: SajuSize.lg,
                      ),

                    SajuSpacing.gap16,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 정면 사진 가이드 헤더
  Widget _buildCurrentGuide(BuildContext context, SajuColors colors) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.mysticGlow.withValues(alpha: 0.12),
          ),
          child: Icon(_photoGuide.icon, size: 28, color: AppTheme.mysticGlow),
        ),
        SajuSpacing.gap12,
        Text(
          _photoGuide.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SajuSpacing.gap4,
        Text(
          _photoGuide.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// 정면 사진 1장 슬롯
  Widget _buildPhotoSlots(BuildContext context, SajuColors colors) {
    final isFilled = _photoPath != null;

    return Center(
      child: GestureDetector(
        onTap: () {
          if (isFilled) {
            _showPhotoSourceSheet(0);
          } else {
            _showPhotoSourceSheet(0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 200,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            color: isFilled
                ? null
                : colors.bgElevated.withValues(alpha: 0.5),
            border: Border.all(
              color: isFilled
                  ? AppTheme.statusSuccess.withValues(alpha: 0.5)
                  : AppTheme.mysticGlow,
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            image: isFilled
                ? DecorationImage(
                    image: FileImage(File(_photoPath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: isFilled
              ? _buildPhotoOverlay(0, true, colors)
              : _buildEmptySlot(0, true, colors),
        ),
      ),
    );
  }

  /// 빈 사진 슬롯
  Widget _buildEmptySlot(int index, bool isActive, SajuColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isActive ? Icons.add_a_photo_outlined : Icons.photo_outlined,
          size: isActive ? 32 : 20,
          color: isActive ? AppTheme.mysticGlow : colors.textTertiary,
        ),
        if (isActive) ...[
          SajuSpacing.gap8,
          GestureDetector(
            onTap: () => _showPhotoSourceSheet(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.mysticGlow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '사진 선택',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mysticGlow,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 사진이 있는 슬롯의 오버레이
  Widget _buildPhotoOverlay(int index, bool isActive, SajuColors colors) {
    return Stack(
      children: [
        // 완료 체크 표시
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.statusSuccess,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        ),
        // 재촬영 버튼 (활성 슬롯일 때만)
        if (isActive)
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _showPhotoSourceSheet(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text(
                    '다시 찍기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 프로그레스 도트 (1장이므로 단일 표시)
  Widget _buildProgressDots(SajuColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _photoPath != null
                ? AppTheme.statusSuccess
                : AppTheme.mysticGlow,
          ),
        ),
      ],
    );
  }

  /// 카메라/갤러리 선택 바텀시트
  void _showPhotoSourceSheet(int index) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Theme(
          data: AppTheme.dark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.camera_alt, color: AppTheme.mysticGlow),
                    title: const Text('카메라로 촬영'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickPhoto(index, ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library,
                        color: AppTheme.mysticGlow),
                    title: const Text('앨범에서 선택'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickPhoto(index, ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 사진 선택
  Future<void> _pickPhoto(int index, ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _photoPath = image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진을 가져오지 못했어요: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 관상 분석 시작 — 사진을 Storage에 업로드 후 URL로 전달
  Future<void> _onStartAnalysis() async {
    if (_photoPath == null) return;
    final validPaths = [_photoPath!];

    // Storage에 업로드 → profiles.profile_images에 저장
    try {
      final repo = ref.read(profileRepositoryProvider);
      final urls = await repo.uploadProfileImages(validPaths);
      if (urls.isNotEmpty) {
        await repo.updateProfile({'profile_images': urls});
      }

      if (!mounted) return;
      context.go(
        RoutePaths.gwansangAnalysis,
        extra: <String, dynamic>{
          'photoUrls': urls,
          'sajuResult': widget.sajuResult,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진 업로드에 실패했어요. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
