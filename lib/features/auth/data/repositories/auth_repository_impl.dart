import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_auction/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:live_auction/features/auth/data/models/user_model.dart';
import 'package:live_auction/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  User? get currentUser => _remoteDataSource.currentUser;

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _remoteDataSource.signUp(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<UserModel?> getUserProfile(String uid) {
    return _remoteDataSource.getUserProfile(uid);
  }
}
