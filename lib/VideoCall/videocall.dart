import 'dart:async';
import 'package:doctro_patient/security/consultation_session_client.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip_view/pip_view.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:provider/provider.dart';

import 'package:doctro_patient/Screen/Screens/Home.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:doctro_patient/VideoCall/overlay_handler.dart';
import 'package:doctro_patient/VideoCall/overlay_service.dart';
import 'package:doctro_patient/api/base_model.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/server_error.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/user_detail_model.dart';
import 'package:doctro_patient/model/video_call_model.dart';

class VideoCall extends StatefulWidget {
  final int? doctorId;
  final String? flag;

  final int? appointmentId;
  final ConsultationSessionClient? sessionClient;

  VideoCall({this.doctorId, this.flag, this.appointmentId, this.sessionClient});

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool muted = false;
  bool mutedVideo = false;
  RtcEngine? _engine;
  String? appId = SharedPreferenceHelper.getString(Preferences.agoraAppId);
  String? token = "";
  String? channelName = "";
  int? callDuration = 0;
  bool? timeOut = false;
  int uid = 0;
  ChannelMediaOptions options = const ChannelMediaOptions(
    clientRoleType: ClientRoleType.clientRoleBroadcaster,
    channelProfile: ChannelProfileType.channelProfileCommunication,
  );

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null || widget.sessionClient != null) {
      unawaited(_startAppointmentSession());
    } else if (widget.flag == "InComming") {
      callApiUserProfile();
    } else if (widget.flag == "Cut") {
      callApiUserProfile();
    } else {
      callApiVideoCallToken();
    }
    offset = const Offset(20.0, 50.0);
  }

  Offset offset = Offset.zero;

  Widget _toolbar() {
    return Consumer<OverlayHandlerProvider>(
      builder: (context, overlayProvider, _) {
        return Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.symmetric(vertical: overlayProvider.inPipMode == true ? 20 : 45),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Palette.white : Palette.blue,
                    size: overlayProvider.inPipMode == true ? 12.0 : 15.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Palette.blue : Palette.white,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 12.0),
                ),
              ),
              Expanded(
                child: RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  child: Icon(
                    Icons.call_end,
                    color: Palette.white,
                    size: overlayProvider.inPipMode == true ? 15.0 : 30.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Palette.red,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 15.0),
                ),
              ),
              Expanded(
                child: RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: Palette.blue,
                    size: overlayProvider.inPipMode == true ? 12.0 : 15.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Palette.white,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 12.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? callTime = "";
  String? callDate = "";

  bool _isDisposed = false;
  bool _isEnding = false;
  bool _leaveRequested = false;
  bool _released = false;
  bool _handledLeave = false;
  Timer? _leaveTimeoutTimer;
  Timer? _renewalTimer;
  ConsultationCredentials? _credentials;
  bool _renewing = false;
  Timer? _statusTimer;
  bool _checkingStatus = false;
  bool _statusWarningShown = false;

  void _scheduleStatusCheck() {
    _statusTimer?.cancel();
    if (_isDisposed || _isEnding || _credentials == null) return;
    _statusTimer = Timer(const Duration(seconds: 15), () {
      unawaited(_checkSessionStatus());
    });
  }

  Future<void> _checkSessionStatus() async {
    final credentials = _credentials;
    final client = widget.sessionClient;
    final id = widget.appointmentId;
    if (_checkingStatus || _isDisposed || _isEnding ||
        credentials == null || client == null || id == null) return;
    _checkingStatus = true;
    try {
      final state = await client.status(id, expectedSessionId: credentials.sessionId);
      if (_isDisposed || _isEnding) return;
      _statusWarningShown = false;
      if (state != 'active') {
        Fluttertoast.showToast(msg: 'Consultation has ended.');
        _requestEndCall(reason: 'server_closed');
      }
    } on ConsultationAccessRevoked {
      if (!_isDisposed && !_isEnding) {
        Fluttertoast.showToast(msg: 'Consultation access ended.');
        _requestEndCall(reason: 'access_revoked');
      }
    } on FormatException {
      if (!_isDisposed && !_isEnding) {
        _requestEndCall(reason: 'invalid_session');
      }
    } catch (_) {
      if (!_isDisposed && !_isEnding && !_statusWarningShown) {
        _statusWarningShown = true;
        Fluttertoast.showToast(msg: 'Unable to verify consultation status. Retrying.');
      }
    } finally {
      _checkingStatus = false;
      _scheduleStatusCheck();
    }
  }

  Future<void> _notifySessionEnd() async {
    final client = widget.sessionClient;
    final id = widget.appointmentId;
    if (_credentials == null || client == null || id == null) return;
    try {
      await client.end(id);
    } catch (_) {
      if (mounted && !_isDisposed) {
        Fluttertoast.showToast(msg: 'Call closed locally. Server confirmation unavailable.');
      }
    }
  }

  void _scheduleRenewal() {
    _renewalTimer?.cancel();
    final credentials = _credentials;
    if (credentials == null || _isDisposed || _isEnding) return;
    final remaining = credentials.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _requestEndCall(reason: 'credential_expiry');
      return;
    }
    final delay = remaining - const Duration(seconds: 60);
    final wait = delay > const Duration(seconds: 10) ? delay : const Duration(seconds: 10);
    _renewalTimer = Timer(wait < remaining ? wait : remaining, () {
      unawaited(_renewCredentials());
    });
  }

  Future<void> _renewCredentials() async {
    final client = widget.sessionClient;
    final previous = _credentials;
    final engine = _engine;
    if (client == null || previous == null || engine == null || _renewing || _isDisposed || _isEnding) return;
    if (!previous.expiresAt.isAfter(DateTime.now())) {
      _requestEndCall(reason: 'credential_expiry');
      return;
    }
    _renewing = true;
    try {
      final next = await client.credentials(widget.appointmentId!, previous: previous);
      if (_isDisposed || _isEnding || _engine != engine) return;
      if (!next.expiresAt.isAfter(previous.expiresAt)) {
        _scheduleRenewal();
        return;
      }
      await engine.renewToken(next.token).timeout(const Duration(seconds: 10));
      if (_isDisposed || _isEnding) return;
      _credentials = next;
      _scheduleRenewal();
    } on ConsultationAccessRevoked {
      if (!_isDisposed && !_isEnding) _requestEndCall(reason: 'access_revoked');
    } on FormatException {
      if (!_isDisposed && !_isEnding) _requestEndCall(reason: 'invalid_session');
    } catch (_) {
      if (_isDisposed || _isEnding) return;
      if (previous.expiresAt.difference(DateTime.now()).inSeconds <= 20) {
        Fluttertoast.showToast(msg: 'Secure consultation expired.');
        _requestEndCall(reason: 'credential_expiry');
      } else {
        _renewalTimer?.cancel();
        _renewalTimer = Timer(const Duration(seconds: 10), () => unawaited(_renewCredentials()));
      }
    } finally {
      _renewing = false;
    }
  }

  Future<void> _startAppointmentSession() async {
    try {
      final id = widget.appointmentId;
      if (id == null || id <= 0 || widget.sessionClient == null) throw StateError('Missing session configuration');
      final credentials = await widget.sessionClient!.credentials(id);
      if (!mounted || _isDisposed || _isEnding) return;
      if (credentials.uid != 1) throw StateError('Invalid patient identity');
      _credentials = credentials;
      token = credentials.token;
      channelName = credentials.channel;
      appId = credentials.appId;
      uid = credentials.uid;
      await initAgora();
      if (!_isDisposed && !_isEnding && _engine != null) {
        _scheduleRenewal();
        _scheduleStatusCheck();
      }
    } catch (_) {
      if (mounted && !_isDisposed) Fluttertoast.showToast(msg: 'Secure consultation unavailable.');
      await _releaseEngineOnce();
    }
  }



  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  Future<void> _leaveChannelOnce() async {
    if (_leaveRequested) return;
    _leaveRequested = true;

    final engine = _engine;
    if (engine == null) return;

    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!_released) unawaited(_releaseEngineOnce());
    });
    try {
      await engine.stopPreview();
    } catch (_) {}

    try {
      await engine.leaveChannel();
    } catch (_) {}
  }

  Future<void> _releaseEngineOnce() async {
    if (_released) return;
    _released = true;

    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    final engine = _engine;
    _engine = null;
    if (engine == null) return;

    try {
      await engine.release();
    } catch (_) {}
  }

  void _requestEndCall({String reason = 'user'}) {
    if (_isEnding) return;
    _isEnding = true;
    _renewalTimer?.cancel();
    _statusTimer?.cancel();
    if (reason == 'user') unawaited(_notifySessionEnd());

    _safeSetState(() {
      _localUserJoined = false;
      _remoteUid = null;
    });

    if (widget.appointmentId != null && _engine == null && mounted) {
      Navigator.of(context).pop();
      return;
    }
    unawaited(_leaveChannelOnce());
  }

  void _onCallEnd(BuildContext context) {
    _requestEndCall();
  }

  void _onToggleMute() {
    _safeSetState(() {
      muted = !muted;
    });
    _engine?.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    if (!_isEnding && !_isDisposed && !mutedVideo) _engine?.switchCamera();
  }

  Future<void> initAgora() async {
    final grants = await [Permission.microphone, Permission.camera].request();
    if (!mounted || _isDisposed || _isEnding) return;
    if (grants[Permission.microphone]?.isGranted != true) {
      Fluttertoast.showToast(msg: 'Microphone permission is required.');
      return;
    }
    final cameraGranted = grants[Permission.camera]?.isGranted == true;

    final resolvedAppId = (appId ?? '').trim();
    if (resolvedAppId.isEmpty || (channelName ?? '').trim().isEmpty ||
        (token ?? '').trim().isEmpty || token == 'null') {
      debugPrint('Agora init skipped: missing appId');
      return;
    }

    final engine = await createAgoraRtcEngine();
    if (!mounted || _isDisposed || _isEnding) {
      await engine.release();
      return;
    }
    _engine = engine;
    _leaveRequested = false;
    _released = false;
    _handledLeave = false;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    await engine.initialize(RtcEngineContext(appId: resolvedAppId));
    if (_isDisposed || _isEnding || _engine != engine) return;
    await engine.enableVideo();
    if (_isDisposed || _isEnding || _engine != engine) return;
    if (!cameraGranted) {
      await engine.enableLocalVideo(false);
      mutedVideo = true;
    }

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (_isDisposed || _isEnding) return;
          _safeSetState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (_isDisposed || _isEnding || (_credentials != null && remoteUid != 2)) return;
          DateTime now = DateTime.now();
          callTime = DateFormat('h:mm a').format(now);
          callDate = DateFormat('yyyy-MM-dd').format(now);
          _safeSetState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          if (_isDisposed || _isEnding || remoteUid != _remoteUid) return;
          _safeSetState(() {
            _remoteUid = null;
          });
          Fluttertoast.showToast(msg: "Call Ended",toastLength: Toast.LENGTH_SHORT);
          _requestEndCall(reason: 'remote_offline');
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          if (_credentials != null) unawaited(_renewCredentials());
        },
        onLeaveChannel: (RtcConnection connection, RtcStats detail) {
          if (_handledLeave) return;
          _handledLeave = true;
          _isEnding = true;
          _renewalTimer?.cancel();
          _statusTimer?.cancel();

          _leaveTimeoutTimer?.cancel();
          _leaveTimeoutTimer = null;

          if (widget.appointmentId != null) {
            if (mounted && !_isDisposed && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
            unawaited(_releaseEngineOnce());
            return;
          }
          if (widget.flag == "InComming") {
            callDuration = detail.duration;
            _safeSetState(() {});
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
            }
          } else if (widget.flag == "Cut") {
            callDuration = detail.duration;
            _safeSetState(() {});
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
            }
          } else {
            callDuration = detail.duration;
            _safeSetState(() {});
            if (mounted) {
              OverlayService().removeVideosOverlay(context, VideoCall(doctorId: widget.doctorId));
            }
          }

          // Release only after leave callback to avoid native race/crash.
          unawaited(_releaseEngineOnce());
        },
      ),
    );

    if (cameraGranted) await engine.startPreview();
    if (_isDisposed || _isEnding || _engine != engine) return;

    final joinChannelId = (channelName ?? '').trim();
    if (joinChannelId.isEmpty) {
      debugPrint('Agora join skipped (patient): missing channelName');
      Fluttertoast.showToast(msg: 'Unable to start video call. Please try again.');
      return;
    }

    final joinToken = (token == null || token!.isEmpty || token!.toLowerCase() == 'null') ? '' : token!;

    await engine.joinChannel(
      token: joinToken,
      channelId: joinChannelId,
      uid: uid,
      options: options,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;
    _renewalTimer?.cancel();
    _statusTimer?.cancel();
    unawaited(_leaveChannelOnce().whenComplete(_releaseEngineOnce));
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return PIPView(
      builder: (context, isFloating) {
        return Scaffold(
          body: Consumer<OverlayHandlerProvider>(
            builder: (context, overlayProvider, _) {
              return InkWell(
                onTap: () {
                  Provider.of<OverlayHandlerProvider>(context, listen: false).disablePip();
                },
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: _remoteVideo(),
                      ),
                    ),
                    widget.flag == "Cut"
                        ? Container()
                        : Stack(
                      children: [
                        Positioned(
                          left: offset.dx,
                          top: offset.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                if (offset.dx > 0.0 && (offset.dx + 150) < width && offset.dy > 0.0 && (offset.dy + 200) < height) {
                                  offset = Offset(offset.dx + details.delta.dx, offset.dy + details.delta.dy);
                                } else {
                                  offset = Offset(details.delta.dx + 20, details.delta.dy + 50);
                                }
                              });
                            },
                            child: Consumer<OverlayHandlerProvider>(
                              builder: (context, overlayProvider, _) {
                                return SizedBox(
                                  width: overlayProvider.inPipMode == true ? 80 : 150,
                                  height: overlayProvider.inPipMode == true ? 80 : 200,
                                  child: Center(
                                    child: _localUserJoined
                                        ? _localPreview()
                                        : ShimmerIndicator(size: 24),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    _toolbar(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _localPreview() {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _remoteVideo() {
    final engine = _engine;
    if (_remoteUid != null && engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    } else {
      if (widget.flag == "InComming") {
        return ScalingText(
          'Connecting...',
          style: TextStyle(fontSize: 16, color: Palette.dark_blue),
        );
      } else if (widget.flag == "Cut") {
        return ScalingText(
          'Call Ended...',
          style: TextStyle(fontSize: 16, color: Palette.dark_blue),
        );
      } else {
        return ScalingText(
          'Ringing...',
          style: TextStyle(fontSize: 16, color: Palette.dark_blue),
        );
      }
    }
  }

  Future<BaseModel<VideoCallModel>> callApiVideoCallToken() async {
    VideoCallModel response;
    Map<String, dynamic> body = {
      "to_id": widget.doctorId,
    };
    try {
      response = await RestClient(RetroApi().dioData()).videoCallRequest(body);
      if (response.success == true && !_isDisposed && !_isEnding) {
        channelName = response.data!.cn;
        token = response.data!.token;
        await initAgora();
      }
      _safeSetState(() {});
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<UserDetail>> callApiUserProfile() async {
    UserDetail response;
    try {
      response = await RestClient(RetroApi().dioData()).userDetailRequest();
      if(response.status == 1 && !_isDisposed && !_isEnding){
        channelName = response.channelName!;
        token = response.agoraToken;
        await initAgora();
      }
      _safeSetState(() {});
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
