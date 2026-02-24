import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
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
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) return null;

      final result = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('auth_id', authId)
          .maybeSingle();

      if (result == null) return null;
      return UserModel.fromJson(result);
    } catch (e) {
      return null;
    }
  }
}
