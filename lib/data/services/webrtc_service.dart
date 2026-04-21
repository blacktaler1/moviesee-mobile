import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/logger/app_logger.dart';
import 'websocket_service.dart';

/// Ovozli aloqa uchun WebRTC servisi.
/// Har bir remote user uchun alohida RTCPeerConnection saqlanadi.
class WebRtcService {
  final WebSocketService _ws;
  final int localUserId;

  /// user_id → RTCPeerConnection (ko'p foydalanuvchi uchun)
  final Map<int, RTCPeerConnection> _peerConnections = {};
  MediaStream? _localStream;
  bool _isMuted = false;

  final _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  WebRtcService(this._ws, {required this.localUserId});

  bool get isMuted => _isMuted;

  Future<void> initialize() async {
    try {
      appLogger.info('[WebRTC] Mikrofon ruxsati so\'ralmoqda...');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      final trackCount = _localStream?.getAudioTracks().length ?? 0;
      appLogger.info('[WebRTC] Mikrofon tayyor: $trackCount audio track');
    } catch (e, stack) {
      // Ruxsat berilmagan bo'lsa — ilovani to'xtatmaymiz, chat/video ishlayveradi
      appLogger.error('[WebRTC] Mikrofon xatosi (ruxsat yo\'q yoki qurilma topilmadi)', e, stack);
    }
  }

  /// Yangi foydalanuvchi ulanganda BIZ offer yuboramiz
  Future<void> createOffer(int remoteUserId) async {
    appLogger.info('[WebRTC] createOffer → remoteUser=$remoteUserId');
    try {
      final pc = await _getOrCreatePeerConnection(remoteUserId);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _ws.sendWebRtcOffer(remoteUserId, offer.sdp!);
      appLogger.info('[WebRTC] Offer yuborildi → user=$remoteUserId');
    } catch (e, stack) {
      appLogger.error('[WebRTC] createOffer xatosi', e, stack);
    }
  }

  /// Boshqa foydalanuvchidan offer kelganda — answer qaytaramiz
  Future<void> handleOffer(int fromUserId, String sdp) async {
    appLogger.info('[WebRTC] handleOffer ← fromUser=$fromUserId');
    try {
      final pc = await _getOrCreatePeerConnection(fromUserId);
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _ws.sendWebRtcAnswer(fromUserId, answer.sdp!);
      appLogger.info('[WebRTC] Answer yuborildi → user=$fromUserId');
    } catch (e, stack) {
      appLogger.error('[WebRTC] handleOffer xatosi', e, stack);
    }
  }

  /// Answer kelganda — qaysi user dan kelganini bilamiz (fromUserId)
  Future<void> handleAnswer(int fromUserId, String sdp) async {
    appLogger.info('[WebRTC] handleAnswer ← fromUser=$fromUserId');
    final pc = _peerConnections[fromUserId];
    if (pc == null) {
      appLogger.warning('[WebRTC] handleAnswer: user=$fromUserId uchun peerConnection yo\'q!');
      return;
    }
    try {
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    } catch (e, stack) {
      appLogger.error('[WebRTC] handleAnswer xatosi', e, stack);
    }
  }

  /// ICE candidate kelganda — to'g'ri peer connectioni topamiz
  Future<void> handleIceCandidate(int fromUserId, Map<String, dynamic> candidate) async {
    final pc = _peerConnections[fromUserId];
    if (pc == null) {
      appLogger.warning('[WebRTC] handleIceCandidate: user=$fromUserId uchun peerConnection yo\'q!');
      return;
    }
    try {
      await pc.addCandidate(RTCIceCandidate(
        candidate['candidate'] as String,
        candidate['sdpMid'] as String,
        candidate['sdpMLineIndex'] as int,
      ));
    } catch (e, stack) {
      appLogger.error('[WebRTC] handleIceCandidate xatosi', e, stack);
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    _ws.sendMute(_isMuted);
    appLogger.info('[WebRTC] Mute toggled: $_isMuted');
  }

  /// Mavjud bo'lsa qaytaradi, yo'q bo'lsa yangi yaratadi
  Future<RTCPeerConnection> _getOrCreatePeerConnection(int remoteUserId) async {
    if (_peerConnections.containsKey(remoteUserId)) {
      return _peerConnections[remoteUserId]!;
    }

    appLogger.info('[WebRTC] Yangi peerConnection: user=$remoteUserId');
    final pc = await createPeerConnection(_configuration);
    _peerConnections[remoteUserId] = pc;

    // Local audio track'larni qo'shamiz
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
      appLogger.info('[WebRTC] Local tracks qo\'shildi: user=$remoteUserId');
    }

    // Remote audio/video kelganda o'ynatish
    // flutter_webrtc audio tracklarni avtomatik o'ynatadi
    pc.onTrack = (event) {
      appLogger.info('[WebRTC] Remote track keldi: user=$remoteUserId, kind=${event.track.kind}');
    };

    // ICE candidate serverga yuborish
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _ws.sendWebRtcIce(remoteUserId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // Ulanish holati logga
    pc.onConnectionState = (state) {
      appLogger.info('[WebRTC] Connection state: user=$remoteUserId → $state');
    };

    return pc;
  }

  void dispose() {
    for (final entry in _peerConnections.entries) {
      appLogger.info('[WebRTC] PeerConnection yopilmoqda: user=${entry.key}');
      entry.value.close();
    }
    _peerConnections.clear();
    _localStream?.dispose();
    appLogger.info('[WebRTC] dispose() tugadi');
  }
}
