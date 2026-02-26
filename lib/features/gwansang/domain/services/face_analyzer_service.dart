/// 얼굴 분석 서비스 — 인터페이스 (순수 Dart, 외부 의존성 없음)
///
/// 사진에서 얼굴을 감지하고 관상학 분석에 필요한 17개 측정값을 추출합니다.
/// 구현체는 data 레이어에 위치합니다:
///   - MlKitFaceAnalyzerService: 실 기기용 (Google ML Kit)
///   - MockFaceAnalyzerService: 시뮬레이터/테스트용
library;

import 'dart:io';

import '../entities/face_measurements.dart';

/// 온디바이스 얼굴 분석 서비스 인터페이스
///
/// Domain 레이어의 순수 인터페이스입니다.
/// ML Kit 등 외부 패키지에 의존하지 않습니다.
abstract class FaceAnalyzerService {
  /// 단일 사진에서 얼굴 측정값 추출
  ///
  /// [imageFile]: 분석할 이미지 파일
  /// 반환: 측정값 [FaceMeasurements], 얼굴이 감지되지 않으면 null
  Future<FaceMeasurements?> analyze(File imageFile);

  /// 여러 사진을 분석하고 측정값 평균을 반환
  ///
  /// 3장의 사진을 분석하여 더 안정적인 측정값을 생성합니다.
  /// [images]: 분석할 이미지 파일 목록 (권장: 3장)
  Future<FaceMeasurements?> analyzeMultiple(List<File> images);

  /// 사진에 얼굴이 있는지 빠르게 검증
  ///
  /// 관상 분석 전 사전 검증에 사용합니다.
  Future<bool> validatePhoto(File imageFile);

  /// 리소스 해제
  void dispose();
}
