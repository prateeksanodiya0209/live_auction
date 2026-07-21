import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_auction/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getUserProfile(String uid);
}
