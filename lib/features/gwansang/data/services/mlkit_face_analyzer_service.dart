/// ML Kit 기반 얼굴 분석 서비스 — 실 기기용 구현체
///
/// Google ML Kit Face Detection을 사용하여 사진에서 얼굴을 감지하고,
/// 관상학 분석에 필요한 17개 측정값을 추출합니다.
/// 모든 측정값은 얼굴 바운딩 박스 기준으로 0~1 범위로 정규화됩니다.
///
/// ⚠️ 이 파일은 실 기기에서만 사용됩니다.
/// iOS 시뮬레이터에서는 MockFaceAnalyzerService가 사용됩니다.
library;

import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../domain/entities/face_measurements.dart';
import '../../domain/services/face_analyzer_service.dart';

// =============================================================================
// MlKitFaceAnalyzerService
// =============================================================================

/// ML Kit 기반 온디바이스 얼굴 분석 서비스
///
/// ML Kit의 Face Detection을 사용하여 사진에서 얼굴 윤곽(contour),
/// 랜드마크(landmark), 분류(classification) 정보를 추출합니다.
/// 추출된 원시 데이터를 관상학 분석에 적합한 정규화된 측정값으로 변환합니다.
///
/// 사용 후 반드시 [dispose]를 호출하여 리소스를 해제해야 합니다.
class MlKitFaceAnalyzerService implements FaceAnalyzerService {
  MlKitFaceAnalyzerService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            enableClassification: true,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  final FaceDetector _detector;

  // ===========================================================================
  // Public API
  // ===========================================================================

  @override
  Future<FaceMeasurements?> analyze(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) return null;

