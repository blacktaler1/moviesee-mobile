import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:moviesee/data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/models/room_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/webrtc_service.dart';
import '../../widgets/chat_overlay.dart';
import '../../widgets/room_users_bar.dart';

class PlayerScreen extends StatefulWidget {
  final String roomCode;
  const PlayerScreen({super.key, required this.roomCode});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _ws = WebSocketService();
  late WebRtcService _webrtc;

  late final Player _player;
  late final VideoController _videoController;
  final _videoUrlCtrl = TextEditingController();
  bool _playerReady = false;
  bool _isSyncing = false;

  List<RoomUser> _users = [];
  List<ChatMessage> _messages = [];
  bool _isMuted = false;
  bool _showChat = false;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _init();
  }

  Future<void> _init() async {
    final user = await StorageService.getUser();
    final token = await StorageService.getToken();
    if (user == null || token == null) return;

    // Play Market talabi: WebRTC dan oldin ruxsat so'rash
    if (mounted) await PermissionService.requestMicrophone(context);

    _webrtc = WebRtcService(_ws, localUserId: user.id);
    await _webrtc.initialize();

    _ws.connect(widget.roomCode, token);
    _listenEvents();
  }

  void _listenEvents() {
    _subs.add(_ws.on(AppConstants.evRoomState).listen((e) {
      setState(() {
        _users = (e['users'] as List)
            .map((u) => RoomUser.fromJson(u as Map<String, dynamic>))
            .toList();
      });
      final videoUrl = e['video_url'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final pos = (e['position'] as num).toDouble();
        final playing = e['playing'] as bool;
        _loadUrlSmart(videoUrl, startPosition: pos, playing: playing);
      }
    }));

    _subs.add(_ws.on(AppConstants.evSyncState).listen((e) async {
      if (!_playerReady || _isSyncing) return;
      final serverTime = (e['server_time'] as num).toDouble();
      final position = (e['position'] as num).toDouble();
      final playing = e['playing'] as bool;
      final latency =
          (DateTime.now().millisecondsSinceEpoch / 1000) - serverTime;
      await _syncPlayer(position + (latency / 2), playing);
    }));

    _subs.add(_ws.on(AppConstants.evVideoChanged).listen((e) {
      final url = e['url'] as String?;
      if (url != null) {
        final playing = e['playing'] as bool? ?? true;
        final position = (e['position'] as num?)?.toDouble() ?? 0.0;
        _loadUrlSmart(url, startPosition: position, playing: playing);
      }
    }));

    _subs.add(_ws.on(AppConstants.evChatMessage).listen((e) {
      setState(() {
        _messages.add(ChatMessage.fromJson(e));
        if (_messages.length > 200) _messages.removeAt(0);
      });
    }));

    _subs.add(_ws.on(AppConstants.evUserJoined).listen((e) {
      final newUserId = e['user_id'] as int;
      final newUsername = e['username'] as String;
      setState(() => _users.add(RoomUser(
            userId: newUserId,
            username: newUsername,
            muted: false,
          )));
      appLogger.info('[PLAYER] Yangi user: $newUsername — WebRTC offer');
      _webrtc.createOffer(newUserId);
    }));

    _subs.add(_ws.on(AppConstants.evUserLeft).listen((e) {
      final uid = e['user_id'] as int;
      setState(() => _users.removeWhere((u) => u.userId == uid));
    }));

    _subs.add(_ws.on(AppConstants.evMuteStatus).listen((e) {
      final uid = e['user_id'] as int;
      final muted = e['muted'] as bool;
      setState(() {
        final i = _users.indexWhere((u) => u.userId == uid);
        if (i != -1) {
          _users[i] = RoomUser(
            userId: _users[i].userId,
            username: _users[i].username,
            muted: muted,
          );
        }
      });
    }));

    _subs.add(_ws.on(AppConstants.evWebrtcOffer).listen((e) async {
      await _webrtc.handleOffer(e['from_user'] as int, e['sdp'] as String);
    }));
    _subs.add(_ws.on(AppConstants.evWebrtcAnswer).listen((e) async {
      await _webrtc.handleAnswer(e['from_user'] as int, e['sdp'] as String);
    }));
    _subs.add(_ws.on(AppConstants.evWebrtcIce).listen((e) async {
      await _webrtc.handleIceCandidate(
        e['from_user'] as int,
        e['candidate'] as Map<String, dynamic>,
      );
    }));
  }

  Future<void> _loadVideo(
    String url, {
    double startPosition = 0,
    bool playing = false,
    Map<String, String>? httpHeaders,
  }) async {
    try {
      await _player.open(Media(url, httpHeaders: httpHeaders), play: false);
      if (startPosition > 0) {
        await _player
            .seek(Duration(milliseconds: (startPosition * 1000).toInt()));
      }
      if (playing) await _player.play();
      if (mounted) setState(() => _playerReady = true);
    } catch (e, stack) {
      appLogger.error('[PLAYER] _loadVideo xato', e, stack);
      rethrow;
    }
  }

  Future<void> _syncPlayer(double position, bool playing) async {
    _isSyncing = true;
    try {
      final currentSec = _player.state.position.inMilliseconds / 1000.0;
      if ((currentSec - position).abs() > AppConstants.syncToleranceSeconds) {
        await _player
            .seek(Duration(milliseconds: (position * 1000).toInt()));
      }
      if (playing && !_player.state.playing) {
        await _player.play();
      } else if (!playing && _player.state.playing) {
        await _player.pause();
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _onPlay() {
    _ws.sendPlay(_player.state.position.inMilliseconds / 1000.0);
    _player.play();
  }

  void _onPause() {
    _ws.sendPause(_player.state.position.inMilliseconds / 1000.0);
    _player.pause();
  }

  void _onSeek(double seconds) {
    _ws.sendSeek(seconds);
    _player.seek(Duration(milliseconds: (seconds * 1000).toInt()));
  }

  void _toggleMute() {
    _webrtc.toggleMute();
    setState(() => _isMuted = _webrtc.isMuted);
  }

  void _showSetVideoDialog() {
    _videoUrlCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VideoUrlSheet(
        controller: _videoUrlCtrl,
        onSubmit: (url) async {
          Navigator.pop(ctx);
          await _handleUrlSubmit(url);
        },
      ),
    );
  }

  Future<void> _handleUrlSubmit(String url) async {
    if (url.isEmpty) return;
    if (_isDirectMediaUrl(url) || _isPlayableUrl(url)) {
      await _loadVideoFromUrl(url);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Video variantlari aniqlanmoqda…'),
        ]),
        duration: Duration(seconds: 60),
        backgroundColor: Color(0xFF2D2D44),
      ));
    }
    try {
      final options = await ApiService.extractVideoOptions(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (options.length <= 1) {
        await _loadVideoFromUrl(
            options.isNotEmpty ? (options[0]['source_url'] as String) : url);
      } else {
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A2E),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => _VideoSelectionSheet(
              options: options,
              onSelect: (sourceUrl) async {
                Navigator.pop(ctx);
                await _loadVideoFromUrl(sourceUrl);
              },
            ),
          );
        }
      }
    } catch (e, stack) {
      appLogger.error('[PLAYER] extractVideoOptions xato', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _loadVideoFromUrl(url);
      }
    }
  }

  Future<void> _loadVideoFromUrl(String url, {bool broadcast = true}) async {
    if (url.isEmpty) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Video ma\'lumotlari yuklanmoqda…'),
        ]),
        duration: Duration(seconds: 60),
        backgroundColor: Color(0xFF2D2D44),
      ));
    }
    try {
      String streamUrl = url;
      String? title;
      Map<String, String>? httpHeaders;

      if (!_isDirectMediaUrl(url)) {
        final info = await ApiService.extractVideoUrl(url);
        streamUrl = info['stream_url'] as String;
        title = info['title'] as String?;
        final rawHeaders = info['headers'] as Map<String, dynamic>?;
        httpHeaders = rawHeaders?.map((k, v) => MapEntry(k, v.toString()));
      }

      if (broadcast) _ws.sendSetVideo(streamUrl);
      await _loadVideo(streamUrl, httpHeaders: httpHeaders, playing: true);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (title != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('▶  $title'),
            backgroundColor: const Color(0xFF16213E),
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } catch (e, stack) {
      appLogger.error('[PLAYER] _loadVideoFromUrl xato', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Xato: ${_friendlyError(e)}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 8),
        ));
      }
    }
  }

  void _loadUrlSmart(String url,
      {double startPosition = 0, bool playing = false}) {
    if (_isPlayableUrl(url)) {
      _loadVideo(url, startPosition: startPosition, playing: playing)
          .catchError((e, stack) {
        appLogger.error('[PLAYER] _loadUrlSmart xato', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Video yuklanmadi: ${_friendlyError(e)}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ));
        }
      });
    } else {
      _loadVideoFromUrl(url, broadcast: false);
    }
  }

  bool _isPlayableUrl(String url) {
    if (_isDirectMediaUrl(url)) return true;
    if (url.startsWith(AppConstants.baseUrl)) return true;
    return false;
  }

  bool _isDirectMediaUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return ['.mp4', '.mkv', '.m3u8', '.mpd', '.webm', '.avi', '.ts']
        .any((ext) => lower.endsWith(ext));
  }

  String _friendlyError(Object e) {
    if (e is VideoExtractionException) return e.userMessage;
    if (e is NetworkException) return e.userMessage;
    if (e is UnauthorizedException) return e.userMessage;
    if (e is ServerException) return e.userMessage;
    if (e is AppException) return e.message;
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Serverga ulanib bo\'lmadi (${AppConstants.baseUrl})';
    }
    if (msg.contains('Connection refused')) return 'Backend ishlamayapti';
    if (msg.contains('timeout')) return 'Vaqt tugadi — keyinroq urinib ko\'ring';
    return msg.length > 150 ? '${msg.substring(0, 150)}...' : msg;
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _ws.dispose();
    _webrtc.dispose();
    _player.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  roomCode: widget.roomCode,
                  onSetVideo: _showSetVideoDialog,
                  onBack: () => context.go('/home'),
                ),
                Expanded(
                  child: _playerReady
                      ? Video(controller: _videoController)
                      : _NoVideoPlaceholder(onTap: _showSetVideoDialog),
                ),
                if (_playerReady)
                  StreamBuilder(
                    stream: _player.stream.position,
                    builder: (_, posSnap) => StreamBuilder(
                      stream: _player.stream.duration,
                      builder: (_, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;
                        return Column(
                          children: [
                            _ProgressBar(
                                position: pos, duration: dur, onSeek: _onSeek),
                            StreamBuilder(
                              stream: _player.stream.playing,
                              builder: (_, playSnap) => _PlayerControls(
                                isPlaying: playSnap.data ?? false,
                                isMuted: _isMuted,
                                showChat: _showChat,
                                onPlay: _onPlay,
                                onPause: _onPause,
                                onToggleMute: _toggleMute,
                                onToggleChat: () =>
                                    setState(() => _showChat = !_showChat),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                RoomUsersBar(users: _users),
              ],
            ),
            if (_showChat)
              Positioned(
                right: 0,
                top: 56,
                bottom: 160,
                width: MediaQuery.of(context).size.width * 0.85,
                child: ChatOverlay(
                  messages: _messages,
                  onSend: (text) => _ws.sendChat(text),
                  onClose: () => setState(() => _showChat = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoUrlSheet extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String url) onSubmit;
  const _VideoUrlSheet({required this.controller, required this.onSubmit});

  @override
  State<_VideoUrlSheet> createState() => _VideoUrlSheetState();
}

class _VideoUrlSheetState extends State<_VideoUrlSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            const Text('Video URL kiriting',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _SupportChip(icon: Icons.play_circle_rounded, label: 'YouTube'),
              _SupportChip(icon: Icons.movie_rounded, label: 'uzmovi.tv'),
              _SupportChip(icon: Icons.link_rounded, label: '.mp4 / .m3u8'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            autofocus: true,
            enabled: !_loading,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://youtube.com/watch?v=... yoki to\'g\'ridan URL',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.link_rounded, color: Color(0xFF6C63FF)),
              filled: true,
              fillColor: const Color(0xFF252540),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final url = widget.controller.text.trim();
                      if (url.isEmpty) return;
                      setState(() => _loading = true);
                      await widget.onSubmit(url);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: const Color(0xFF3A3A5C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Videoni Yuklash',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSelectionSheet extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Future<void> Function(String sourceUrl) onSelect;
  const _VideoSelectionSheet({required this.options, required this.onSelect});

  String _fmtDuration(dynamic dur) {
    if (dur == null) return '';
    final secs = (dur as num).toInt();
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            const Text('Video tanlang',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
            const Spacer(),
            Text('${options.length} ta variant',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final title = opt['title'] as String? ?? 'Video';
            final sourceUrl = opt['source_url'] as String;
            final thumbnail = opt['thumbnail'] as String?;
            final durStr = _fmtDuration(opt['duration']);
            return GestureDetector(
              onTap: () => onSelect(sourceUrl),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252540),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumbnail != null
                          ? Image.network(thumbnail,
                              width: 80,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbPlaceholder())
                          : _thumbPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (durStr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(durStr,
                                style: const TextStyle(
                                    color: Color(0xFF8B83FF), fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_outline_rounded,
                        color: Color(0xFF6C63FF), size: 28),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 80,
        height: 50,
        color: const Color(0xFF1A1A2E),
        child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 24),
      );
}

class _SupportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SupportChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF252540),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8B83FF)),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(color: Color(0xFFB0A8FF), fontSize: 12)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String roomCode;
  final VoidCallback onSetVideo;
  final VoidCallback onBack;
  const _TopBar(
      {required this.roomCode,
      required this.onSetVideo,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black87,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MovieSee',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Xona: $roomCode',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_link_rounded, color: Colors.white70),
            onPressed: onSetVideo,
            tooltip: 'Video URL',
          ),
        ],
      ),
    );
  }
}

class _NoVideoPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _NoVideoPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const ColoredBox(
        color: Color(0xFF0A0A0A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_link_rounded, color: Colors.white24, size: 64),
              SizedBox(height: 16),
              Text('Video URL kiriting',
                  style: TextStyle(color: Colors.white38, fontSize: 16)),
              SizedBox(height: 8),
              Text('archive.org yoki boshqa ochiq manbadan link',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final void Function(double) onSeek;
  const _ProgressBar(
      {required this.position, required this.duration, required this.onSeek});

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble();
    final value =
        total > 0 ? (position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Slider(
            value: value,
            onChangeEnd: (v) => onSeek(v * (total / 1000)),
            onChanged: (_) {},
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Colors.white24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
                Text(_fmt(duration),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final bool showChat;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleChat;

  const _PlayerControls({
    required this.isPlaying,
    required this.isMuted,
    required this.showChat,
    required this.onPlay,
    required this.onPause,
    required this.onToggleMute,
    required this.onToggleChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 40,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              color: Colors.white,
            ),
            onPressed: isPlaying ? onPause : onPlay,
          ),
          IconButton(
            iconSize: 32,
            icon: Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: isMuted ? Colors.redAccent : Colors.white70,
            ),
            onPressed: onToggleMute,
          ),
          IconButton(
            iconSize: 32,
            icon: Icon(
              showChat
                  ? Icons.chat_bubble_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: showChat
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white70,
            ),
            onPressed: onToggleChat,
          ),
        ],
      ),
    );
  }
}
