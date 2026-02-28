import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/errors/failures.dart';
// NOTE: UserModel은 auth의 데이터 레이어 DTO입니다. data-to-data 크로스 피처
// 참조이며, UserModel을 core로 추출하거나 profile 전용 모델을 만들 때 해소 예정.
import '../../../auth/data/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UserEntity> createProfile({
    required String name,
    required String gender,
    required DateTime birthDate,
    String? birthTime,
  }) async {
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) throw AuthFailure.unauthenticated();

      final data = {
        'auth_id': authId,
        'name': name,
        'gender': gender,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'birth_time': birthTime,
      };

      final result = await _client
          .from(SupabaseTables.profiles)
          .insert(data)
          .select()
          .single();

      return UserModel.fromJson(result);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure.unknown(e);
    }
  }

  @override
  Future<UserEntity> completeMatchingProfile({
    required List<String> profileImageUrls,
    required int height,
    required String occupation,
    required String location,
    required String bio,
    required List<String> interests,
    String? mbti,
    DrinkingFrequency? drinking,
    SmokingStatus? smoking,
    String? datingStyle,
    Religion? religion,
  }) async {
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) throw AuthFailure.unauthenticated();

      final updates = {
        'profile_images': profileImageUrls,
        'height': height,
        'occupation': occupation,
        'location': location,
        'bio': bio,
        'interests': interests,
        'mbti': mbti,
        'drinking': drinking?.name,
        'smoking': smoking?.name,
        'dating_style': datingStyle,
        'religion': religion?.name,
        'is_profile_complete': true,
      };

      final result = await _client
          .from(SupabaseTables.profiles)
          .update(updates)
          .eq('auth_id', authId)
          .select()
          .single();

      return UserModel.fromJson(result);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure.unknown(e);
    }
  }

  @override
  Future<List<String>> uploadProfileImages(List<String> localFilePaths) async {
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) throw AuthFailure.unauthenticated();

      final urls = <String>[];
      for (var i = 0; i < localFilePaths.length; i++) {
        final file = File(localFilePaths[i]);
        final ext = localFilePaths[i].split('.').last.toLowerCase();
        final storagePath = '$authId/profile_$i.$ext';

        await _client.storage
            .from('profile-images')
            .upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = _client.storage
            .from('profile-images')
            .getPublicUrl(storagePath);
        urls.add(publicUrl);
      }

      return urls;
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: '이미지 업로드에 실패했어요. 다시 시도해 주세요.',
        code: 'IMAGE_UPLOAD_FAILED',
        originalException: e,
      );
    }
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> updates) async {
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) throw AuthFailure.unauthenticated();

      final result = await _client
          .from(SupabaseTables.profiles)
          .update(updates)
          .eq('auth_id', authId)
          .select()
          .single();

      return UserModel.fromJson(result);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure.unknown(e);
    }
  }

  @override
  Future<UserEntity?> getProfile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;

    try {
      final result = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('auth_id', authId)
          .maybeSingle();

      if (result == null) return null;
      return UserModel.fromJson(result);
    } on PostgrestException catch (e) {
      throw ServerFailure(
        message: '프로필 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        code: 'PROFILE_FETCH_FAILED',
        originalException: e,
      );
    }
  }
}
