import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _controllers = <String, StreamController<Map<String, dynamic>>>{};
  StreamSubscription? _subscription;

  bool get isConnected => _channel != null;

  void connect(String roomCode, String token) {
    final url = '${AppConstants.wsBaseUrl}/ws/$roomCode?token=$token';
    dev.log('[WS] Ulanish boshlandi: $url');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
      dev.log('[WS] WebSocket ulandi: room=$roomCode');
    } catch (e) {
      dev.log('[WS] Ulanishda xato: $e');
    }
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type != null) {
        _controllers[type]?.add(data);
        _controllers['*']?.add(data);
      }
    } catch (e) {
      dev.log('[WS] JSON parse xato: $e | raw: $raw');
    }
  }

  void _onError(dynamic error) {
    dev.log('[WS] WebSocket xato: $error');
    _controllers['__error']?.add({'type': '__error', 'message': error.toString()});
  }

  void _onDone() {
    dev.log('[WS] WebSocket yopildi');
    _controllers['__done']?.add({'type': '__done'});
  }

  Stream<Map<String, dynamic>> on(String eventType) {
    _controllers.putIfAbsent(eventType, () => StreamController.broadcast());
    return _controllers[eventType]!.stream;
  }

  void Function(Map<String, dynamic>)? _testSendHandler;

  // ignore: avoid_setters_without_getters
  set onSendForTest(void Function(Map<String, dynamic>) handler) {
    _testSendHandler = handler;
  }

  void send(Map<String, dynamic> data) {
    if (_testSendHandler != null) {
      _testSendHandler!(data);
      return;
    }
    if (_channel == null) {
      dev.log('[WS] Channel null — yuborib bo\'lmadi!');
      return;
    }
    _channel?.sink.add(jsonEncode(data));
  }

  void simulateIncomingForTest(Map<String, dynamic> event) =>
      _onData(jsonEncode(event));

  void sendPlay(double position) =>
      send({'type': 'play', 'position': position});

  void sendPause(double position) =>
      send({'type': 'pause', 'position': position});

  void sendSeek(double position) =>
      send({'type': 'seek', 'position': position});

  void sendChat(String text) =>
      send({'type': 'chat', 'text': text});

  void sendMute(bool muted) =>
      send({'type': 'mute', 'muted': muted});

  void sendSetVideo(String url) =>
      send({'type': 'set_video', 'url': url});

  void requestSync() =>
      send({'type': 'request_sync'});

  void sendWebRtcOffer(int toUserId, String sdp) =>
      send({'type': 'webrtc_offer', 'to_user': toUserId, 'sdp': sdp});

  void sendWebRtcAnswer(int toUserId, String sdp) =>
      send({'type': 'webrtc_answer', 'to_user': toUserId, 'sdp': sdp});

  void sendWebRtcIce(int toUserId, Map<String, dynamic> candidate) =>
      send({'type': 'webrtc_ice', 'to_user': toUserId, 'candidate': candidate});

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _channel = null;
  }
}
