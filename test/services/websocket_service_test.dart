// import 'package:flutter_test/flutter_test.dart';
// import 'package:moviesee/data/services/websocket_service.dart';

// void main() {
//   group('WebSocketService — send helpers', () {
//     late WebSocketService service;

//     setUp(() {
//       service = WebSocketService();
//     });

//     test('sendPlay encodes correct JSON', () {
//       // WebSocketService.send ni mock yordamida ushlab qolish
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendPlay(42.5);

//       expect(sent.length, 1);
//       expect(sent.first['type'], 'play');
//       expect(sent.first['position'], closeTo(42.5, 0.001));
//     });

//     test('sendPause encodes correct JSON', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendPause(100.0);

//       expect(sent.length, 1);
//       expect(sent.first['type'], 'pause');
//       expect(sent.first['position'], closeTo(100.0, 0.001));
//     });

//     test('sendSeek encodes correct JSON', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendSeek(200.0);

//       expect(sent.first['type'], 'seek');
//       expect(sent.first['position'], closeTo(200.0, 0.001));
//     });

//     test('sendChat encodes correct JSON', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendChat('Salom dunyo!');

//       expect(sent.first['type'], 'chat');
//       expect(sent.first['text'], 'Salom dunyo!');
//     });

//     test('sendMute encodes correct JSON', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendMute(true);

//       expect(sent.first['type'], 'mute');
//       expect(sent.first['muted'], isTrue);
//     });

//     test('sendSetVideo encodes correct JSON', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.sendSetVideo('https://archive.org/test.mp4');

//       expect(sent.first['type'], 'set_video');
//       expect(sent.first['url'], 'https://archive.org/test.mp4');
//     });

//     test('requestSync sends correct type', () {
//       final sent = <Map<String, dynamic>>[];
//       service.onSendForTest = sent.add;

//       service.requestSync();

//       expect(sent.first['type'], 'request_sync');
//     });
//   });

//   group('WebSocketService — on() stream routing', () {
//     late WebSocketService service;

//     setUp(() {
//       service = WebSocketService();
//     });

//     tearDown(() {
//       service.dispose();
//     });

//     test('on() delivers only matching event type', () async {
//       final syncEvents = <Map<String, dynamic>>[];
//       final chatEvents = <Map<String, dynamic>>[];

//       service.on('sync_state').listen(syncEvents.add);
//       service.on('chat_message').listen(chatEvents.add);

//       // Ichki stream'ga to'g'ridan-to'g'ri pushлash
//       service.simulateIncomingForTest({'type': 'sync_state', 'position': 10.0, 'playing': true});
//       service.simulateIncomingForTest({'type': 'chat_message', 'text': 'Test', 'username': 'Ali'});
//       service.simulateIncomingForTest({'type': 'sync_state', 'position': 20.0, 'playing': false});

//       // Stream async, bir tick kutish
//       await Future.delayed(Duration.zero);

//       expect(syncEvents.length, 2);
//       expect(chatEvents.length, 1);
//       expect(chatEvents.first['username'], 'Ali');
//     });

//     test('on() with unknown type delivers nothing', () async {
//       final events = <Map<String, dynamic>>[];
//       service.on('unknown_event').listen(events.add);

//       service.simulateIncomingForTest({'type': 'sync_state', 'position': 5.0});
//       await Future.delayed(Duration.zero);

//       expect(events, isEmpty);
//     });
//   });
// }
