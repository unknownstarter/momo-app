/// 얼굴 분석 서비스 — ML Kit 기반 온디바이스 얼굴 측정
///
/// Google ML Kit Face Detection을 사용하여 사진에서 얼굴을 감지하고,
/// 관상학 분석에 필요한 17개 측정값을 추출합니다.
/// 모든 측정값은 얼굴 바운딩 박스 기준으로 0~1 범위로 정규화됩니다.
library;

import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../entities/face_measurements.dart';

// =============================================================================
// FaceAnalyzerService
// =============================================================================

/// 온디바이스 얼굴 분석 서비스
///
/// ML Kit의 Face Detection을 사용하여 사진에서 얼굴 윤곽(contour),
/// 랜드마크(landmark), 분류(classification) 정보를 추출합니다.
/// 추출된 원시 데이터를 관상학 분석에 적합한 정규화된 측정값으로 변환합니다.
///
/// 사용 후 반드시 [dispose]를 호출하여 리소스를 해제해야 합니다.
class FaceAnalyzerService {
  FaceAnalyzerService()
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

  /// 단일 사진에서 얼굴 측정값 추출
  ///
  /// [imageFile]: 분석할 이미지 파일
  ///
  /// 반환: 측정값 [FaceMeasurements], 얼굴이 감지되지 않으면 null
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

  /// 여러 사진을 분석하고 측정값 평균을 반환
  ///
  /// 3장의 사진을 분석하여 더 안정적인 측정값을 생성합니다.
  /// 얼굴이 하나도 감지되지 않으면 null을 반환합니다.
  ///
  /// [images]: 분석할 이미지 파일 목록 (권장: 3장)
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

