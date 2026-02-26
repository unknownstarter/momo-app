/// Mock 얼굴 분석 서비스 — 시뮬레이터/테스트용 구현체
///
/// iOS 시뮬레이터에서는 Google ML Kit이 동작하지 않으므로,
/// 개발/테스트 시 사실적인 Mock 데이터를 반환합니다.
///
/// 실 기기에서는 MlKitFaceAnalyzerService가 사용됩니다.
library;

import 'dart:io';
import 'dart:math';

import '../../domain/entities/face_measurements.dart';
import '../../domain/services/face_analyzer_service.dart';

class MockFaceAnalyzerService implements FaceAnalyzerService {
  final _random = Random(42); // 고정 시드로 재현 가능한 결과

  @override
  Future<FaceMeasurements?> analyze(File imageFile) async {
    // 실제 분석처럼 약간의 지연 시뮬레이션
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return _generateRealisticMeasurements();
  }

  @override
  Future<FaceMeasurements?> analyzeMultiple(List<File> images) async {
    await Future<void>.delayed(
      Duration(milliseconds: 200 * images.length),
    );

    return _generateRealisticMeasurements();
  }

  @override
  Future<bool> validatePhoto(File imageFile) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return true; // Mock에서는 항상 유효
  }

  @override
  void dispose() {
    // Mock이므로 리소스 해제 불필요
  }

  /// 사실적인 한국인 평균 얼굴 측정값 생성
  FaceMeasurements _generateRealisticMeasurements() {
    final shapes = ['oval', 'round', 'heart', 'square', 'long', 'diamond'];

    return FaceMeasurements(
      faceShape: shapes[_random.nextInt(shapes.length)],
      upperThird: _randomInRange(0.30, 0.36),
      middleThird: _randomInRange(0.31, 0.36),
      lowerThird: _randomInRange(0.30, 0.36),
      eyeSpacing: _randomInRange(0.28, 0.38),
      eyeSlant: _randomInRange(-0.15, 0.15),
      eyeSize: _randomInRange(0.10, 0.18),
      noseBridgeHeight: _randomInRange(0.12, 0.22),
      noseWidth: _randomInRange(0.22, 0.35),
      mouthWidth: _randomInRange(0.30, 0.45),
      lipThickness: _randomInRange(0.04, 0.10),
      eyebrowArch: _randomInRange(0.01, 0.05),
      eyebrowThickness: _randomInRange(0.02, 0.06),
      foreheadHeight: _randomInRange(0.30, 0.36),
      jawlineAngle: _randomInRange(0.35, 0.65),
      faceSymmetry: _randomInRange(0.82, 0.96),
      faceLengthRatio: _randomInRange(1.15, 1.45),
    );
  }

  double _randomInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
