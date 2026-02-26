/// 얼굴 측정값 — ML Kit에서 추출한 구조화된 데이터
///
/// 사진이 서버로 전송되지 않고, 이 측정값(숫자)만 전송된다.
/// 관상학의 삼정(三停), 오관(五官) 분석에 필요한 모든 비율/수치를 포함.
library;

/// 얼굴 측정값 — ML Kit에서 추출한 구조화된 데이터
///
/// 사진이 서버로 전송되지 않고, 이 측정값(숫자)만 전송된다.
/// 관상학의 삼정(三停), 오관(五官) 분석에 필요한 모든 비율/수치를 포함.
class FaceMeasurements {
  const FaceMeasurements({
    required this.faceShape,
    required this.upperThird,
    required this.middleThird,
    required this.lowerThird,
    required this.eyeSpacing,
    required this.eyeSlant,
    required this.eyeSize,
    required this.noseBridgeHeight,
    required this.noseWidth,
    required this.mouthWidth,
    required this.lipThickness,
    required this.eyebrowArch,
    required this.eyebrowThickness,
    required this.foreheadHeight,
    required this.jawlineAngle,
    required this.faceSymmetry,
    required this.faceLengthRatio,
  });

  /// 얼굴형 (round, oval, square, heart, long, diamond)
  final String faceShape;

  // --- 삼정(三停) 비율 — 이상적인 값은 각각 ~0.33 ---

  /// 상정(上停): 이마 ~ 눈썹 비율
  final double upperThird;

  /// 중정(中停): 눈썹 ~ 코끝 비율
  final double middleThird;

  /// 하정(下停): 코끝 ~ 턱 비율
  final double lowerThird;

  // --- 눈 관련 ---

  /// 눈 사이 간격 (정규화된 비율)
  final double eyeSpacing;

  /// 눈 기울기 (양수: 올라감, 음수: 처짐)
  final double eyeSlant;

  /// 눈 크기 (정규화된 비율)
  final double eyeSize;

  // --- 코 관련 ---

  /// 콧대 높이 (정규화된 비율)
  final double noseBridgeHeight;

  /// 코 너비 (정규화된 비율)
  final double noseWidth;

  // --- 입 관련 ---

  /// 입 너비 (정규화된 비율)
  final double mouthWidth;

  /// 입술 두께 (정규화된 비율)
  final double lipThickness;

  // --- 눈썹 관련 ---

  /// 눈썹 아치 정도 (정규화된 비율)
  final double eyebrowArch;

  /// 눈썹 두께 (정규화된 비율)
  final double eyebrowThickness;

  // --- 이마 ---

  /// 이마 높이 (정규화된 비율)
  final double foreheadHeight;

  // --- 턱 ---

  /// 턱선 각도 (정규화된 비율)
  final double jawlineAngle;

  // --- 종합 ---

  /// 대칭도 (0~1, 1이 완벽 대칭)
  final double faceSymmetry;

  /// 얼굴 세로/가로 비율
  final double faceLengthRatio;

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'face_shape': faceShape,
    'upper_third': upperThird,
    'middle_third': middleThird,
    'lower_third': lowerThird,
    'eye_spacing': eyeSpacing,
    'eye_slant': eyeSlant,
    'eye_size': eyeSize,
    'nose_bridge_height': noseBridgeHeight,
    'nose_width': noseWidth,
    'mouth_width': mouthWidth,
    'lip_thickness': lipThickness,
    'eyebrow_arch': eyebrowArch,
    'eyebrow_thickness': eyebrowThickness,
    'forehead_height': foreheadHeight,
    'jawline_angle': jawlineAngle,
    'face_symmetry': faceSymmetry,
    'face_length_ratio': faceLengthRatio,
  };

  /// JSON 역직렬화
  factory FaceMeasurements.fromJson(Map<String, dynamic> json) {
    return FaceMeasurements(
      faceShape: json['face_shape'] as String? ?? 'oval',
      upperThird: (json['upper_third'] as num?)?.toDouble() ?? 0.33,
      middleThird: (json['middle_third'] as num?)?.toDouble() ?? 0.33,
      lowerThird: (json['lower_third'] as num?)?.toDouble() ?? 0.34,
      eyeSpacing: (json['eye_spacing'] as num?)?.toDouble() ?? 0.5,
      eyeSlant: (json['eye_slant'] as num?)?.toDouble() ?? 0.0,
      eyeSize: (json['eye_size'] as num?)?.toDouble() ?? 0.5,
      noseBridgeHeight:
          (json['nose_bridge_height'] as num?)?.toDouble() ?? 0.5,
      noseWidth: (json['nose_width'] as num?)?.toDouble() ?? 0.5,
      mouthWidth: (json['mouth_width'] as num?)?.toDouble() ?? 0.5,
      lipThickness: (json['lip_thickness'] as num?)?.toDouble() ?? 0.5,
      eyebrowArch: (json['eyebrow_arch'] as num?)?.toDouble() ?? 0.5,
      eyebrowThickness:
          (json['eyebrow_thickness'] as num?)?.toDouble() ?? 0.5,
      foreheadHeight: (json['forehead_height'] as num?)?.toDouble() ?? 0.5,
      jawlineAngle: (json['jawline_angle'] as num?)?.toDouble() ?? 0.5,
      faceSymmetry: (json['face_symmetry'] as num?)?.toDouble() ?? 0.8,
      faceLengthRatio:
          (json['face_length_ratio'] as num?)?.toDouble() ?? 1.3,
    );
  }
}
