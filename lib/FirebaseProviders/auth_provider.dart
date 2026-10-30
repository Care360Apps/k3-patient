import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:doctro_patient/FirebaseModels/user_chat.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status { uninitialized, authenticated, authenticating, authenticateError, authenticateCanceled }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider({
    required this.firebaseAuth,
    required this.prefs,
    required this.firebaseFirestore,
  });

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    return prefs.getString(FirestoreConstants.id)?.isNotEmpty == true;
  }

  bool check = false;

  Future<bool> handleSignIn(String email, String password) async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      User? user = (await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user;
      if (user != null) {
        final QuerySnapshot result = await firebaseFirestore.collection(FirestoreConstants.pathUserCollection).where(FirestoreConstants.id, isEqualTo: user.uid).get();
        final List<DocumentSnapshot> documents = result.docs;
        if (documents.length == 0) {
          firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(user.uid).set({
            FirestoreConstants.nickname: SharedPreferenceHelper.getString(FirestoreConstants.nickname)!,
            FirestoreConstants.photoUrl: SharedPreferenceHelper.getString(FirestoreConstants.photoUrl)!,
            FirestoreConstants.userType: "patient",
            FirestoreConstants.id: user.uid,
            FirestoreConstants.userId: SharedPreferenceHelper.getString(Preferences.userId),
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });

          User? currentUser = user;
          await prefs.setString(FirestoreConstants.id, currentUser.uid);
          await prefs.setString(FirestoreConstants.nickname, currentUser.displayName ?? "");
          await prefs.setString(FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
        } else {
          DocumentSnapshot documentSnapshot = documents[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);
          await prefs.setString(FirestoreConstants.id, userChat.id);
          await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
          await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
          await prefs.setString(FirestoreConstants.userType, userChat.userType);
        }
        _status = Status.authenticated;
        notifyListeners();
        return check = true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return check = false;
      }
    } on FirebaseAuthException catch (signUpError) {
      if (signUpError.code == 'ERROR_EMAIL_ALREADY_IN_USE' || signUpError.code == "email-already-in-use") {
        try {
          User? user = (await _auth.signInWithEmailAndPassword(email: email, password: password)).user;
          if (user != null) {
            final QuerySnapshot result = await firebaseFirestore.collection(FirestoreConstants.pathUserCollection).where(FirestoreConstants.id, isEqualTo: user.uid).get();
            final List<DocumentSnapshot> documents = result.docs;
            if (documents.length == 0) {
              firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(user.uid).set({
                FirestoreConstants.nickname: SharedPreferenceHelper.getString(FirestoreConstants.nickname)!,
                FirestoreConstants.photoUrl: SharedPreferenceHelper.getString(FirestoreConstants.photoUrl)!,
                FirestoreConstants.userType: "patient",
                FirestoreConstants.id: user.uid,
                'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
                FirestoreConstants.chattingWith: null
              });
              print("UserId ${user.uid} ${FirestoreConstants.id}");

              User? currentUser = user;
              await prefs.setString(FirestoreConstants.id, currentUser.uid);
              await prefs.setString(FirestoreConstants.nickname, currentUser.displayName ?? "");
              await prefs.setString(FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
            } else {
              DocumentSnapshot documentSnapshot = documents[0];
              UserChat userChat = UserChat.fromDocument(documentSnapshot);

              await prefs.setString(FirestoreConstants.id, userChat.id);
              await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
              await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
              await prefs.setString(FirestoreConstants.userType, userChat.userType);
            }

            _status = Status.authenticated;
            notifyListeners();

            return check = true;
          } else {
            _status = Status.authenticateError;
            notifyListeners();
            return check = false;
          }
        } on FirebaseAuthException {
          _status = Status.authenticateError;
          notifyListeners();
          return check = false;
        } catch (_) {
          _status = Status.authenticateError;
          notifyListeners();
          return check = false;
        }
      } else {
        return check = false;
      }
    } catch (_) {
      _status = Status.authenticateError;
      notifyListeners();
      return check = false;
    }
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
  }

  /// Sign into Firebase using the custom token issued by our backend.
  /// Also writes / updates this user's document in the Firestore `users` collection.
  Future<bool> signInWithCustomToken({
    required String customToken,
    required String appUserId,
    required String nickname,
    required String photoUrl,
    String userType = 'patient',
  }) async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final UserCredential cred = await firebaseAuth.signInWithCustomToken(customToken);
      final User? user = cred.user;
      if (user == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      // Store the Firebase UID in prefs IMMEDIATELY after sign-in so that
      // even if the Firestore write below fails the session is still usable.
      await prefs.setString(FirestoreConstants.id, user.uid);
      await prefs.setString(FirestoreConstants.nickname, nickname);
      await prefs.setString(FirestoreConstants.photoUrl, photoUrl);
      await prefs.setString(FirestoreConstants.userType, userType);

      // Upsert the Firestore users document so the chat lookup can find this user.
      // This is non-fatal — Firebase Auth is already established above.
      try {
        final docRef = firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(user.uid);
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set({
            FirestoreConstants.id: user.uid,
            FirestoreConstants.userId: appUserId,
            FirestoreConstants.nickname: nickname,
            FirestoreConstants.photoUrl: photoUrl,
            FirestoreConstants.userType: userType,
            FirestoreConstants.chattingWith: null,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        } else {
          await docRef.update({
            FirestoreConstants.nickname: nickname,
            FirestoreConstants.photoUrl: photoUrl,
            FirestoreConstants.userId: appUserId,
          });
        }
      } catch (_) {
        // Non-fatal: the Firebase Auth session is active even if we cannot
        // write the profile doc yet (e.g. rules haven't been updated).
      }

      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('signInWithCustomToken failed: $e');
      }
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
  }

  /// Ensure there is an active Firebase Auth session.
  /// Returns `true` if a valid session exists after this call.
  /// Does NOT fall back to anonymous auth — users must sign in at login time
  /// via custom token or email/password.
  Future<bool> ensureFirebaseUser() async {
    try {
      User? user = firebaseAuth.currentUser;
      if (kDebugMode) {
        print('ensureFirebaseUser: currentUser=${user?.uid}');
      }

      if (user == null) {
        final email = SharedPreferenceHelper.getString(FirestoreConstants.email);
        final password = SharedPreferenceHelper.getString(FirestoreConstants.password);
        if (email != null && email.isNotEmpty && email != 'N_A' &&
            password != null && password.isNotEmpty && password != 'N_A') {
          try {
            final cred = await firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            user = cred.user;
          } on FirebaseAuthException catch (e) {
            if (kDebugMode) {
              print('ensureFirebaseUser email/password fallback: ${e.code}');
            }
          }
        }
      }

      if (user == null) {
        if (kDebugMode) {
          print('ensureFirebaseUser: no session available — user must log in again');
        }
        return false;
      }

      await prefs.setString(FirestoreConstants.id, user.uid);

      // Ensure the Firestore user document exists with all required fields
      // so the doctor_app can find this patient in the chat list.
      _ensureFirestoreUserDoc(user.uid);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ensureFirebaseUser FAILED: $e');
      }
      return false;
    }
  }

  void _ensureFirestoreUserDoc(String uid) {
    final nickname = SharedPreferenceHelper.getString(FirestoreConstants.nickname) ?? '';
    final photoUrl = SharedPreferenceHelper.getString(FirestoreConstants.photoUrl) ?? '';
    final appUserId = SharedPreferenceHelper.getString(Preferences.userId) ?? '';

    firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(uid)
        .set({
      FirestoreConstants.id: uid,
      FirestoreConstants.nickname: nickname == 'N_A' ? '' : nickname,
      FirestoreConstants.photoUrl: photoUrl == 'N_A' ? '' : photoUrl,
      FirestoreConstants.userType: 'patient',
      FirestoreConstants.userId: appUserId == 'N_A' ? '' : appUserId,
    }, SetOptions(merge: true)).catchError((e) {
      if (kDebugMode) {
        print('_ensureFirestoreUserDoc failed (non-fatal): $e');
      }
    });
  }

}
