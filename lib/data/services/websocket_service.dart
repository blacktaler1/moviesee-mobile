import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  int? _userId;

  void connect(String roomCode, int userId) {
    _userId = userId;
    final uri = Uri.parse('${AppConstants.wsUrl}/ws/room/$roomCode?user_id=$userId');
    appLogger.info('[WS] Connecting: $uri');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) => _onMessage(data as String),
      onError: (e, stack) => appLogger.error('[WS] Error', e, stack as StackTrace),
      onDone: () => appLogger.info('[WS] Disconnected'),
    );
  }

  void _onMessage(String raw) {
    appLogger.debug('[WS] Received: $raw');
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel == null) {
      appLogger.warning('[WS] Send failed: not connected');
      return;
    }
    _channel!.sink.add(jsonEncode(payload));
  }

  void sendWebRtcOffer(int toUserId, String sdp) =>
      _send({'type': 'webrtc_offer', 'to': toUserId, 'sdp': sdp});

  void sendWebRtcAnswer(int toUserId, String sdp) =>
      _send({'type': 'webrtc_answer', 'to': toUserId, 'sdp': sdp});

  void sendWebRtcIce(int toUserId, Map<String, dynamic> candidate) =>
      _send({'type': 'webrtc_ice', 'to': toUserId, 'candidate': candidate});

  void sendMute(bool isMuted) =>
      _send({'type': 'mute', 'is_muted': isMuted, 'from': _userId});

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    appLogger.info('[WS] Disconnected');
  }
}
