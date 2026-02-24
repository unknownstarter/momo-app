import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client.g.dart';

// =============================================================================
// Supabase 클라이언트 Provider
// =============================================================================

/// Supabase 클라이언트 인스턴스 Provider
///
/// main.dart에서 Supabase.initialize()를 호출한 후에만 사용 가능합니다.
/// 앱 전역에서 Supabase 서비스에 접근할 때 이 Provider를 사용합니다.
///
/// ```dart
/// final client = ref.watch(supabaseClientProvider);
/// final data = await client.from('profiles').select();
/// ```
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// GoTrue 인증 클라이언트 Provider
///
/// 인증 관련 작업에 직접 접근할 때 사용합니다.
/// 대부분의 경우 authStateProvider를 사용하는 것이 더 적합합니다.
@riverpod
GoTrueClient supabaseAuth(Ref ref) {
  return ref.watch(supabaseClientProvider).auth;
}

// =============================================================================
// 인증 상태 스트림 Provider
// =============================================================================

/// 현재 인증된 사용자 세션 스트림
///
/// go_router의 redirect와 함께 사용하여 인증 상태 변경 시
/// 자동으로 적절한 페이지로 리다이렉트합니다.
///
/// 반환값:
/// - Session: 로그인된 상태
/// - null: 로그아웃된 상태
@riverpod
Stream<Session?> authState(Ref ref) {
  final auth = ref.watch(supabaseAuthProvider);

  // 초기 세션 + 이후 변경 사항을 하나의 스트림으로
  return auth.onAuthStateChange.map((data) => data.session);
}

/// 현재 로그인된 사용자 (동기적 접근)
///
/// null이면 로그인되지 않은 상태입니다.
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(supabaseAuthProvider).currentUser;
}

/// 현재 세션 (동기적 접근)
@riverpod
Session? currentSession(Ref ref) {
  return ref.watch(supabaseAuthProvider).currentSession;
}

// =============================================================================
// Supabase 헬퍼 메서드 클래스
// =============================================================================

/// Supabase 공통 작업을 위한 헬퍼 클래스
///
/// Repository 구현체에서 직접 SupabaseClient를 사용해도 되지만,
/// 반복되는 패턴(에러 핸들링, 페이지네이션 등)을 여기서 추상화합니다.
class SupabaseHelper {
  const SupabaseHelper(this._client);

  final SupabaseClient _client;

  // --- 데이터 조회 ---

  /// 단일 레코드 조회 (by ID)
  ///
  /// [table]: 테이블 이름
  /// [id]: 레코드 ID
  /// [columns]: 조회할 컬럼 (기본: 전체)
  Future<Map<String, dynamic>?> getById(
    String table,
    String id, {
    String columns = '*',
  }) async {
    final response = await _client
        .from(table)
        .select(columns)
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// 페이지네이션 조회
  ///
  /// [table]: 테이블 이름
  /// [columns]: 조회할 컬럼
  /// [page]: 페이지 번호 (1부터 시작)
  /// [pageSize]: 페이지당 레코드 수
  /// [orderBy]: 정렬 기준 컬럼
  /// [ascending]: 오름차순 여부
  Future<List<Map<String, dynamic>>> getPaginated(
    String table, {
    String columns = '*',
    int page = 1,
    int pageSize = 20,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    final response = await _client
        .from(table)
        .select(columns)
        .order(orderBy, ascending: ascending)
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- 데이터 삽입/수정/삭제 ---

  /// 레코드 삽입 (upsert)
  ///
  /// 이미 존재하면 업데이트, 없으면 삽입합니다.
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _client.from(table).upsert(data).select().single();
    return response;
  }

  /// 레코드 업데이트
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from(table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// 소프트 삭제 (deleted_at 타임스탬프 설정)
  Future<void> softDelete(String table, String id) async {
    await _client
        .from(table)
        .update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  // --- Storage ---

  /// 프로필 이미지 업로드
  ///
  /// [bucket]: Storage 버킷명
  /// [path]: 저장 경로 (예: 'user-id/photo-1.jpg')
  /// [fileBytes]: 파일 바이트 데이터
  /// [contentType]: MIME 타입 (예: 'image/jpeg')
  ///
  /// 반환: 업로드된 파일의 public URL
  Future<String> uploadFile(
    String bucket,
    String path,
    List<int> fileBytes, {
    String contentType = 'image/jpeg',
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          fileBytes as dynamic,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// 파일 삭제
  Future<void> deleteFile(String bucket, List<String> paths) async {
    await _client.storage.from(bucket).remove(paths);
  }

  // --- Realtime ---

  /// 테이블 변경 사항 실시간 구독
  ///
  /// [table]: 테이블 이름
  /// [filter]: PostgresChangeFilter 인스턴스 (예: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: 'abc-123'))
  /// [callback]: 변경 이벤트 콜백
  RealtimeChannel subscribeToTable(
    String table, {
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) callback,
  }) {
    final channel = _client.channel('public:$table');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: filter,
      callback: callback,
    );

    channel.subscribe();
    return channel;
  }

  // --- Edge Functions ---

  /// Edge Function 호출
  ///
  /// [functionName]: 함수 이름
  /// [body]: 요청 본문
  Future<dynamic> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body,
    );
    return response.data;
  }
}

/// SupabaseHelper Provider
@riverpod
SupabaseHelper supabaseHelper(Ref ref) {
  return SupabaseHelper(ref.watch(supabaseClientProvider));
}
