/// 사용자(User) 공유 도메인 엔티티
///
/// UserEntity는 auth, profile, matching 등 다수 feature에서 사용하는
/// 앱의 핵심 도메인 모델입니다. Clean Architecture의 의존성 규칙을 지키기 위해
/// core/domain에 위치하여 모든 feature가 동등하게 참조합니다.
///
/// auth feature: 사용자를 **인증/생성**한다
/// profile feature: 사용자 정보를 **조회/수정**한다
/// matching feature: 사용자 정보를 **매칭에 활용**한다
///
/// 이 파일은 원래 auth/domain/entities/user_entity.dart에 있던 내용을
/// 그대로 re-export합니다. auth 쪽 파일은 이 파일을 export하는 형태로
/// 하위 호환성을 유지합니다.
library;

export '../../../features/auth/domain/entities/user_entity.dart';
