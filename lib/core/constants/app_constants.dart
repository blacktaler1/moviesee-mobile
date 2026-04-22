class AppConstants {
  static const String baseUrl = 'https://moviesee-backend.onrender.com';
  static const String wsBaseUrl = 'wss://moviesee-backend.onrender.com';

  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';

  // WebSocket event types
  static const String evRoomState = 'room_state';
  static const String evSyncState = 'sync_state';
  static const String evUserJoined = 'user_joined';
  static const String evUserLeft = 'user_left';
  static const String evChatMessage = 'chat_message';
  static const String evMuteStatus = 'mute_status';
  static const String evVideoChanged = 'video_changed';
  static const String evWebrtcOffer = 'webrtc_offer';
  static const String evWebrtcAnswer = 'webrtc_answer';
  static const String evWebrtcIce = 'webrtc_ice';
  static const String evError = 'error';

  // Sync tolerance (soniya)
  static const double syncToleranceSeconds = 2.0;
}