    // 가장 큰 얼굴(메인 피사체)을 선택
    final face = faces.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >=
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b,
    );

    return _computeMeasurements(face);
  }

  @override
  Future<FaceMeasurements?> analyzeMultiple(List<File> images) async {
    final results = <FaceMeasurements>[];

    for (final image in images) {
      final measurement = await analyze(image);
      if (measurement != null) {
        results.add(measurement);
      }
    }

    if (results.isEmpty) return null;
    if (results.length == 1) return results.first;

    return _averageMeasurements(results);
  }

  @override
  Future<bool> validatePhoto(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);
    return faces.isNotEmpty;
  }

  @override
  void dispose() {
    _detector.close();
  }

  // ===========================================================================
  // 내부 계산 메서드
  // ===========================================================================

  FaceMeasurements _computeMeasurements(Face face) {
    final box = face.boundingBox;
    final faceWidth = box.width;
    final faceHeight = box.height;
    final ratio = faceHeight / faceWidth;

    final thirds = _computeThirds(face, faceHeight);
    final eyeMetrics = _computeEyeMetrics(face, faceWidth);
    final noseMetrics = _computeNoseMetrics(face, faceWidth, faceHeight);
    final mouthMetrics = _computeMouthMetrics(face, faceWidth, faceHeight);
    final eyebrowMetrics = _computeEyebrowMetrics(face, faceHeight);
    final jawline = _computeJawlineAngle(face);
    final symmetry = _computeSymmetry(face);
    final faceShape = _classifyFaceShape(ratio, face);

    return FaceMeasurements(
      faceShape: faceShape,
      upperThird: thirds.$1,
      middleThird: thirds.$2,
      lowerThird: thirds.$3,
      eyeSpacing: eyeMetrics.$1,
      eyeSlant: eyeMetrics.$2,
      eyeSize: eyeMetrics.$3,
      noseBridgeHeight: noseMetrics.$1,
      noseWidth: noseMetrics.$2,
      mouthWidth: mouthMetrics.$1,
      lipThickness: mouthMetrics.$2,
      eyebrowArch: eyebrowMetrics.$1,
      eyebrowThickness: eyebrowMetrics.$2,
      foreheadHeight: thirds.$1,
      jawlineAngle: jawline,
      faceSymmetry: symmetry,
      faceLengthRatio: ratio.clamp(0.8, 2.0),
    );
  }

  String _classifyFaceShape(double ratio, Face face) {
    final faceContour = face.contours[FaceContourType.face];

    if (faceContour == null || faceContour.points.length < 10) {
      if (ratio < 1.1) return 'round';
      if (ratio > 1.5) return 'long';
      return 'oval';
    }

    final points = faceContour.points;
    final totalPoints = points.length;

    final upperIdx = totalPoints ~/ 4;
    final lowerIdx = (totalPoints * 3) ~/ 4;

    final upperWidth =
        (points[upperIdx].x - points[totalPoints - upperIdx - 1].x).abs();
    final lowerWidth =
        (points[lowerIdx].x - points[totalPoints - lowerIdx - 1].x).abs();

    final widthRatio =
        upperWidth > 0 ? (lowerWidth / upperWidth).clamp(0.0, 2.0) : 1.0;

    if (ratio < 1.15 && widthRatio > 0.85) return 'round';
    if (ratio > 1.5) return 'long';
    if (widthRatio < 0.7) return 'heart';
    if (widthRatio > 1.1) return 'diamond';
    if (ratio < 1.25 && widthRatio > 0.9) return 'square';
    return 'oval';
  }

  (double, double, double) _computeThirds(Face face, double faceHeight) {
    if (faceHeight <= 0) return (0.33, 0.33, 0.34);

    final box = face.boundingBox;
    final faceTop = box.top;

    final leftEyebrow = face.contours[FaceContourType.leftEyebrowTop];
    final rightEyebrow = face.contours[FaceContourType.rightEyebrowTop];
    final noseBottom = face.contours[FaceContourType.noseBottom];

    double eyebrowY;
    if (leftEyebrow != null &&
        leftEyebrow.points.isNotEmpty &&
        rightEyebrow != null &&
        rightEyebrow.points.isNotEmpty) {
      eyebrowY = (leftEyebrow.points.first.y.toDouble() +
              rightEyebrow.points.first.y.toDouble()) /
          2;
    } else {
      eyebrowY = faceTop + faceHeight * 0.33;
    }

    double noseBottomY;
    if (noseBottom != null && noseBottom.points.isNotEmpty) {
      final midIdx = noseBottom.points.length ~/ 2;
      noseBottomY = noseBottom.points[midIdx].y.toDouble();
    } else {
      noseBottomY = faceTop + faceHeight * 0.66;
    }

    final faceBottom = faceTop + faceHeight;

    final upper = ((eyebrowY - faceTop) / faceHeight).clamp(0.0, 1.0);
    final middle = ((noseBottomY - eyebrowY) / faceHeight).clamp(0.0, 1.0);
    final lower = ((faceBottom - noseBottomY) / faceHeight).clamp(0.0, 1.0);

    final total = upper + middle + lower;
    if (total <= 0) return (0.33, 0.33, 0.34);

    return (upper / total, middle / total, lower / total);
  }

  (double, double, double) _computeEyeMetrics(Face face, double faceWidth) {
    if (faceWidth <= 0) return (0.5, 0.0, 0.5);

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) return (0.5, 0.0, 0.5);

    final leftPos = leftEye.position;
    final rightPos = rightEye.position;

    final spacing =
        ((rightPos.x - leftPos.x).abs() / faceWidth).clamp(0.0, 1.0);

    final dx = (rightPos.x - leftPos.x).toDouble();
    final dy = (rightPos.y - leftPos.y).toDouble();
    final slantRadians = dx != 0 ? atan2(dy, dx) : 0.0;
    final slant = (slantRadians / (pi / 4)).clamp(-1.0, 1.0);

    double eyeSize = 0.5;
    final leftEyeContour = face.contours[FaceContourType.leftEye];
    if (leftEyeContour != null && leftEyeContour.points.length >= 4) {
      final eyePoints = leftEyeContour.points;
      final eyeWidth = eyePoints
              .map((p) => p.x.toDouble())
              .reduce(max) -
          eyePoints.map((p) => p.x.toDouble()).reduce(min);
      eyeSize = (eyeWidth / faceWidth).clamp(0.0, 1.0);
    }

    return (spacing, slant, eyeSize);
  }

  (double, double) _computeNoseMetrics(
    Face face,
    double faceWidth,
    double faceHeight,
  ) {
    if (faceWidth <= 0 || faceHeight <= 0) return (0.5, 0.5);

    double bridgeHeight = 0.5;
    final noseBridge = face.contours[FaceContourType.noseBridge];
    if (noseBridge != null && noseBridge.points.length >= 2) {
      final topY = noseBridge.points.first.y.toDouble();
      final bottomY = noseBridge.points.last.y.toDouble();
      bridgeHeight = ((bottomY - topY).abs() / faceHeight).clamp(0.0, 1.0);
    }

    double noseWidth = 0.5;
    final noseBottom = face.contours[FaceContourType.noseBottom];
    if (noseBottom != null && noseBottom.points.length >= 2) {
      final leftX = noseBottom.points.first.x.toDouble();
      final rightX = noseBottom.points.last.x.toDouble();
      noseWidth = ((rightX - leftX).abs() / faceWidth).clamp(0.0, 1.0);
    }

    return (bridgeHeight, noseWidth);
  }

  (double, double) _computeMouthMetrics(
    Face face,
    double faceWidth,
    double faceHeight,
  ) {
    if (faceWidth <= 0 || faceHeight <= 0) return (0.5, 0.5);

    double mouthWidth = 0.5;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    if (leftMouth != null && rightMouth != null) {
      final width =
          (rightMouth.position.x - leftMouth.position.x).abs().toDouble();
      mouthWidth = (width / faceWidth).clamp(0.0, 1.0);
    }

    double lipThickness = 0.5;
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];
    if (upperLip != null &&
        upperLip.points.isNotEmpty &&
        lowerLip != null &&
        lowerLip.points.isNotEmpty) {
      final upperMidIdx = upperLip.points.length ~/ 2;
      final lowerMidIdx = lowerLip.points.length ~/ 2;
      final upperY = upperLip.points[upperMidIdx].y.toDouble();
      final lowerY = lowerLip.points[lowerMidIdx].y.toDouble();
      lipThickness = ((lowerY - upperY).abs() / faceHeight).clamp(0.0, 1.0);
    }

    return (mouthWidth, lipThickness);
  }

  (double, double) _computeEyebrowMetrics(Face face, double faceHeight) {
    if (faceHeight <= 0) return (0.5, 0.5);

    double arch = 0.5;
    final leftEyebrowTop = face.contours[FaceContourType.leftEyebrowTop];
    if (leftEyebrowTop != null && leftEyebrowTop.points.length >= 3) {
      final points = leftEyebrowTop.points;
      final startY = points.first.y.toDouble();
      final endY = points.last.y.toDouble();
      final baselineY = (startY + endY) / 2;

      final peakY = points.map((p) => p.y.toDouble()).reduce(min);
      final archHeight = (baselineY - peakY).abs();
      arch = (archHeight / faceHeight).clamp(0.0, 1.0);
    }

    double thickness = 0.5;
    final eyebrowTop = face.contours[FaceContourType.leftEyebrowTop];
    final eyebrowBottom = face.contours[FaceContourType.leftEyebrowBottom];
    if (eyebrowTop != null &&
        eyebrowTop.points.isNotEmpty &&
        eyebrowBottom != null &&
        eyebrowBottom.points.isNotEmpty) {
      final topMidIdx = eyebrowTop.points.length ~/ 2;
      final bottomMidIdx = eyebrowBottom.points.length ~/ 2;
      final topY = eyebrowTop.points[topMidIdx].y.toDouble();
      final bottomY = eyebrowBottom.points[bottomMidIdx].y.toDouble();
      thickness = ((bottomY - topY).abs() / faceHeight).clamp(0.0, 1.0);
    }

    return (arch, thickness);
  }

  double _computeJawlineAngle(Face face) {
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null || faceContour.points.length < 10) return 0.5;

    final points = faceContour.points;
    final totalPoints = points.length;

    final chinIdx = totalPoints ~/ 2;
    final leftJawIdx = (totalPoints * 3) ~/ 8;
    final rightJawIdx = (totalPoints * 5) ~/ 8;

    if (chinIdx >= totalPoints ||
        leftJawIdx >= totalPoints ||
        rightJawIdx >= totalPoints) {
      return 0.5;
    }

    final chin = points[chinIdx];
    final leftJaw = points[leftJawIdx];
    final rightJaw = points[rightJawIdx];

    final v1x = leftJaw.x.toDouble() - chin.x.toDouble();
    final v1y = leftJaw.y.toDouble() - chin.y.toDouble();
    final v2x = rightJaw.x.toDouble() - chin.x.toDouble();
    final v2y = rightJaw.y.toDouble() - chin.y.toDouble();

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0.5;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final angle = acos(cosAngle);

    return (angle / pi).clamp(0.0, 1.0);
  }

  double _computeSymmetry(Face face) {
    double totalDiff = 0.0;
    int comparisons = 0;

    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final yDiff =
          (leftEye.position.y - rightEye.position.y).abs().toDouble();
      totalDiff += yDiff / box.height;

      final leftDist = (centerX - leftEye.position.x).abs();
      final rightDist = (rightEye.position.x - centerX).abs();
      if (leftDist + rightDist > 0) {
        totalDiff += (leftDist - rightDist).abs() / (leftDist + rightDist);
      }
      comparisons += 2;
    }

    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    if (leftMouth != null && rightMouth != null) {
      final yDiff =
          (leftMouth.position.y - rightMouth.position.y).abs().toDouble();
      totalDiff += yDiff / box.height;

      final leftDist = (centerX - leftMouth.position.x).abs();
      final rightDist = (rightMouth.position.x - centerX).abs();
      if (leftDist + rightDist > 0) {
        totalDiff += (leftDist - rightDist).abs() / (leftDist + rightDist);
      }
      comparisons += 2;
    }

    if (comparisons == 0) return 0.8;

    final avgDiff = totalDiff / comparisons;
    return (1.0 - avgDiff * 2).clamp(0.0, 1.0);
  }

  FaceMeasurements _averageMeasurements(List<FaceMeasurements> measurements) {
    final n = measurements.length;

    final shapeCounts = <String, int>{};
    for (final m in measurements) {
      shapeCounts[m.faceShape] = (shapeCounts[m.faceShape] ?? 0) + 1;
    }
    final dominantShape = shapeCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    ).key;

    return FaceMeasurements(
      faceShape: dominantShape,
      upperThird: measurements.map((m) => m.upperThird).reduce((a, b) => a + b) / n,
      middleThird: measurements.map((m) => m.middleThird).reduce((a, b) => a + b) / n,
      lowerThird: measurements.map((m) => m.lowerThird).reduce((a, b) => a + b) / n,
      eyeSpacing: measurements.map((m) => m.eyeSpacing).reduce((a, b) => a + b) / n,
      eyeSlant: measurements.map((m) => m.eyeSlant).reduce((a, b) => a + b) / n,
      eyeSize: measurements.map((m) => m.eyeSize).reduce((a, b) => a + b) / n,
      noseBridgeHeight: measurements.map((m) => m.noseBridgeHeight).reduce((a, b) => a + b) / n,
      noseWidth: measurements.map((m) => m.noseWidth).reduce((a, b) => a + b) / n,
      mouthWidth: measurements.map((m) => m.mouthWidth).reduce((a, b) => a + b) / n,
      lipThickness: measurements.map((m) => m.lipThickness).reduce((a, b) => a + b) / n,
      eyebrowArch: measurements.map((m) => m.eyebrowArch).reduce((a, b) => a + b) / n,
      eyebrowThickness: measurements.map((m) => m.eyebrowThickness).reduce((a, b) => a + b) / n,
      foreheadHeight: measurements.map((m) => m.foreheadHeight).reduce((a, b) => a + b) / n,
      jawlineAngle: measurements.map((m) => m.jawlineAngle).reduce((a, b) => a + b) / n,
      faceSymmetry: measurements.map((m) => m.faceSymmetry).reduce((a, b) => a + b) / n,
      faceLengthRatio: measurements.map((m) => m.faceLengthRatio).reduce((a, b) => a + b) / n,
    );
  }
}
