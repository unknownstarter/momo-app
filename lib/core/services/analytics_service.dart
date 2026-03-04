import 'package:firebase_analytics/firebase_analytics.dart';

/// 글로벌 이벤트 트래킹 서비스
///
/// 네이밍 컨벤션:
/// - 화면 조회: `view_{screen}` (예: view_home, view_login)
/// - 클릭: `click_{action}_in_{screen}` (예: click_apple_login_in_login)
/// - 완료: `complete_{action}` (예: complete_onboarding)
/// - 비즈니스: `{action}` (예: like_sent, match_created)
abstract final class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  /// GoRouter observer — app_router.dart에 등록
  static final observer = FirebaseAnalyticsObserver(analytics: _analytics);

  // ---------------------------------------------------------------------------
  // Screen Views (자동 추적 + 수동 보완)
  // ---------------------------------------------------------------------------

  static Future<void> viewScreen(String screenName) =>
      _analytics.logScreenView(screenClass: screenName, screenName: screenName);

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  static Future<void> clickAppleLoginInLogin() =>
      _log('click_apple_login_in_login');

  static Future<void> clickKakaoLoginInLogin() =>
      _log('click_kakao_login_in_login');

  static Future<void> clickBrowseInLogin() =>
      _log('click_browse_in_login');

  static Future<void> loginSuccess({required String method}) =>
      _analytics.logLogin(loginMethod: method);

  static Future<void> clickLogout() => _log('click_logout');

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  static Future<void> viewOnboardingSlide({required int step}) =>
      _log('view_onboarding_slide', {'step': step});

  static Future<void> clickStartFormInOnboarding() =>
      _log('click_start_form_in_onboarding');

  static Future<void> completeOnboardingStep({required int step, required String stepName}) =>
      _log('complete_onboarding_step', {'step': step, 'step_name': stepName});

  static Future<void> clickSendSmsInOnboarding() =>
      _log('click_send_sms_in_onboarding');

  static Future<void> completeSmsVerification() =>
      _log('complete_sms_verification');

  static Future<void> clickStartAnalysisInOnboarding() =>
      _log('click_start_analysis_in_onboarding');

  static Future<void> completeOnboarding() => _log('complete_onboarding');

  // ---------------------------------------------------------------------------
  // Destiny Analysis (사주 + 관상 통합)
  // ---------------------------------------------------------------------------

  static Future<void> startDestinyAnalysis() =>
      _log('start_destiny_analysis');

  static Future<void> completeSajuAnalysis() =>
      _log('complete_saju_analysis');

  static Future<void> completeGwansangAnalysis() =>
      _log('complete_gwansang_analysis');

  static Future<void> completeDestinyAnalysis() =>
      _log('complete_destiny_analysis');

  static Future<void> clickFindMatchesInDestinyResult() =>
      _log('click_find_matches_in_destiny_result');

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  static Future<void> clickCardInHome({required String section, String? profileId}) {
    final params = <String, Object>{'section': section};
    if (profileId != null) params['profile_id'] = profileId;
    return _log('click_card_in_home', params);
  }

  static Future<void> clickSeeMoreInHome({required String section}) =>
      _log('click_see_more_in_home', {'section': section});

  // ---------------------------------------------------------------------------
  // Matching
  // ---------------------------------------------------------------------------

  static Future<void> clickTabInMatching({required int tabIndex}) =>
      _log('click_tab_in_matching', {'tab_index': tabIndex});

  static Future<void> clickFilterInMatching({required String element}) =>
      _log('click_filter_in_matching', {'element': element});

  static Future<void> clickProfileCard({required String source, String? profileId}) {
    final params = <String, Object>{'source': source};
    if (profileId != null) params['profile_id'] = profileId;
    return _log('click_profile_card', params);
  }

  // ---------------------------------------------------------------------------
  // Like / Match
  // ---------------------------------------------------------------------------

  static Future<void> likeSent({String? profileId, String? source}) {
    final params = <String, Object>{};
    if (profileId != null) params['profile_id'] = profileId;
    if (source != null) params['source'] = source;
    return _log('like_sent', params);
  }

  static Future<void> likeAccepted({String? profileId}) {
    final params = <String, Object>{};
    if (profileId != null) params['profile_id'] = profileId;
    return _log('like_accepted', params);
  }

  static Future<void> likeRejected({String? profileId}) {
    final params = <String, Object>{};
    if (profileId != null) params['profile_id'] = profileId;
    return _log('like_rejected', params);
  }

  static Future<void> matchCreated() => _log('match_created');

  // ---------------------------------------------------------------------------
  // Compatibility
  // ---------------------------------------------------------------------------

  static Future<void> viewCompatibilityPreview({String? profileId}) {
    final params = <String, Object>{};
    if (profileId != null) params['profile_id'] = profileId;
    return _log('view_compatibility_preview', params);
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  static Future<void> clickChatRoom({required String roomId}) =>
      _log('click_chat_room', {'room_id': roomId});

  static Future<void> messageSent() => _log('message_sent');

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  static Future<void> clickEditProfile() => _log('click_edit_profile');

  static Future<void> clickSettingsInProfile() =>
      _log('click_settings_in_profile');

  static Future<void> clickPaymentInProfile() =>
      _log('click_payment_in_profile');

  static Future<void> completeMatchingProfile() =>
      _log('complete_matching_profile');

  // ---------------------------------------------------------------------------
  // Gwansang (관상)
  // ---------------------------------------------------------------------------

  static Future<void> clickTakePhotoInGwansang({required int step}) =>
      _log('click_take_photo_in_gwansang', {'step': step});

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  static Future<void> switchTab({required int tabIndex, required String tabName}) =>
      _log('switch_tab', {'tab_index': tabIndex, 'tab_name': tabName});

  // ---------------------------------------------------------------------------
  // Private helper
  // ---------------------------------------------------------------------------

  static Future<void> _log(String name, [Map<String, Object>? params]) =>
      _analytics.logEvent(name: name, parameters: params);
}
