import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// AuthRepository Supabase 구현체
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Future<UserEntity?> signInWithApple() async {
    final response = await _datasource.signInWithApple();
    final userId = response.user?.id;
    if (userId == null) return null;

    return _fetchOrNull(userId);
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    final response = await _datasource.signInWithGoogle();
    final userId = response.user?.id;
    if (userId == null) return null;

    return _fetchOrNull(userId);
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<UserEntity?> getCurrentUserProfile() async {
    final user = _datasource.currentUser;
    if (user == null) return null;

    return _fetchOrNull(user.id);
  }

  @override
  Future<bool> hasProfile() async {
    final user = _datasource.currentUser;
    if (user == null) return false;

    final json = await _datasource.fetchProfile(user.id);
    return json != null;
  }

  Future<UserEntity?> _fetchOrNull(String authId) async {
    final json = await _datasource.fetchProfile(authId);
    if (json == null) return null;
    return UserModel.fromJson(json);
  }
}
