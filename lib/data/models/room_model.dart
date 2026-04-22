class RoomModel {
  final int id;
  final String code;
  final String name;
  final int hostId;
  final String? videoUrl;
  final double currentPosition;
  final bool isPlaying;

  const RoomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.hostId,
    this.videoUrl,
    required this.currentPosition,
    required this.isPlaying,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        hostId: json['host_id'] as int,
        videoUrl: json['video_url'] as String?,
        currentPosition: (json['current_position'] as num).toDouble(),
        isPlaying: json['is_playing'] as bool,
      );
}

class ChatMessage {
  final int userId;
  final String username;
  final String text;
  final String time;

  const ChatMessage({
    required this.userId,
    required this.username,
    required this.text,
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        userId: json['user_id'] as int,
        username: json['username'] as String,
        text: json['text'] as String,
        time: json['time'] as String,
      );
}

class RoomUser {
  final int userId;
  final String username;
  final bool muted;

  const RoomUser({
    required this.userId,
    required this.username,
    required this.muted,
  });

  factory RoomUser.fromJson(Map<String, dynamic> json) => RoomUser(
        userId: json['user_id'] as int,
        username: json['username'] as String,
        muted: json['muted'] as bool? ?? false,
      );
}
