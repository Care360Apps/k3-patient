import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro_patient/Chat/utilities.dart';
import 'package:doctro_patient/FirebaseProviders/auth_provider.dart';
import 'package:doctro_patient/FirebaseProviders/chat_provider.dart';
import 'package:doctro_patient/FirebaseProviders/home_provider.dart';
import 'package:doctro_patient/FirebaseProviders/setting_provider.dart';
import 'package:doctro_patient/FirebaseModels/user_chat.dart';
import 'package:doctro_patient/Chat/chatPage.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/localization/localization_constant.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'loading_view.dart';

class Chat extends StatefulWidget {
  final int doctorId;
  final String where;
  /// When Firestore has no user doc for this doctorId, use these to open chat anyway (e.g. from appointment detail).
  final String? peerIdFallback;
  final String? peerNicknameFallback;
  final String? peerAvatarFallback;

  Chat({
    required this.doctorId,
    required this.where,
    this.peerIdFallback,
    this.peerNicknameFallback,
    this.peerAvatarFallback,
  });

  @override
  State createState() => ChatState();
}

class ChatState extends State<Chat> {
  ChatState({Key? key});

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  final int _limitIncrement = 20;
  bool isLoading = false;
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  bool _authReady = false;
  bool _authFailed = false;

  late AuthProvider authProvider;
  String currentUserId = '';
  late HomeProvider homeProvider;
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  late SettingProvider settingProvider;

  late ChatProvider chatProvider;
  String groupChatId = "";
  List<QueryDocumentSnapshot> listMessage = [];

  @override
  void initState() {
    super.initState();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    chatProvider = context.read<ChatProvider>();

    _initFirebaseUser();
    registerNotification();
    listScrollController.addListener(scrollListener);
  }

  Future<void> _initFirebaseUser() async {
    bool success = false;
    String? id;
    try {
      success = await authProvider.ensureFirebaseUser().timeout(const Duration(seconds: 30));
      id = authProvider.getUserFirebaseId();
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      currentUserId = success ? (id ?? '') : '';
      _authReady = true;
      _authFailed = !success || currentUserId.isEmpty;
    });
    if (!_authFailed) {
      unawaited(_getTokenSafely());
    }
  }

  Widget _buildErrorScreen(String message) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Palette.dark_blue),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Palette.blue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Palette.blue.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Palette.dark_blue),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    listScrollController.dispose();
    searchBarTec.dispose();
    btnClearController.close();
    super.dispose();
  }

  void registerNotification() {
    firebaseMessaging.requestPermission();

    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted || !_authReady || _authFailed) return;
      if (message.notification != null) {
        showNotification(message.notification!);
      }
      return;
    });

    // Safely get token with proper error handling
    _getTokenSafely();
  }
 
  Future<void> _getTokenSafely() async {
    // Laravel notification endpoints use OneSignal subscription IDs, not raw
    // FirebaseMessaging tokens. Never overwrite Firestore chat routing with FCM.
    try {
      final subscriptionId = SharedPreferenceHelper.getString(Preferences.device_token);
      if (subscriptionId == null || subscriptionId.isEmpty || subscriptionId == 'N_A') {
        return;
      }
      if (currentUserId.isNotEmpty) {
        await homeProvider.updateDataFirestore(
          FirestoreConstants.pathUserCollection,
          currentUserId,
          {FirestoreConstants.token: subscriptionId},
        );
      }
    } catch (_) {
      // A missing subscription must not prevent sending/reading chat messages.
    }
  }

  void scrollListener() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid ? 'com.dfa.flutterchatdemo' : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    DarwinNotificationDetails iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);


    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authReady) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitFadingCircle(color: Palette.blue, size: 40.0),
              const SizedBox(height: 16),
              Text(
                'Connecting...',
                style: TextStyle(fontSize: 14, color: Palette.grey.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    if (_authFailed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Palette.dark_blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Palette.blue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Palette.blue.withOpacity(0.5)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chat Unavailable',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please log out and log in again\nto access the chat.',
                  style: TextStyle(fontSize: 14, color: Palette.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: homeProvider.getStreamFireStore(FirestoreConstants.pathUserCollection, _limit, widget.doctorId.toString()),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return _buildErrorScreen(
              getTranslated(context, AppString.something_went_wrong_toast).toString(),
            );
          }
          if (snapshot.hasData) {
            if ((snapshot.data?.docs.length ?? 0) > 0) {
              final docs = snapshot.data!.docs;
              final did = widget.doctorId.toString();
              DocumentSnapshot bestDoc = docs.first;
              for (final d in docs) {
                if (d.id == 'doctor_$did' || d.id == 'provider_$did') {
                  bestDoc = d;
                  break;
                }
              }
              UserChat userChat = UserChat.fromDocument(bestDoc);
              if (Utilities.isKeyboardShowing()) {
                Utilities.closeKeyboard(context);
              }
              return ChatPage(
                peerId: userChat.id,
                peerAvatar: userChat.photoUrl,
                peerNickname: userChat.nickname,
                doctorToken: userChat.token,
                where: widget.where,
              );
            } else {
              return _buildErrorScreen('Doctor not available for chat yet.');
            }
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpinKitFadingCircle(color: Palette.blue, size: 40.0),
                const SizedBox(height: 16),
                Text(
                  'Loading chat...',
                  style: TextStyle(fontSize: 14, color: Palette.grey.withOpacity(0.7)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
