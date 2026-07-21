import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_auction/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Failed to create Firebase Auth user');
    }

    final userModel = UserModel(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      profileImage: '',
      deviceToken: '',
      isOnline: true,
      isBlocked: false,
      totalAuctionsJoined: 0,
      totalWins: 0,
      totalBids: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    // Update Firebase Auth display name
    await user.updateDisplayName(name.trim());

    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('User not found');
    }

    // Update or create user profile and set isOnline status
    await _firestore.collection('users').doc(user.uid).set({
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?.containsKey('name') == true) {
      return UserModel.fromDocument(doc);
    } else {
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: '',
        profileImage: '',
        deviceToken: '',
        isOnline: true,
        isBlocked: false,
        totalAuctionsJoined: 0,
        totalWins: 0,
        totalBids: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap(), SetOptions(merge: true));
      return userModel;
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Ignore network errors on signout
      }
    }
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }
}