  /// 사진에 얼굴이 있는지 빠르게 검증
  ///
  /// 관상 분석 전 사전 검증에 사용합니다.
  /// [imageFile]: 검증할 이미지 파일
  ///
  /// 반환: 얼굴이 감지되면 true
  Future<bool> validatePhoto(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);
    return faces.isNotEmpty;
  }

  /// 리소스 해제
  ///
  /// FaceDetector가 사용하는 네이티브 리소스를 해제합니다.
  /// 사용이 끝난 후 반드시 호출해야 합니다.
  void dispose() {
    _detector.close();
  }

  // ===========================================================================
  // 내부 계산 메서드
  // ===========================================================================

  /// ML Kit Face 객체에서 모든 측정값을 계산
  FaceMeasurements _computeMeasurements(Face face) {
    final box = face.boundingBox;
    final faceWidth = box.width;
    final faceHeight = box.height;
    final ratio = faceHeight / faceWidth;

    // 삼정(三停) 비율
    final thirds = _computeThirds(face, faceHeight);

    // 눈 메트릭
    final eyeMetrics = _computeEyeMetrics(face, faceWidth);

    // 코 메트릭
    final noseMetrics = _computeNoseMetrics(face, faceWidth, faceHeight);

    // 입 메트릭
    final mouthMetrics = _computeMouthMetrics(face, faceWidth, faceHeight);

    // 눈썹 메트릭
    final eyebrowMetrics = _computeEyebrowMetrics(face, faceHeight);

    // 턱선 각도
    final jawline = _computeJawlineAngle(face);

    // 대칭도
    final symmetry = _computeSymmetry(face);

    // 얼굴형 분류
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
      foreheadHeight: thirds.$1, // 이마 높이 = 상정 비율
      jawlineAngle: jawline,
      faceSymmetry: symmetry,
      faceLengthRatio: ratio.clamp(0.8, 2.0),
    );
  }

  /// 얼굴형 분류
  ///
  /// 세로/가로 비율과 턱선, 관자놀이 윤곽을 기반으로 6종 얼굴형을 분류합니다.
  String _classifyFaceShape(double ratio, Face face) {
    // 얼굴 윤곽 포인트 가져오기
    final faceContour = face.contours[FaceContourType.face];

    if (faceContour == null || faceContour.points.length < 10) {
      // 윤곽 데이터가 부족하면 비율로만 판단
      if (ratio < 1.1) return 'round';
      if (ratio > 1.5) return 'long';
      return 'oval';
    }

    final points = faceContour.points;
    final totalPoints = points.length;

    // 관자놀이(상부) 너비 vs 턱(하부) 너비 비교
    // 윤곽 포인트는 시계 방향으로 배열 (상단 중앙부터)
    final upperIdx = totalPoints ~/ 4;
    final lowerIdx = (totalPoints * 3) ~/ 4;

    final upperWidth =
        (points[upperIdx].x - points[totalPoints - upperIdx - 1].x).abs();
    final lowerWidth =
        (points[lowerIdx].x - points[totalPoints - lowerIdx - 1].x).abs();

    final widthRatio =
        upperWidth > 0 ? (lowerWidth / upperWidth).clamp(0.0, 2.0) : 1.0;

    // 분류 로직
    if (ratio < 1.15 && widthRatio > 0.85) return 'round';
    if (ratio > 1.5) return 'long';
    if (widthRatio < 0.7) return 'heart'; // 상부 넓고 하부 좁음
    if (widthRatio > 1.1) return 'diamond'; // 중부 넓고 상하 좁음
    if (ratio < 1.25 && widthRatio > 0.9) return 'square';
    return 'oval';
  }

  /// 삼정(三停) 비율 계산 — (상정, 중정, 하정)
  ///
  /// 이마(상정) : 눈썹~코끝(중정) : 코끝~턱(하정)의 비율.
  /// 이상적인 비율은 각각 ~0.33으로 균등합니다.
  (double, double, double) _computeThirds(Face face, double faceHeight) {
    if (faceHeight <= 0) return (0.33, 0.33, 0.34);

    final box = face.boundingBox;
    final faceTop = box.top;

    // 눈썹 위치 (상정/중정 경계)
    final leftEyebrow = face.contours[FaceContourType.leftEyebrowTop];
    final rightEyebrow = face.contours[FaceContourType.rightEyebrowTop];

    // 코끝 위치 (중정/하정 경계)
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
      // 눈썹 데이터가 없으면 기본 비율 사용
      eyebrowY = faceTop + faceHeight * 0.33;
    }

    double noseBottomY;
    if (noseBottom != null && noseBottom.points.isNotEmpty) {
      // 코 하단 윤곽의 중앙 포인트
      final midIdx = noseBottom.points.length ~/ 2;
      noseBottomY = noseBottom.points[midIdx].y.toDouble();
    } else {
      // 코 데이터가 없으면 기본 비율 사용
      noseBottomY = faceTop + faceHeight * 0.66;
    }

    final faceBottom = faceTop + faceHeight;

    final upper = ((eyebrowY - faceTop) / faceHeight).clamp(0.0, 1.0);
    final middle = ((noseBottomY - eyebrowY) / faceHeight).clamp(0.0, 1.0);
    final lower = ((faceBottom - noseBottomY) / faceHeight).clamp(0.0, 1.0);

    // 합이 1이 되도록 정규화
    final total = upper + middle + lower;
    if (total <= 0) return (0.33, 0.33, 0.34);

    return (upper / total, middle / total, lower / total);
  }

  /// 눈 메트릭 계산 — (간격, 기울기, 크기)
  ///
  /// 눈 사이 간격, 눈꼬리 기울기, 눈 크기를 정규화된 값으로 반환합니다.
  (double, double, double) _computeEyeMetrics(Face face, double faceWidth) {
    if (faceWidth <= 0) return (0.5, 0.0, 0.5);

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) return (0.5, 0.0, 0.5);

    final leftPos = leftEye.position;
    final rightPos = rightEye.position;

    // 눈 사이 간격 (정규화)
    final spacing =
        ((rightPos.x - leftPos.x).abs() / faceWidth).clamp(0.0, 1.0);

    // 눈 기울기 (양수: 올라감, 음수: 처짐) — atan2로 계산
    final dx = (rightPos.x - leftPos.x).toDouble();
    final dy = (rightPos.y - leftPos.y).toDouble();
    final slantRadians = dx != 0 ? atan2(dy, dx) : 0.0;
    final slant = (slantRadians / (pi / 4)).clamp(-1.0, 1.0); // -1 ~ 1 범위

    // 눈 크기 (윤곽 기반)
    double eyeSize = 0.5; // 기본값
    final leftEyeContour = face.contours[FaceContourType.leftEye];
    if (leftEyeContour != null && leftEyeContour.points.length >= 4) {
      final eyePoints = leftEyeContour.points;
      // 눈의 가로 길이
      final eyeWidth = eyePoints
          .map((p) => p.x.toDouble())
          .reduce(max) -
          eyePoints.map((p) => p.x.toDouble()).reduce(min);
      eyeSize = (eyeWidth / faceWidth).clamp(0.0, 1.0);
    }

    return (spacing, slant, eyeSize);
  }

  /// 코 메트릭 계산 — (콧대 높이, 코 너비)
  (double, double) _computeNoseMetrics(
    Face face,
    double faceWidth,
    double faceHeight,
  ) {
    if (faceWidth <= 0 || faceHeight <= 0) return (0.5, 0.5);

    // 콧대 높이: noseBridge 윤곽의 상단~하단 거리
    double bridgeHeight = 0.5;
    final noseBridge = face.contours[FaceContourType.noseBridge];
    if (noseBridge != null && noseBridge.points.length >= 2) {
      final topY = noseBridge.points.first.y.toDouble();
      final bottomY = noseBridge.points.last.y.toDouble();
      bridgeHeight = ((bottomY - topY).abs() / faceHeight).clamp(0.0, 1.0);
    }

    // 코 너비: noseBottom 윤곽의 좌우 폭
    double noseWidth = 0.5;
    final noseBottom = face.contours[FaceContourType.noseBottom];
    if (noseBottom != null && noseBottom.points.length >= 2) {
      final leftX = noseBottom.points.first.x.toDouble();
      final rightX = noseBottom.points.last.x.toDouble();
      noseWidth = ((rightX - leftX).abs() / faceWidth).clamp(0.0, 1.0);
    }

    return (bridgeHeight, noseWidth);
  }

  /// 입 메트릭 계산 — (입 너비, 입술 두께)
  (double, double) _computeMouthMetrics(
    Face face,
    double faceWidth,
    double faceHeight,
  ) {
    if (faceWidth <= 0 || faceHeight <= 0) return (0.5, 0.5);

    // 입 너비: 좌우 입꼬리 랜드마크 간 거리
    double mouthWidth = 0.5;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    if (leftMouth != null && rightMouth != null) {
      final width =
          (rightMouth.position.x - leftMouth.position.x).abs().toDouble();
      mouthWidth = (width / faceWidth).clamp(0.0, 1.0);
    }

    // 입술 두께: 상순 상단 ~ 하순 하단 윤곽 간 거리
    double lipThickness = 0.5;
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];
    if (upperLip != null &&
        upperLip.points.isNotEmpty &&
        lowerLip != null &&
        lowerLip.points.isNotEmpty) {
      // 윤곽 중앙 포인트 사용
      final upperMidIdx = upperLip.points.length ~/ 2;
      final lowerMidIdx = lowerLip.points.length ~/ 2;
      final upperY = upperLip.points[upperMidIdx].y.toDouble();
      final lowerY = lowerLip.points[lowerMidIdx].y.toDouble();
      lipThickness = ((lowerY - upperY).abs() / faceHeight).clamp(0.0, 1.0);
    }

    return (mouthWidth, lipThickness);
  }

  /// 눈썹 메트릭 계산 — (아치 정도, 두께)
  (double, double) _computeEyebrowMetrics(Face face, double faceHeight) {
    if (faceHeight <= 0) return (0.5, 0.5);

    // 눈썹 아치: 눈썹 상단 윤곽의 최고점 vs 양 끝점의 높이 차이
    double arch = 0.5;
    final leftEyebrowTop = face.contours[FaceContourType.leftEyebrowTop];
    if (leftEyebrowTop != null && leftEyebrowTop.points.length >= 3) {
      final points = leftEyebrowTop.points;
      final startY = points.first.y.toDouble();
      final endY = points.last.y.toDouble();
      final baselineY = (startY + endY) / 2;

      // 최고점 (y가 가장 작은 점)
      final peakY =
          points.map((p) => p.y.toDouble()).reduce(min);
      final archHeight = (baselineY - peakY).abs();
      arch = (archHeight / faceHeight).clamp(0.0, 1.0);
    }

    // 눈썹 두께: 상단 ~ 하단 윤곽 간 거리
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

  /// 턱선 각도 계산
  ///
  /// 얼굴 윤곽에서 턱 부분의 각도를 계산합니다.
  /// 값이 작을수록 뾰족한 턱, 클수록 둥근/각진 턱입니다.
  double _computeJawlineAngle(Face face) {
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null || faceContour.points.length < 10) return 0.5;

    final points = faceContour.points;
    final totalPoints = points.length;

    // 턱 끝 (하단 중앙) 인덱스
    final chinIdx = totalPoints ~/ 2;
    // 좌우 턱선 포인트
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

    // 좌측 턱선 벡터
    final v1x = leftJaw.x.toDouble() - chin.x.toDouble();
    final v1y = leftJaw.y.toDouble() - chin.y.toDouble();

    // 우측 턱선 벡터
    final v2x = rightJaw.x.toDouble() - chin.x.toDouble();
    final v2y = rightJaw.y.toDouble() - chin.y.toDouble();

    // 두 벡터 사이 각도 (코사인 법칙)
    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0.5;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final angle = acos(cosAngle); // 0 ~ pi

    // 0~1 범위로 정규화 (0: 뾰족, 1: 넓음)
    return (angle / pi).clamp(0.0, 1.0);
  }

  /// 얼굴 대칭도 계산
  ///
  /// 좌우 랜드마크의 y좌표 차이를 비교하여 대칭도를 계산합니다.
  /// 1.0이 완벽한 대칭, 0.0이 완전 비대칭입니다.
  double _computeSymmetry(Face face) {
    double totalDiff = 0.0;
    int comparisons = 0;

    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;

    // 눈 대칭
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      // y좌표 차이 (수평 대칭)
      final yDiff =
          (leftEye.position.y - rightEye.position.y).abs().toDouble();
      totalDiff += yDiff / box.height;

      // 중앙선으로부터의 거리 차이
      final leftDist = (centerX - leftEye.position.x).abs();
      final rightDist = (rightEye.position.x - centerX).abs();
      if (leftDist + rightDist > 0) {
        totalDiff += (leftDist - rightDist).abs() / (leftDist + rightDist);
      }
      comparisons += 2;
    }

    // 입꼬리 대칭
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

    if (comparisons == 0) return 0.8; // 기본값

    final avgDiff = totalDiff / comparisons;
    // 차이가 작을수록 대칭도가 높음 (1.0에 가까움)
    return (1.0 - avgDiff * 2).clamp(0.0, 1.0);
  }

  /// 여러 측정값의 평균 계산
  ///
  /// 3장의 사진에서 각각 추출한 측정값을 평균내어
  /// 더 안정적인 결과를 생성합니다.
  FaceMeasurements _averageMeasurements(List<FaceMeasurements> measurements) {
    final n = measurements.length;

    // 얼굴형은 최빈값 사용
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
