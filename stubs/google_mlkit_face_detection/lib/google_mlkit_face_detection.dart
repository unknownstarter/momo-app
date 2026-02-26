/// Stub for google_mlkit_face_detection — simulator/test builds only.
///
/// Provides the same public API as the real package but with no native
/// dependencies. All methods throw [UnsupportedError] at runtime.
library;

export 'dart:math' show Point;

import 'dart:io';
import 'dart:math';
import 'dart:ui';

// =============================================================================
// InputImage
// =============================================================================

class InputImage {
  InputImage._();

  static InputImage fromFile(File file) => InputImage._();
}

// =============================================================================
// FaceDetectorOptions / FaceDetectorMode
// =============================================================================

enum FaceDetectorMode { fast, accurate }

class FaceDetectorOptions {
  const FaceDetectorOptions({
    this.enableContours = false,
    this.enableLandmarks = false,
    this.enableClassification = false,
    this.enableTracking = false,
    this.minFaceSize = 0.1,
    this.performanceMode = FaceDetectorMode.fast,
  });

  final bool enableContours;
  final bool enableLandmarks;
  final bool enableClassification;
  final bool enableTracking;
  final double minFaceSize;
  final FaceDetectorMode performanceMode;
}

// =============================================================================
// FaceDetector
// =============================================================================

class FaceDetector {
  FaceDetector({required FaceDetectorOptions options});

  Future<List<Face>> processImage(InputImage inputImage) {
    throw UnsupportedError(
      'ML Kit Face Detection is not available on this platform. '
      'Use MockFaceAnalyzerService instead.',
    );
  }

  void close() {}
}

// =============================================================================
// Face
// =============================================================================

class Face {
  Face({
    required this.boundingBox,
    this.landmarks = const {},
    this.contours = const {},
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.trackingId,
  });

  final Rect boundingBox;
  final Map<FaceLandmarkType, FaceLandmark> landmarks;
  final Map<FaceContourType, FaceContour> contours;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final int? trackingId;
}

// =============================================================================
// FaceLandmark
// =============================================================================

enum FaceLandmarkType {
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftMouth,
  rightMouth,
  bottomMouth,
  noseBase,
  leftCheek,
  rightCheek,
}

class FaceLandmark {
  const FaceLandmark({required this.type, required this.position});

  final FaceLandmarkType type;
  final Point<int> position;
}

// =============================================================================
// FaceContour
// =============================================================================

enum FaceContourType {
  face,
  leftEyebrowTop,
  leftEyebrowBottom,
  rightEyebrowTop,
  rightEyebrowBottom,
  leftEye,
  rightEye,
  upperLipTop,
  upperLipBottom,
  lowerLipTop,
  lowerLipBottom,
  noseBridge,
  noseBottom,
  leftCheek,
  rightCheek,
}

class FaceContour {
  const FaceContour({required this.type, required this.points});

  final FaceContourType type;
  final List<Point<int>> points;
}

