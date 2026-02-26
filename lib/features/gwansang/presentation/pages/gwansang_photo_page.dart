import 'package:flutter/material.dart';

/// 관상 사진 업로드 페이지 -- 얼굴 사진 촬영/선택 화면
///
/// placeholder (Task G8에서 구현 예정)
class GwansangPhotoPage extends StatelessWidget {
  const GwansangPhotoPage({super.key, this.sajuResult});

  /// 사주 분석 결과 (GoRouter extra)
  final dynamic sajuResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관상 사진 업로드 - 구현 예정')),
      body: const Center(child: Text('구현 예정')),
    );
  }
}
