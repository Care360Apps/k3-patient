import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro_patient/FirebaseModels/message_chat.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/apis.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider({required this.firebaseFirestore, required this.prefs, required this.firebaseStorage});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(docPath).set(dataNeedUpdate, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore.collection(FirestoreConstants.pathMessageCollection).doc(groupChatId).collection(groupChatId).orderBy(FirestoreConstants.timestamp, descending: true).limit(limit).snapshots();
  }

  void sendMessage(String content, int type, String groupChatId, String currentUserId, String peerId) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(now);

    MessageChat messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: now,
      content: content,
      type: type,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, messageChat.toJson());
    });

    firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .set({
      'lastMessage': type == TypeMessage.image ? '📷 Photo' : content,
      'lastTimestamp': now,
      'lastBy': currentUserId,
      'unread_$peerId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(peerId)
        .set({'totalUnread': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  void markAsRead(String groupChatId, String currentUserId) {
    final convDoc = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId);

    convDoc.get().then((snap) {
      if (snap.exists) {
        final unread = (snap.data()?['unread_$currentUserId'] ?? 0) as int;
        if (unread > 0) {
          convDoc.set({'unread_$currentUserId': 0}, SetOptions(merge: true));
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(currentUserId)
              .set({
            'totalUnread': FieldValue.increment(-unread),
          }, SetOptions(merge: true));
        }
      }
    }).catchError((_) {});
  }

  Stream<DocumentSnapshot> getConversationStream(String groupChatId) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .snapshots();
  }

  /// Opt-in staging path. Dispatch notifications only through the authenticated
  /// Laravel OneSignal endpoint; never put messaging credentials in a mobile app.
  /// Keep disabled until device-token alignment and server authorization tests pass.
  Future<void> sendNotification(String content, String? token, String userName,
      String userId, int type, String doctorName, String doctorImage) async {
    const backendPushEnabled = bool.fromEnvironment(
      'K3_BACKEND_PUSH_ENABLED', defaultValue: false,
    );
    if (!backendPushEnabled || token == null || token.trim().isEmpty ||
        token == 'N_A' || token == 'null') {
      return;
    }
    try {
      await RetroApi().dioData().post(
        '${Apis.baseUrl}send_message_to_doctor_notification',
        data: {
          // Push bodies must not disclose patient conversation or clinical text.
          'content': type == TypeMessage.image ? 'New image message' : 'New chat message',
          'to_device_token': token,
        },
      );
    } catch (_) {
      // Best effort; the Firestore chat message remains the source of truth.
      // Do not log access tokens, recipient tokens, or message contents.
    }
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = prefs.getString(FirestoreConstants.nickname);
    return FirebaseFirestore.instance.collection(FirestoreConstants.pathMessageCollection).orderBy("content", descending: true).where(FirestoreConstants.pathMessageCollection, arrayContains: myUsername).snapshots();
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}
