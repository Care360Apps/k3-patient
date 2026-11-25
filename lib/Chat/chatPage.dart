import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/localization/localization_constant.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:doctro_patient/const/preference.dart';
import '../Screen/Screens/Home.dart';
import 'full_photo_page.dart';
import 'loading_view.dart';
import 'package:doctro_patient/FirebaseProviders/auth_provider.dart';
import 'package:doctro_patient/FirebaseProviders/chat_provider.dart';
import 'package:doctro_patient/FirebaseModels/message_chat.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  final String doctorToken;
  final String where;

  const ChatPage({
    Key? key,
    required this.peerId,
    required this.peerAvatar,
    required this.peerNickname,
    required this.doctorToken,
    required this.where,
  }) : super(key: key);

  @override
  State createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  String currentUserId = '';

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = '';

  File? imageFileCamera;
  File? imageFileGallery;
  bool isLoading = false;
  String imageUrlCamera = '';
  String imageUrlGallery = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    listScrollController.addListener(_scrollListener);
    _initAndRead();
  }

  Future<void> _initAndRead() async {
    await authProvider.ensureFirebaseUser();
    if (mounted) {
      readLocal();
      setState(() {
        _authReady = true;
      });
    }
  }

  void _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void readLocal() {
    final uid = authProvider.getUserFirebaseId();
    if (uid != null && uid.isNotEmpty) {
      currentUserId = uid;
    }

    if (currentUserId.isEmpty) return;

    if (currentUserId.compareTo(widget.peerId) > 0) {
      groupChatId = '$currentUserId-${widget.peerId}';
    } else {
      groupChatId = '${widget.peerId}-$currentUserId';
    }


    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: widget.peerId},
    );

    chatProvider.markAsRead(groupChatId, currentUserId);
  }

  Future getImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted && pickedFile != null) {
      imageFileGallery = File(pickedFile.path);
      setState(() => isLoading = true);
      uploadFileGallery();
    }
  }

  Future getImageFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (mounted && pickedFile != null) {
      imageFileCamera = File(pickedFile.path);
      setState(() => isLoading = true);
      uploadFileCamera();
    }
  }

  Future uploadFileCamera() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFileCamera!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrlCamera = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrlCamera, TypeMessage.image);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Image upload failed. Please try again.');
    }
  }

  Future uploadFileGallery() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask =
        chatProvider.uploadFile(imageFileGallery!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrlGallery = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrlGallery, TypeMessage.image);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Image upload failed. Please try again.');
    }
  }

  bool _sending = false;

  Future<void> onSendMessage(String content, int type) async {
    if (!mounted || _sending || !_authReady || groupChatId.isEmpty ||
        currentUserId.isEmpty || widget.peerId.isEmpty ||
        content.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.peerId);
      if (!mounted) return;
      if (type == TypeMessage.text && textEditingController.text == content) {
        textEditingController.clear();
      }
      chatProvider.sendNotification(
        content, widget.doctorToken,
        SharedPreferenceHelper.getString(Preferences.name) ?? '',
        currentUserId, type, widget.peerNickname, widget.peerAvatar,
      );
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Message not confirmed. Please check your connection.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    listScrollController.removeListener(_scrollListener);
    listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool isLastMessageLeft(int index) {
    return (index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0;
  }

  bool isLastMessageRight(int index) {
    return (index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0;
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dt)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE h:mm a').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  void _handleBack() {
    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: null},
    );
    if (widget.where == 'DoctorDetail' || widget.where == 'chatList') {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Home()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Palette.dark_blue,
        onPressed: _handleBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildPeerAvatar(36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerNickname,
                  style: const TextStyle(
                    color: Palette.dark_blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Palette.blue.withOpacity(0.2), width: 2),
      ),
      child: ClipOval(
        child: widget.peerAvatar.isNotEmpty
            ? Image.network(
                widget.peerAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(size),
              )
            : _defaultAvatar(size),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      color: Palette.blue.withOpacity(0.1),
      child: Icon(Icons.person_rounded,
          size: size * 0.6, color: Palette.blue.withOpacity(0.6)),
    );
  }

  Widget _buildMessageList() {
    if (!_authReady || groupChatId.isEmpty) {
      return const Center(child: ShimmerIndicator(size: 28));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.getChatStream(groupChatId, _limit),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          listMessage = snapshot.data!.docs;
          if (listMessage.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: listMessage.length,
            reverse: true,
            controller: listScrollController,
            itemBuilder: (context, index) =>
                _buildMessageItem(index, listMessage[index]),
          );
        }
        return const Center(child: ShimmerIndicator(size: 28));
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: Palette.blue.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, AppString.no_message_hereYet).toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Palette.dark_blue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 13,
              color: Palette.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(int index, DocumentSnapshot document) {
    final messageChat = MessageChat.fromDocument(document);
    final isMe = messageChat.idFrom == currentUserId;
    final showTimestamp = isMe ? isLastMessageRight(index) : isLastMessageLeft(index);

    return Padding(
      padding: EdgeInsets.only(bottom: showTimestamp ? 16 : 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (isLastMessageLeft(index))
                  _buildPeerAvatar(28)
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 8),
              ],
              Flexible(child: _buildBubble(messageChat, isMe)),
            ],
          ),
          if (showTimestamp)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 36,
                right: isMe ? 4 : 0,
              ),
              child: Text(
                _formatTimestamp(messageChat.timestamp),
                style: TextStyle(
                  color: Palette.grey.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageChat message, bool isMe) {
    if (message.type == TypeMessage.text) {
      return Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Palette.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Palette.dark_blue,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    } else if (message.type == TypeMessage.image) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FullPhotoPage(url: message.content)),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            child: Image.network(
              message.content,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 220,
                  height: 220,
                  color: Colors.grey.shade100,
                  child: const Center(child: ShimmerIndicator(size: 24)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 220,
                color: Colors.grey.shade100,
                child: const Icon(Icons.broken_image_rounded,
                    size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Image.asset(
        'images/${message.content}.gif',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAttachButton(),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField()),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Palette.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.photo_library_rounded, size: 20),
        color: Palette.blue,
        padding: EdgeInsets.zero,
        onPressed: _showImagePicker,
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: textEditingController,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        style: const TextStyle(color: Palette.dark_blue, fontSize: 15),
        decoration: InputDecoration(
          hintText: getTranslated(context, AppString.type_yourMessage_hint)
              .toString(),
          hintStyle: TextStyle(color: Palette.grey.withOpacity(0.7), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        onSubmitted: (_) =>
            onSendMessage(textEditingController.text, TypeMessage.text),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.blue, Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Palette.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.send_rounded, size: 20),
        color: Colors.white,
        padding: EdgeInsets.zero,
        onPressed: () =>
            onSendMessage(textEditingController.text, TypeMessage.text),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Palette.dark_blue,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: getTranslated(context, AppString.fromCamera)
                        .toString(),
                    onTap: () {
                      Navigator.pop(ctx);
                      getImageFromCamera();
                    },
                  ),
                  _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: getTranslated(context, AppString.fromGallery)
                        .toString(),
                    onTap: () {
                      Navigator.pop(ctx);
                      getImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Palette.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: Palette.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Palette.dark_blue,
            ),
          ),
        ],
      ),
    );
  }
}
