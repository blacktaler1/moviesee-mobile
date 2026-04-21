import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import '../models/room_model.dart';
import 'storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';
import '../../core/exceptions/app_exception.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 120), // yt-dlp + ejs download uchun
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_AuthInterceptor())
    ..interceptors.add(
      TalkerDioLogger(
        talker: appLogger,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          printResponseData: true,
          hiddenHeaders: {'Authorization'}, // tokenni logda ko'rsatmaymiz
        ),
      ),
    );

  // ── Auth ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    appLogger.info('[API] register() → POST /auth/register | username=$username, email=$email');
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    appLogger.info('[API] login() → POST /auth/login | email=$email');
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  // ── Rooms ─────────────────────────────────────────────────

  static Future<RoomModel> createRoom(String name, {String? videoUrl}) async {
    appLogger.info('[API] createRoom() → POST /rooms/create | name=$name');
    try {
      final res = await _dio.post('/rooms/create', data: {
        'name': name,
        if (videoUrl != null) 'video_url': videoUrl,
      });
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  static Future<RoomModel> joinRoom(String code) async {
    appLogger.info('[API] joinRoom() → POST /rooms/join | code=$code');
    try {
      final res = await _dio.post('/rooms/join', data: {'code': code});
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  static Future<RoomModel> getRoom(String code) async {
    appLogger.info('[API] getRoom() → GET /rooms/$code');
    try {
      final res = await _dio.get('/rooms/$code');
      return RoomModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  // ── Notifications ─────────────────────────────────────────

  static Future<void> saveFcmToken(String fcmToken) async {
    appLogger.info('[API] saveFcmToken() → POST /auth/fcm-token');
    try {
      await _dio.post('/auth/fcm-token', data: {'fcm_token': fcmToken});
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  static Future<void> sendRoomInvite(String roomCode, int toUserId) async {
    appLogger.info('[API] sendRoomInvite() → POST /rooms/$roomCode/invite | toUserId=$toUserId');
    try {
      await _dio.post('/rooms/$roomCode/invite', data: {'to_user_id': toUserId});
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  /// YouTube, uzmovi.tv va boshqa saytlardan video stream URL ni chiqarish.
  static Future<Map<String, dynamic>> extractVideoUrl(String url) async {
    appLogger.info('[API] extractVideoUrl() → POST /rooms/extract-url | url=$url');
    try {
      final res = await _dio.post('/rooms/extract-url', data: {'url': url});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  /// Sahifadagi barcha video variantlarini qaytaradi (stream URL chiqarmasdan).
  /// Har bir variant: {title, source_url, thumbnail?, duration?}
  static Future<List<Map<String, dynamic>>> extractVideoOptions(String url) async {
    appLogger.info('[API] extractVideoOptions() → POST /rooms/extract-options | url=$url');
    try {
      final res = await _dio.post('/rooms/extract-options', data: {'url': url});
      final list = res.data as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e, stack) {
      throw _mapException(e, stack);
    }
  }

  // ── Exception Mapper ──────────────────────────────────────
  /// DioException ni typed AppException ga aylantiradi.
  /// Bu pattern user'ning boshqa loyihalarida (dewibe_erp, rentifyapp) ham ishlatiladi.
  static AppException _mapException(DioException e, StackTrace stack) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Server qaytargan xato matni (backend: {"error": {"code": "...", "message": "..."}})
    String? serverMessage;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String) {
        serverMessage = err['message'] as String;
      } else if (data['detail'] is String) {
        serverMessage = data['detail'] as String;
      }
    }

    appLogger.error('[API] Xatolik: status=$statusCode | $serverMessage', e, stack);

    return switch (statusCode) {
      400 => ValidationException(message: serverMessage ?? 'Noto\'g\'ri so\'rov', origin: e, stackTrace: stack),
      401 => UnauthorizedException(message: serverMessage ?? 'Autentifikatsiya talab qilinadi', origin: e, stackTrace: stack),
      403 => ForbiddenException(message: serverMessage ?? 'Ruxsat yo\'q', origin: e, stackTrace: stack),
      404 => NotFoundException(message: serverMessage ?? 'Topilmadi', origin: e, stackTrace: stack),
      409 => ConflictException(message: serverMessage ?? 'Bunday ma\'lumot allaqachon mavjud', origin: e, stackTrace: stack),
      422 => VideoExtractionException(message: serverMessage ?? 'Validatsiya xatosi', origin: e, stackTrace: stack),
      _ => NetworkException(
          message: serverMessage ?? e.message ?? 'Tarmoq xatosi',
          statusCode: statusCode,
          origin: e,
          stackTrace: stack,
        ),
    };
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      appLogger.warning('[AUTH] Token yo\'q! Path: ${options.path}');
    }
    handler.next(options);
  }
}
